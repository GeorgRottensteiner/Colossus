NUM_SPRITES = 36

;placeholder for various temp parameters
PARAM1                  = $03
PARAM2                  = $04
PARAM3                  = $05
PARAM4                  = $06
PARAM5                  = $07
PARAM6                  = $08
PARAM7                  = $09
PARAM8                  = $0A
PARAM9                  = $0B
PARAM10                 = $0C
PARAM11                 = $0D
PARAM12                 = $0E


LOCAL1                  = $10
LOCAL2                  = $11
LOCAL3                  = $12

CURRENT_INDEX           = $0f
CURRENT_SUB_INDEX       = $13


;placeholder for zero page pointers
ZEROPAGE_POINTER_1      = $17
ZEROPAGE_POINTER_2      = $19
ZEROPAGE_POINTER_3      = $21
ZEROPAGE_POINTER_4      = $23

;address of the screen buffer
SCREEN_CHAR             = $C000
SCREEN_COLOR            = $D800

SPRITE_LOCATION         = $D000
CHARSET_LOCATION        = $F800



!src <c64.asm>



* = $0801

!basic

          sei  ;; switch off interrupt

          lda #$35 ;; all RAM except D000-Dfff
          sta $01  ;; write to $FFFA/$FFFB now possible
          lda #<nmiRoutine ;; change nmi vector to nmiRoutine
          sta $FFFA
          lda #>nmiRoutine
          sta $FFFB
          lda #$00  ;; stop Timer A
          sta $DD0E
          sta $DD04 ;; set Timer A to 0, after starting
          sta $DD05 ;; NMI will occur immediately
          lda #$81
          sta $DD0D ;; set Timer A as source for NMI
          lda #$01
          sta $DD0E ;; start Timer A -> NMI
          ;; from here on NMI is disabled

          ;Turn off CIA interrupts
          nop
          nop
          nop
          lda #$7f
          sta CIA1.IRQ_CONTROL
          sta CIA2.NMI_CONTROL

          lda #$37 ;; all RAM except D000-Dfff
          sta PROCESSOR_PORT  ;; write to $FFFA/$FFFB now possible

          ;clear keyboard buffer
          lda #$00
          sta $C6

          ;disable run/stop + restore keys!
          lda #$FC
          sta $0328

          ;disable shift-commodore
          lda #$80
          sta $0291


          lda #$0e
          sta VIC.MEMORY_CONTROL

          ;VIC bank
          lda CIA2.DATA_PORT_A
          and #$fc
          sta CIA2.DATA_PORT_A

          lda #0
          sta VIC.BORDER_COLOR
          sta VIC.SPRITE_ENABLE
          sta VIC.SPRITE_X_EXTEND
          sta VIC.SPRITE_MULTICOLOR

          lda #1
          sta VIC.SPRITE_MULTICOLOR_1
          lda #0
          sta VIC.SPRITE_MULTICOLOR_2
          lda #10
          sta VIC.CHARSET_MULTICOLOR_1
          lda #11
          sta VIC.CHARSET_MULTICOLOR_2


          lda #2
          sta VIC.BACKGROUND_COLOR
          sta CURRENT_BG


          sei

          ;only RAM
          ;to copy under the IO rom
          lda #$30
          sta PROCESSOR_PORT


          ;take source address from CHARSET
          lda #<SPRITE_DATA
          sta ZEROPAGE_POINTER_1
          lda #>SPRITE_DATA
          sta ZEROPAGE_POINTER_1 + 1

          ;set target address
          lda #<SPRITE_LOCATION
          sta ZEROPAGE_POINTER_2
          lda #>SPRITE_LOCATION
          sta ZEROPAGE_POINTER_2 + 1

          ldx #( NUM_SPRITES * 64 + 255 ) / 256
          ldy #0
-
          lda (ZEROPAGE_POINTER_1),y
          sta (ZEROPAGE_POINTER_2),y
          iny
          bne -

          inc ZEROPAGE_POINTER_1 + 1
          inc ZEROPAGE_POINTER_2 + 1

          dex
          bne -

          ;take source address from CHARSET
          lda #<CHARSET_DATA
          sta ZEROPAGE_POINTER_1
          lda #>CHARSET_DATA
          sta ZEROPAGE_POINTER_1 + 1

          ;set target address ($F000)
          lda #<CHARSET_LOCATION
          sta ZEROPAGE_POINTER_2
          lda #>CHARSET_LOCATION
          sta ZEROPAGE_POINTER_2 + 1

          ldx #8
          ldy #0
-
          lda (ZEROPAGE_POINTER_1),y
          sta (ZEROPAGE_POINTER_2),y
          iny
          bne -

          inc ZEROPAGE_POINTER_1 + 1
          inc ZEROPAGE_POINTER_2 + 1

          dex
          bne -

          lda #$36
          sta PROCESSOR_PORT

          cli

          ldx #0
-
          txa
          sta SCREEN_CHAR,x
          inx
          bne -

          lda #15
          sta SID.FILTER_MODE_VOLUME

          lda #1
          jsr MUSIC_PLAYER

          jsr InitGameIRQ

          jmp Title


nmiRoutine
          rti ;; exit interrupt not acknowledged


* = $1000
MUSIC_PLAYER
          ;!bin "Colossus_by_Endurion_4_no_extra_drivers_.sid",,$7c + 2
          ;!bin "Colossus_by_Endurion_5_optimize1.sid",,$7c + 2
          ;!bin "Colossus_by_Endurion_5_optimize2.sid",,$7c + 2
          ;!bin "Colossus_by_Endurion_Final_.sid",,$7c + 2
          !bin "Colossus_by_Endurion_Polished_Final_FINAL.sid",,$7c + 2


!src "objects.asm"
;!src "bresenham16bit.asm"
!src "bresenham8bit.asm"
!src "game.asm"
!src "irq.asm"
!src "util.asm"
;!src "sfxplay.asm"
!src "sfxplaygt.asm"
!src "level.asm"
!src "grid.asm"
!src "title.asm"
!src "welldone.asm"

PANEL
          !media "panel.charscreen",CHAR

          !mediasrc "colossus.mapproject",MAP_,TILE

          !mediasrc "colossus.mapproject",MAP,MAP

SPRITE_DATA
          !media "colossus.spriteproject",SPRITE,0,NUM_SPRITES

CHARSET_DATA
          !media "colossus.mapproject",CHAR,0,256