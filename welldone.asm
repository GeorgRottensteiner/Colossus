!lzone WellDone
          jsr ScreenOff

          lda #0
          sta VIC.SPRITE_ENABLE

          ldx #0
-
          lda #32
          sta SCREEN_CHAR + 0 * 240,x
          sta SCREEN_CHAR + 1 * 240,x
          sta SCREEN_CHAR + 2 * 240,x
          sta SCREEN_CHAR + 3 * 240,x

          lda #1
          sta SCREEN_COLOR + 0 * 240,x
          sta SCREEN_COLOR + 1 * 240,x
          sta SCREEN_COLOR + 2 * 240,x
          sta SCREEN_COLOR + 3 * 240,x

          inx
          cpx #240
          bne -

          ldx #0
-
          lda WD_TEXT_1,x
          sta SCREEN_CHAR + 8 * 40 + 6,x

          lda WD_TEXT_2,x
          sta SCREEN_CHAR + 10 * 40 + 6,x
          lda WD_TEXT_3,x
          sta SCREEN_CHAR + 11 * 40 + 6,x
          lda WD_TEXT_4,x
          sta SCREEN_CHAR + 12 * 40 + 6,x

          lda WD_TEXT_5,x
          sta SCREEN_CHAR + 14 * 40 + 6,x

          inx
          cpx #28
          bne -

          ldy #1
          jsr DisplayPanelMessage

          jsr ScreenOn

!lzone WellDoneLoop
          jsr WaitFrame

          lda JOY_VALUE
          and #JOY_FIRE
          bne WellDoneLoop

          lda JOY_VALUE_RELEASED
          and #JOY_FIRE
          beq WellDoneLoop

          lda JOY_VALUE_RELEASED
          and #~JOY_FIRE
          sta JOY_VALUE_RELEASED
          jmp Title

WD_TEXT_1
          !scr "         well done!         "

WD_TEXT_2
          !scr "jumping from the beasts maw "

WD_TEXT_3
          !scr "it collapses, defeated from "

WD_TEXT_4
          !scr "inside.                     "

WD_TEXT_5
          !scr "     what a nightmare!      "

