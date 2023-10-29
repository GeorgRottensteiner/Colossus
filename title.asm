!lzone Title
          jsr ScreenOff

          jsr RemoveAllObjects

          lda #10
          sta VIC.CHARSET_MULTICOLOR_1


          ldx #0
-
          lda #32
          sta SCREEN_CHAR + 0 * 250,x
          sta SCREEN_CHAR + 1 * 250,x
          sta SCREEN_CHAR + 2 * 250,x
          sta SCREEN_CHAR + 3 * 250,x

          lda #1
          sta SCREEN_COLOR + 0 * 250,x
          sta SCREEN_COLOR + 1 * 250,x
          sta SCREEN_COLOR + 2 * 250,x
          sta SCREEN_COLOR + 3 * 250,x

          inx
          cpx #250
          bne -

          ldx #0
-
          lda TEXT_1,x
          sta SCREEN_CHAR + 12 * 40 + 10,x
          lda TEXT_2,x
          sta SCREEN_CHAR + 13 * 40 + 10,x

          lda TEXT_3,x
          sta SCREEN_CHAR + 15 * 40 + 10,x
          lda TEXT_4,x
          sta SCREEN_CHAR + 16 * 40 + 10,x

          lda TEXT_5,x
          sta SCREEN_CHAR + 18 * 40 + 10,x
          lda TEXT_6,x
          sta SCREEN_CHAR + 19 * 40 + 10,x

          lda TEXT_7,x
          sta SCREEN_CHAR + 21 * 40 + 10,x

          inx
          cpx #20
          bne -

          ldy #1
          jsr DisplayPanelMessage

          ldx #0
          ldy #0
-
          lda COLOSSUS_TITLE,x
          sta SCREEN_CHAR + 4 + 1 * 40,y
          lda COLOSSUS_TITLE + 31,x
          sta SCREEN_CHAR + 4 + 2 * 40,y
          lda COLOSSUS_TITLE + 2 * 31,x
          sta SCREEN_CHAR + 4 + 3 * 40,y
          lda COLOSSUS_TITLE + 3 * 31,x
          sta SCREEN_CHAR + 4 + 4 * 40,y
          lda COLOSSUS_TITLE + 4 * 31,x
          sta SCREEN_CHAR + 4 + 5 * 40,y
          lda COLOSSUS_TITLE + 5 * 31,x
          sta SCREEN_CHAR + 4 + 6 * 40,y
          lda COLOSSUS_TITLE + 6 * 31,x
          sta SCREEN_CHAR + 4 + 7 * 40,y

          lda COLOSSUS_TITLE + 31 * 7,x
          sta SCREEN_COLOR + 4 + 1 * 40,y
          lda COLOSSUS_TITLE + 31 * 7 + 31,x
          sta SCREEN_COLOR + 4 + 2 * 40,y
          lda COLOSSUS_TITLE + 31 * 7 + 2 * 31,x
          sta SCREEN_COLOR + 4 + 3 * 40,y
          lda COLOSSUS_TITLE + 31 * 7 + 3 * 31,x
          sta SCREEN_COLOR + 4 + 4 * 40,y
          lda COLOSSUS_TITLE + 31 * 7 + 4 * 31,x
          sta SCREEN_COLOR + 4 + 5 * 40,y
          lda COLOSSUS_TITLE + 31 * 7 + 5 * 31,x
          sta SCREEN_COLOR + 4 + 6 * 40,y
          lda COLOSSUS_TITLE + 31 * 7 + 6 * 31,x
          sta SCREEN_COLOR + 4 + 7 * 40,y

          inx
          iny
          cpx #31
          bne -

          ldx #0
-
          lda MEGASTYLE_LOGO,x
          sta SCREEN_CHAR + 20 * 40 + 1,x
          lda MEGASTYLE_LOGO + 3,x
          sta SCREEN_CHAR + 21 * 40 + 1,x
          lda MEGASTYLE_LOGO + 6,x
          sta SCREEN_CHAR + 22 * 40 + 1,x
          inx
          cpx #3
          bne -

          lda #7
          sta PARAM1
          lda #4
          sta PARAM2
          lda #TYPE_BOSS_EYE
          sta PARAM3
          jsr AddObject
          jsr MoveSpriteUp
          jsr MoveSpriteUp
          jsr MoveSpriteUp
          jsr MoveSpriteUp

          lda #15
          sta PARAM1
          lda #4
          sta PARAM2
          lda #TYPE_BOSS_EYE
          sta PARAM3
          jsr AddObject
          jsr MoveSpriteUp
          jsr MoveSpriteUp
          jsr MoveSpriteUp
          jsr MoveSpriteUp

          lda #1
          jsr MUSIC_PLAYER

          jsr ScreenOn

!lzone TitleLoop
          jsr WaitFrame

          ldx #0
          jsr BHTitleEye
          ldx #1
          jsr BHTitleEye

          lda JOY_VALUE
          and #JOY_FIRE
          bne TitleLoop

          lda JOY_VALUE_RELEASED
          and #JOY_FIRE
          beq TitleLoop

          lda JOY_VALUE_RELEASED
          and #~JOY_FIRE
          sta JOY_VALUE_RELEASED
          jmp StartGame

TEXT_1
          !scr "     written by     "

TEXT_2
          !scr "georg  rottensteiner"

TEXT_3
          !scr "      audio by      "

TEXT_4
          !scr "    roy  widding    "

TEXT_5
          !scr "  for minijam #144  "
TEXT_6
          !scr "      72 hours      "

TEXT_7
          !scr "  a megastyle game  "


MEGASTYLE_LOGO
          !byte $cf,$f7,$f7,$cc,$cc,$cc,$20,$cc,$ef

COLOSSUS_TITLE
          !media "title.charscreen",CHARCOLOR