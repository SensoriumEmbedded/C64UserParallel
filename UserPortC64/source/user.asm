
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
   
   ;BASIC routines:
   PrintString = $ab1e
   
   ;code locations (saved to prg):
	;BasicStart = $0801
   ;code       = $0810 ;2064
   code       = $c000  ;49152
   
   
;   *=BasicStart
;   ;BASIC SYS header
;   !byte $0b,$08,$01,$00,$9e  ; Line 1 SYS
;   !convtab pet
;   !tx "2064" ;dec address for sys start in text
;   !byte $00,$00,$00
   
   *=code  ; Start location for code

;Setup stuff:
   sei
   lda #<MsgWelcome
   ldy #>MsgWelcome
   jsr PrintString   
   
   lda #$00
   sta UserPBDir  ;set all of PB as inputs
   
   lda UserPADir
   ora #%00000100 ;set bit 2
   sta UserPADir  ;set PA.2 as output
   lda UserPAIO   
   and #%11111011 ;clear bit 2 (not ready)
   sta UserPAIO   ;set ready output low

   
;Main routine:
Main:
   lda #<MsgWaiting
   ldy #>MsgWaiting
   jsr PrintString   ;display waiting message
   
   jsr ReceiveByte
   cmp #$B9  ;magic number to start
   beq cont1
   lda #$01  ;unexpected start byte
   jmp ErrOut
cont1:   
   
   lda #<MsgReceiving
   ldy #>MsgReceiving
   jsr PrintString   ;display receiving message
   
   jsr ReceiveByte
   sta PtrAddrLo
   cmp #$01  ;StartAddr Low
   beq cont2
   lda #$02  ;StartAddr Low
   jmp ErrOut
cont2: 
  
   jsr ReceiveByte
   sta PtrAddrHi
   cmp #$08  ;StartAddr High
   beq cont3
   lda #$03  ;StartAddr High
   jmp ErrOut
cont3:   

   jsr ReceiveByte  ;size in 256 byte pages
   clc
   adc PtrAddrHi
   sta LastPage   ;store last page hi addr
  
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
   
Finish:
   lda #<MsgFinished
   ldy #>MsgFinished
   jsr PrintString
   
;   ldy #$00   ;packet index
;printpacket:
;   lda Packet, y
;   jsr PrintHexByte
;   iny
;   cpy #PacketSize
;   bne printpacket
   ;lda #13
   ;jsr SendChar
   ;jmp Main

   rts ;return to BASIC
   
   
   
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
   rts ;return to BASIC
 
 
 
;   *********************** Subroutines *********************** 
 
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
 
;   *********************** Strings/Messages *********************** 

MsgError:
   !convtab pet
   !tx "Error #", 0
MsgWelcome:       ;clr screen, wht char, lower case
   !tx 147, 5, 14, "Trav's para-user app 0.02", 13, 0
MsgWaiting:
   !tx "Waiting...", 13, 0
MsgReceiving:
   !tx "Receiving...", 13, 0
MsgFinished:
   !tx "Finished", 13, 0
   
   
   