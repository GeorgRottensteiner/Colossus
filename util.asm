!lzone WaitFrame
          lda #$ff

          ;wait for raster to reach raster A
WaitForSpecificFrame
          cmp VIC.RASTER_POS
          beq WaitForSpecificFrame

          ;wait for the raster to reach line $f8 (should be closer to the start of this line this way)
.WaitStep2
          cmp VIC.RASTER_POS
          bne .WaitStep2
          rts



!lzone GenerateRandomNumber
          lda $dc04
          eor $dc05
          eor $dd04
          adc $dd05
          eor $dd06
          eor $dd07
          rts



;lower end = PARAM5
;higher end = PARAM6
!lzone GenerateRangedRandom
          lda PARAM6
          sec
          sbc PARAM5
          clc
          adc #1
          sta PARAM6

          jsr GenerateRandomNumber
.CheckValue
          cmp PARAM6
          bcc .ValueOk

          ;too high
          sec
          sbc PARAM6
          jmp .CheckValue

.ValueOk
          clc
          adc PARAM5
          rts


!lzone GeneratePseudoRandomNumber
          lda PSEUDO_RANDOM_SEED
          beq .Eor
          clc
          asl
          beq +    ;if the input was $80, skip the EOR
          bcc +
.Eor
          eor #$1d
+
          sta PSEUDO_RANDOM_SEED
          rts



!lzone ScreenOff
          lda #$00
          sta SCREEN_OFF

          jmp WaitFrame



!lzone ScreenOn
          lda #$10
          sta SCREEN_OFF

          jmp WaitFrame


PANEL_SCORE_OFFSET  = 11
PANEL_MAP_OFFSET    = 39
PANEL_HEALTH_OFFSET = 28


;a = value
;x = offset on screen
!lzone IncScore
          clc
          adc SCREEN_CHAR + 40 * 24,x
          cmp #48 + 10
          bcc +

          sec
          sbc #10
          sta SCREEN_CHAR + 40 * 24,x
          lda #1
          dex
          bmi .Done
          jmp IncScore

+
          sta SCREEN_CHAR + 40 * 24,x
.Done
          rts



;y = message
!lzone DisplayPanelMessage
          lda PANEL_MESSAGES_LO,y
          sta ZEROPAGE_POINTER_1
          lda PANEL_MESSAGES_HI,y
          sta ZEROPAGE_POINTER_1 + 1

          ldy #0
-
          lda (ZEROPAGE_POINTER_1),y
          sta SCREEN_CHAR + 40 * 24 + 15,y
          iny
          cpy #10
          bne -

          rts



PANEL_MESSAGES_LO
          !byte <GAME_OVER_MESSAGE_1
          !byte <GAME_OVER_MESSAGE_2
          !byte <M_FOR_MAP_MESSAGE
          !byte <RETURN_TO_EXIT_MESSAGE

PANEL_MESSAGES_HI
          !byte >GAME_OVER_MESSAGE_1
          !byte >GAME_OVER_MESSAGE_2
          !byte >M_FOR_MAP_MESSAGE
          !byte >RETURN_TO_EXIT_MESSAGE

GAME_OVER_MESSAGE_1
          !scr "game  over"

GAME_OVER_MESSAGE_2
          !scr "press fire"

M_FOR_MAP_MESSAGE
          !scr "m for map "

RETURN_TO_EXIT_MESSAGE
          !scr "go to exit"



SCREEN_LINE_OFFSET_TABLE_LO
          !fill 25, <( SCREEN_CHAR + i * 40 )

SCREEN_LINE_OFFSET_TABLE_HI
          !fill 25, >( SCREEN_CHAR + i * 40 )

PSEUDO_RANDOM_SEED
          !byte 0

SCREEN_OFF
          !byte $10
