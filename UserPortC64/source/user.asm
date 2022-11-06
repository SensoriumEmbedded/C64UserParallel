
   PacketSize = 64

   ;mem pointers
   UserPAIO   = $dd00
   UserPBIO   = $dd01
   UserPADir  = $dd02
   UserPBDir  = $dd03
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
   and #%11111011 ;clear bit 2
   sta UserPADir  ;set PA.2 as input
   
;Main Loop:
Main:
   lda #<MsgWaiting
   ldy #>MsgWaiting
   jsr PrintString   
   ldy #$00   ;packet index
lpForHigh:
   lda UserPAIO
   and #%00000100 ;mask bit 2 (latch)
   bne lpForHigh

   ;grab and save byte:
   lda UserPBIO
   sta Packet, y
   iny
   cpy #PacketSize
   beq Finish
   
lpForLow
   lda UserPAIO
   and #%00000100 ;mask bit 2 (latch)
   beq lpForLow

   jmp lpForHigh
 
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
   rts ;return to BASIC
 
 
 
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
   
   
   