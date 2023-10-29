SCREEN_GRID_WIDTH   = 16
SCREEN_GRID_HEIGHT  = 16

NUM_SPECIAL_SCREENS = 4


EXIT_N        = $01
EXIT_S        = $02
EXIT_W        = $04
EXIT_E        = $08


;we have 256 cells
;4 are predefined so far: start, eyes * 2, heart
;pseudo random maze is filled in between

!lzone InitGrid
          ldx #0
          txa
-
          sta SCREEN_GRID,x
          inx
          bne -

          ;aa is blocking!!
          lda GAME_MAIN_SEED
          sta PSEUDO_RANDOM_SEED

          ;place special screens
          ldy #0
.PlaceNextSpecialScreen
.IsColliding
          jsr GeneratePseudoRandomNumber
          cpy #0
          beq .CanPlace

          ;need to check for collisions with existing special screens
          sty LOCAL1

          ldy #0
-
          cmp SPECIAL_SCREENS,y
          beq .IsColliding

          iny
          cpy LOCAL1
          bne -

.CanPlace
          sta SPECIAL_SCREENS,y
          tax
          lda #$80
          sta SCREEN_GRID,x

          iny
          cpy #NUM_SPECIAL_SCREENS
          bne .PlaceNextSpecialScreen

          ;exit up
          lda SPECIAL_SCREENS
          sec
          sbc #SCREEN_GRID_WIDTH
          jsr AddNSExit

          ;now fill up the maze
          lda #0
          sta PARAM3

          ldx #0
-
          lda SCREEN_GRID,x
          bne +

          inc PARAM3

+
          inx
          bne -

          ;find eligible slot
          ldx #0
          stx CURRENT_INDEX

.ConnectNextScreen
          jsr GeneratePseudoRandomNumber
          sta CURRENT_INDEX

-
          ldx CURRENT_INDEX
          lda SCREEN_GRID,x
          bne .ScreenIsAlreadyConnected
          ;bmi .SkipSpecialScreens

          ;and #$0f
          ;bne .ScreenIsAlreadyConnected

          ;check if any regular screen is next to us (and is already connected e.g. has exits set)
          inx
          lda SCREEN_GRID,x
          bmi .ScreenToRightIsSpecial
          and #$0f
          beq .ScreenToRightIsNotConnected

          ;connect to screen to the right
          lda CURRENT_INDEX
          jsr AddWEExit
          jmp .ScreenConnected

.ScreenToRightIsSpecial
.ScreenToRightIsNotConnected
          ldx CURRENT_INDEX
          dex
          lda SCREEN_GRID,x
          bmi .ScreenToLeftIsSpecial
          and #$0f
          beq .ScreenToLeftIsNotConnected

          ;connect to screen to the left
          lda CURRENT_INDEX
          sec
          sbc #1
          jsr AddWEExit
          jmp .ScreenConnected

.ScreenToLeftIsSpecial
.ScreenToLeftIsNotConnected
          lda CURRENT_INDEX
          clc
          adc #SCREEN_GRID_WIDTH
          tax
          lda SCREEN_GRID,x
          bmi .ScreenToSouthIsSpecial
          and #$0f
          beq .ScreenToSouthIsNotConnected

          ;connect to screen to the south
          lda CURRENT_INDEX
          jsr AddNSExit
          jmp .ScreenConnected

.ScreenToSouthIsSpecial
.ScreenToSouthIsNotConnected
          lda CURRENT_INDEX
          sec
          sbc #SCREEN_GRID_WIDTH
          tax
          lda SCREEN_GRID,x
          bmi .ScreenToNorthIsSpecial
          and #$0f
          beq .ScreenToNorthIsNotConnected

          ;connect to screen to the north
          txa
          jsr AddNSExit
          jmp .ScreenConnected

.ScreenToNorthIsSpecial
.ScreenToNorthIsNotConnected
          ;no connected neighbours
.ScreenIsAlreadyConnected
          inc CURRENT_INDEX
          jmp -

.ScreenConnected
          dec PARAM3
          lda PARAM3
          bne .ConnectNextScreen

          ;connect special screens
          ;TODO - make sure special screens are not arranged to map exits into other special screens

          ;eye 1
          lda SPECIAL_SCREENS + 1
          jsr AddWEExit

          ;eye 2
          lda SPECIAL_SCREENS + 2
          sec
          sbc #1
          jsr AddWEExit

          ;heart
          lda SPECIAL_SCREENS + 3
          jsr AddNSExit


          rts




;a = index of northern cell
!lzone AddNSExit
          tax
          lda SCREEN_GRID,x
          ora #EXIT_S
          sta SCREEN_GRID,x

          txa
          clc
          adc #SCREEN_GRID_WIDTH
          tax

          lda SCREEN_GRID,x
          ora #EXIT_N
          sta SCREEN_GRID,x
          rts



;a = index of western cell
!lzone AddWEExit
          tax
          lda SCREEN_GRID,x
          ora #EXIT_E
          sta SCREEN_GRID,x

          txa
          clc
          adc #1
          tax

          lda SCREEN_GRID,x
          ora #EXIT_W
          sta SCREEN_GRID,x
          rts



!lzone DisplayMap
          ldy #SFX_BONUS_BLIP
          jsr PlaySoundEffect

          lda VIC.SPRITE_ENABLE
          pha

          lda #0
          sta VIC.SPRITE_ENABLE

          lda #<( SCREEN_CHAR + 12 + 4 * 40 )
          sta ZEROPAGE_POINTER_1
          sta ZEROPAGE_POINTER_2
          lda #>( SCREEN_CHAR + 12 + 4 * 40 )
          sta ZEROPAGE_POINTER_1 + 1
          clc
          adc #>( SCREEN_COLOR - SCREEN_CHAR )
          sta ZEROPAGE_POINTER_2 + 1

          ldy #0
          ldx #0

--
-
          lda SCREEN_GRID,x
          and #$40
          bne .Explored

          lda #32
          jmp .NotExplored


.Explored
          lda SCREEN_GRID,x
          bpl .RegularScreen

          ;special screen
          sty LOCAL1
          txa
          ldy #0
.NextSpecialScreen
          cmp SPECIAL_SCREENS,y
          beq .FoundSpecialScreen

          iny
          jmp .NextSpecialScreen

.FoundSpecialScreen
          tya
          clc
          adc #128
          ldy LOCAL1
          jmp .NotExplored



.RegularScreen
          lda SCREEN_GRID,x
          and #$0f
          clc
          adc #112
.NotExplored
          sta (ZEROPAGE_POINTER_1),y
          lda #1
          sta (ZEROPAGE_POINTER_2),y
          inx
          iny
          cpy #SCREEN_GRID_WIDTH
          bne -

          lda ZEROPAGE_POINTER_1
          clc
          adc #40
          sta ZEROPAGE_POINTER_1
          sta ZEROPAGE_POINTER_2
          bcc +
          inc ZEROPAGE_POINTER_1 + 1
          inc ZEROPAGE_POINTER_2 + 1
+
          ldy #0
          cpx #0
          bne --

          lda CURRENT_SCREEN_GRID
          and #$0f
          sta PARAM1
          lda CURRENT_SCREEN_GRID
          lsr
          lsr
          lsr
          lsr
          clc
          adc #4
          tay

          lda SCREEN_LINE_OFFSET_TABLE_LO,y
          sta ZEROPAGE_POINTER_1
          sta ZEROPAGE_POINTER_2
          lda SCREEN_LINE_OFFSET_TABLE_HI,y
          sta ZEROPAGE_POINTER_1 + 1
          clc
          adc #>( SCREEN_COLOR - SCREEN_CHAR )
          sta ZEROPAGE_POINTER_2 + 1
          lda PARAM1
          clc
          adc #12
          tay
          lda #7
          sta (ZEROPAGE_POINTER_2),y

          lda (ZEROPAGE_POINTER_1),y
          sta PARAM5
          sty LOCAL1


.MapLoop
          jsr WaitFrame

          jsr KERNAL.SCNKEY
          jsr KERNAL.GETIN
          beq +

          cmp #77
          bne +

          jmp .ReturnToGame

+

          inc BLINK_DELAY
          lda BLINK_DELAY
          and #$0f
          bne +

          ldy LOCAL1
          lda (ZEROPAGE_POINTER_1),y
          cmp PARAM5
          beq ++

          lda PARAM5
          jmp +++

++
          lda #164
+++
          sta (ZEROPAGE_POINTER_1),y

+

          lda JOY_VALUE
          and #JOY_FIRE
          bne .MapLoop

.ReturnToGame
          inc MAP_MODE
          jsr BuildScreen
          dec MAP_MODE

          pla
          sta VIC.SPRITE_ENABLE

          ldy #SFX_BONUS_BLIP
          jsr PlaySoundEffect

          jsr ScreenOn

          rts




;123g EWSN
;           1 = special screen
;           2 = explored
;           3 = special enemy defeated
SCREEN_GRID
          !fill SCREEN_GRID_WIDTH * SCREEN_GRID_HEIGHT

SPECIAL_SCREENS
          !fill NUM_SPECIAL_SCREENS

BLINK_DELAY
          !byte 0