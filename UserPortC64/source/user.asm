
   !convtab pet   ;key in and text out conv to PetSCII throughout
 
   PacketSize = 64

   ;Registers:
   PtrAddrLo  = $fb
   PtrAddrHi  = $fc
   LastPage   = $fd
   UserPAIO   = $dd00
   UserPBIO   = $dd01
   UserPADir  = $dd02
   UserPBDir  = $dd03
   UserPICR   = $dd0d
      
   ;Kernal routines:
   SendChar = $ffd2
   ScanKey  = $ff9f ;SCNKEY
   GetIn    = $ffe4 ;GETIN
   
   ;BASIC routines:
   BasicWarmStartVect = $a002
   PrintString =  $ab1e


CompType = 3 ;Choose Compile type:  1=BASIC, 2=UPPER, 3=ROMCRT

!if CompType = 1 {
; Load into Basic RAM (0801) directly and run from there 
; no crunch needed 
; 
   BasicStart = $0801
   *=BasicStart
   ;BASIC SYS header
   !byte $0b,$08,$01,$00,$9e  ; Line 1 SYS
   !tx "2064" ;dec address for sys start in text
   !byte $00,$00,$00
   code = 2064 ;$0810
}

!if CompType = 2 {
;Option #2
; Load into upper memory, use cruncher to to transfer/call  
; SET cruncherArgs=-x$c000 -c64 -g55 -fshort
;
   code       = $c000  ;49152
}

!if CompType = 3 {
;Option #3
; Store in EEPROM/cartridge
; no crunch needed  
; SET build=%filename%.bin
; SET compilerArgs=-r %buildPath%\%compilerReport% --vicelabels %buildPath%\%compilerSymbols% --msvc --color --format plain -v3 --outfile
; burn to eeprom, file won't import to emulator due to 2 missing start addr bytes in file
;
* = $9fff                     ; set a byte to cause fill up to -$9fff (or $bfff if 16K)
   !byte 0
;  jump vectors and autostart key     
   CartStart = $8000
   *=CartStart
   !word Coldstart    ; Cartridge cold-start vector   ;!byte $09, $80 = !word $8009
   !word Warmstart    ; Cartridge warm-start vector
   !byte $c3, $c2, $cd, $38, $30    ; CBM8O - Autostart key
;  KERNAL RESET ROUTINE
Coldstart:
   sei
   stx $d016            ; Turn on VIC for PAL / NTSC check
   jsr $fda3            ; IOINIT - Init CIA chips
   jsr $fd50            ; RANTAM - Clear/test system RAM
   jsr $fd15            ; RESTOR - Init KERNAL RAM vectors
   jsr $ff5b            ; CINT   - Init VIC and screen editor
   cli                  ; Re-enable IRQ interrupts
;  BASIC RESET  Routine
Warmstart:
   jsr $e453            ; Init BASIC RAM vectors
   jsr $e3bf            ; Main BASIC RAM Init routine
   jsr $e422            ; Power-up message / NEW command
   ldx #$fb
   txs                  ; Reduce stack pointer for BASIC
   code       = *
}
   

;******************************* Real Code Start ************************************   
   *=code  ; Start location for code
   
;   Setup stuff:
   ;sei
   lda #$00
   sta UserPBDir  ;set all of PB as inputs
   
   lda UserPADir
   ora #%00000100 ;set bit 2
   sta UserPADir  ;set PA.2 as output
   lda UserPAIO   
   and #%11111011 ;clear bit 2 (not ready)
   sta UserPAIO   ;set ready output low
  
   lda #<MsgWelcome
   ldy #>MsgWelcome
   jsr PrintString  
   
;*******************************  Keyboard option list/input wait   *******************************
KbdOptions:
   lda #<MsgOptions
   ldy #>MsgOptions
   jsr PrintString

WaitForKey:     ;"rEceive, Run, Save, Disp, or Quit..."
   jsr ScanKey  ; (since interrupts are disabled)
   jsr GetIn    ;
   beq WaitForKey

   cmp #'e'     ;rEceive
   beq ReceiveFile
   
   cmp #'r'   ;load keyboard buffer with "RUN\n" and exit to BASIC
   bne notR
   ;load keyboard buffer with "run\n":  
   lda #'r'
   sta $0277  ;kbd buff 0
   lda #'u'
   sta $0278 ;kbd buff 1
   lda #'n'
   sta $0279  ;kbd buff 2
   lda #13
   sta $027a  ;kbd buff 3
   lda #4
   sta $C6  ;# chars in kbd buff (10 max)
   jmp (BasicWarmStartVect)
notR:

   cmp #'q'  ;quit to BASIC
   bne notQ
   jmp (BasicWarmStartVect) 
notQ:

   cmp #'d'  ;display start of receved data
   bne notD
   ldy #$00   ;index
DispLoop:     ;first 100 bytes from $0801
   lda $0801, y
   jsr PrintHexByte
   iny
   cpy #100
   bne DispLoop
   lda #13
   jsr SendChar
   jmp KbdOptions
notD:

   cmp #'s'  ;save file to disk
   bne notS
   ;save not yet implemented...
   
notS:

   jmp KbdOptions   ; try again...  
   

ReceiveFile:  ;*******************************  Receive File from host ;*******************************
   lda #<MsgWaiting
   ldy #>MsgWaiting
   jsr PrintString   ;display waiting message
   
   jsr ReceiveByte;*** magic number to start
   cmp #$B9  
   beq cont1
   lda #$01  ;unexpected start byte
   jmp ErrOut
cont1:   
   
   lda #<MsgReceiving
   ldy #>MsgReceiving
   jsr PrintString   ;display receiving message
   
   jsr ReceiveByte  ;*** Size in 256 byte pages
   sta LastPage     ;store last page hi addr
  
   jsr ReceiveByte  ;*** Start Address low byte
   sta PtrAddrLo
   cmp #$01  ;StartAddr Low, verifying $0801
   beq cont2
   lda #$02  ;StartAddr Low
   jmp ErrOut
cont2: 
  
   jsr ReceiveByte  ;*** Start Address High byte
   sta PtrAddrHi
   cmp #$08  ;StartAddr High, verifying $0801
   beq cont3
   lda #$03  ;StartAddr High
   jmp ErrOut
cont3:   

;  Ready for Payload...
   clc
   adc LastPage     ;add start address page to size 
   sta LastPage     ;store last page hi addr

   ldy #$00       ;reset packet index
ReadyNext:
   jsr ReceiveByte
   sta (PtrAddrLo), y   ;save byte in mem
   iny
   bne ReadyNext
   
   inc PtrAddrHi
   lda PtrAddrHi
   cmp LastPage
   bne ReadyNext
   
   lda #<MsgFinished
   ldy #>MsgFinished
   jsr PrintString
   
   jmp KbdOptions

   
ErrOut:   
   ;ErrNum stored in acc
   pha
   lda #<MsgError
   ldy #>MsgError
   jsr PrintString   
   pla
   jsr PrintHexByte
   lda #13
   jsr SendChar
   jmp KbdOptions
 
 
 
;   ;******************************* Subroutines ;******************************* 
 
ReceiveByte:
   ;Receives one byte from parallel port, then back to not ready
   ;returns value in acc
   ; X and Y not touched
   lda UserPAIO   
   ora #%00000100 ;set bit 2 (ready)
   sta UserPAIO   ;set ready output high

   lda #%00010000 ;mask bit 4 (Flag pin)
lpForFlag:        ;wait for high to low transition on Flag2 pin
   bit UserPICR   ;self clearing on read
   beq lpForFlag

   lda UserPAIO   
   and #%11111011 ;clear bit 2 (not ready)
   sta UserPAIO   ;set ready output low
   
   lda UserPBIO  ;grab byte
   rts
 
PrintHexByte:
   ;Print byte value stored in acc in hex
   ;  2 chars plus 2 spaces
   ;trashes acc
   pha
   ror
   ror
   ror
   ror
   jsr PrintHexNibble
   pla
   jsr PrintHexNibble
   lda #' '
   jsr SendChar
   lda #' '
   jsr SendChar
   rts
   
PrintHexNibble:   
   ;Print value stored in lower nible acc in hex
   ;trashes acc
   and #$0f
   cmp #$0a
   bpl letter 
   clc
   adc #'0'
   jmp printret
letter:
   clc
   adc #'a'-$0a
printret:
   jsr SendChar
   rts
 
;   ;******************************* Strings/Messages ;******************************* 

MsgError:
   !tx "Error #", 0
MsgWelcome:       ;clr screen, wht char, lower case
   !tx 5, 14, "Trav's para-user app 0.04", 13, 0
   ;!tx 147, 5, 14, "Trav's para-user app 0.03", 13, 0
MsgWaiting:
   !tx "Waiting for host...", 13, 0
MsgReceiving:
   !tx "Receiving...", 13, 0
MsgFinished:
   !tx "Finished!", 13, 0
MsgOptions:
   !tx 13, "rEceive, Run, Save, Disp, or Quit...", 13, 0
   
   
   