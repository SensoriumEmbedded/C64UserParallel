
   PacketSize = 64

   ;mem pointers
   UserPAIO   = $dd00
   UserPBIO   = $dd01
   UserPADir  = $dd02
   UserPBDir  = $dd03
   UserPICR   = $dd0d
   
   Packet     = $1000
   
   ;Kernal routines:
   SendChar = $ffd2
   
   ;BASIC routines:
   PrintString = $ab1e
   
   ;code locations (saved to prg):
	BasicStart = $0801
   code       = $0810 ;2064
   
   
   *=BasicStart
   ;BASIC SYS header
   !byte $0b,$08,$01,$00,$9e  ; Line 1 SYS
   !convtab pet
   !tx "2064" ;dec address for sys start in text
   !byte $00,$00,$00
   
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
   
;Main Loop:
Main:
   lda #<MsgWaiting
   ldy #>MsgWaiting
   jsr PrintString   ;display waiting message
   ldy #$00       ;reset packet index
   
ReadyNext:

   lda UserPAIO   ;set ready output high
   ora #%00000100 ;set bit 2 (ready)
   sta UserPAIO

   lda #%00010000 ;mask bit 4 (Flag pin)
lpForFlag:        ;wait for high to low transition on Flag2 pin
   bit UserPICR   ;self clearing on read
   beq lpForFlag

   lda UserPAIO   ;set ready output low
   and #%11111011 ;clear bit 2 (not ready)
   sta UserPAIO
   ;grab and save byte:
   lda UserPBIO
   sta Packet, y
   iny
   cpy #PacketSize
   bne ReadyNext
   
Finish:
   lda #<MsgFinished
   ldy #>MsgFinished
   jsr PrintString
   ldy #$00   ;packet index
printpacket:
   lda Packet, y
   jsr PrintHexByte
   iny
   cpy #PacketSize
   bne printpacket
   ;lda #13
   ;jsr SendChar
   jmp Main
   ;rts ;return to BASIC
 
 
 
PrintHexByte:
   ;Print value stored in acc in hex
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
 
 
;Strings/Messages: 
MsgWelcome:
   !tx 147, "trav's para-user app 0.01", 13, 0
MsgWaiting:
   !tx 13, "waiting...", 0
MsgFinished:
   !tx "packet received", 13, 0
   
   
   