!lzone StartGame
          lda #0
          jsr MUSIC_PLAYER

          jsr GenerateRandomNumber
          sta GAME_MAIN_SEED

          lda #0
          sta PLAYER_LAST_MOVED_DIR
          sta PLAYER_DEAD
          sta GAME_DIFFICULTY
          sta GAME_MAP_EXPLORED
          sta NUM_BOSSES_DEFEATED
          sta GAME_COMPLETED

          lda #$ff
          sta CURRENT_SPECIAL_SCREEN

          ;lda #6
          ;sta GAME_DIFFICULTY

          ;hang 4, after 3

          ;lda #0
          ;sta GAME_MAIN_SEED
          jsr InitGrid
;
;          ldx #0
;-
;          lda SCREEN_GRID,x
;          ora #$40
;          sta SCREEN_GRID,x
;          inx
;          bne -
;
;          jsr DisplayMap
;
;          lda #4
;          sta GAME_MAIN_SEED

;--
;          lda GAME_MAIN_SEED
;          lsr
;          lsr
;          lsr
;          lsr
;          and #$0f
;          tay
;          lda HEX_DISPLAY,y
;          sta SCREEN_CHAR
;          lda GAME_MAIN_SEED
;          and #$0f
;          tay
;          lda HEX_DISPLAY,y
;          sta SCREEN_CHAR + 1
;
;          jsr InitGrid
;
;          ldx #0
;-
;          lda SCREEN_GRID,x
;          ora #$40
;          sta SCREEN_GRID,x
;          inx
;          bne -
;
;          jsr DisplayMap
;-
;          jsr WaitFrame
;          jsr KERNAL.SCNKEY
;          jsr KERNAL.GETIN
;          beq -
;
;          inc GAME_MAIN_SEED
;          jmp --
;
;
;HEX_DISPLAY
;          !scr "0123456789abcdef"
;
;          jsr RemoveAllObjects
;
          ldx #0
-
          lda PANEL,x
          sta SCREEN_CHAR + 24 * 40,x
          lda #1
          sta SCREEN_COLOR + 24 * 40,x
          inx
          cpx #40
          bne -

          ;place in start screen
          lda SPECIAL_SCREENS
          sta CURRENT_SCREEN_GRID

          jsr RemoveAllObjects

          lda #19
          sta PARAM1
          lda #9
          sta PARAM2
          lda #TYPE_PLAYER
          sta PARAM3
          jsr AddObject

          jsr BuildScreen

          ldy #2
          jsr DisplayPanelMessage

          jsr ScreenOn

!lzone GameLoop
          jsr WaitFrame

          lda GAME_COMPLETED
          beq +
          jmp WellDone

+

          jsr KERNAL.SCNKEY
          jsr KERNAL.GETIN
          beq +

          cmp #77
          bne +

          jsr DisplayMap

+
          lda PLAYER_DEAD
          beq +

          lda JOY_VALUE
          and #JOY_FIRE
          bne .NotFire

          lda JOY_VALUE_RELEASED
          and #JOY_FIRE
          beq .NotReleased

          lda JOY_VALUE_RELEASED
          and #~JOY_FIRE
          sta JOY_VALUE_RELEASED
          jmp Title


.NotReleased
.NotFire
          inc PLAYER_DEAD_DELAY
          lda PLAYER_DEAD_DELAY
          and #$3f
          bne +

          lda PLAYER_DEAD_MESSAGE
          eor #$01
          sta PLAYER_DEAD_MESSAGE
          tay
          jsr DisplayPanelMessage


+



          inc SPEED_TABLE_POS
          lda SPEED_TABLE_POS
          and #$07
          sta SPEED_TABLE_POS

          jsr ObjectControl

          jmp GameLoop





JOY_VALUE
          !byte 0

JOY_VALUE_RELEASED
          !byte 0


PLAYER_DEAD
          !byte 0

PLAYER_DEAD_DELAY
          !byte 0
PLAYER_DEAD_MESSAGE
          !byte 0

CURRENT_SCREEN_GRID
          !byte 0

;also defines the range of random enemies to spawn
GAME_DIFFICULTY
          !byte 0

GAME_MAP_EXPLORED
          !byte 0

GAME_MAIN_SEED
          !byte 0

;current special screen index, $ff if not
CURRENT_SPECIAL_SCREEN
          !byte $ff

NUM_BOSSES_DEFEATED
          !byte 0

GAME_COMPLETED
          !byte 0

CURRENT_BG
          !byte 2