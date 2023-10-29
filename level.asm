TILE_FLOOR        = 0
TILE_WALL_TOP     = 4
TILE_WALL         = 12
TILE_FLOOR_SHADOW = 16

LEVEL_WIDTH   = 20
LEVEL_HEIGHT  = 12

;build screen from grid entry CURRENT_SCREEN_GRID
!lzone BuildScreen
          jsr ScreenOff

          lda MAP_MODE
          bne +
          jsr RemoveAllObjectsButPlayer
+

          ;mark as visited
          ldx CURRENT_SCREEN_GRID
          txa
          lda SCREEN_GRID,x
          and #$40
          bne .AlreadyVisited

          lda SCREEN_GRID,x
          ora #$40
          sta SCREEN_GRID,x
          lda #1
          ldx #PANEL_MAP_OFFSET
          jsr IncScore

          ;increase difficulty?
          inc GAME_MAP_EXPLORED
          lda GAME_MAP_EXPLORED
          and #$0f
          bne +

          inc GAME_DIFFICULTY

+
.AlreadyVisited
          lda CURRENT_SCREEN_GRID
          lsr
          lsr
          lsr
          lsr
          lsr
          lsr
          tay
          lda LEVEL_COLOR_BG,y
          sta CURRENT_BG
          lda LEVEL_COLOR_MC_1,y
          sta VIC.CHARSET_MULTICOLOR_1


          ;current screen is seed
          ldx CURRENT_SCREEN_GRID
          stx PSEUDO_RANDOM_SEED

          lda #$ff
          sta CURRENT_SPECIAL_SCREEN

          ldy #0
-
          lda SPECIAL_SCREENS,y
          cmp CURRENT_SCREEN_GRID
          bne +
          jmp .FixedScreen
+
          iny
          cpy #NUM_SPECIAL_SCREENS
          bne -

          ;is gggg EWSN
          lda SCREEN_GRID,x
          lsr
          lsr
          lsr
          lsr
          tay

          ;fill floor
          ldx #0
          lda #TILE_FLOOR
-

          sta LEVEL_TILES,x

          inx
          cpx #20 * 12
          bne -

          ;fill walls
          ldx #0
          lda #TILE_WALL_TOP
-
          sta LEVEL_TILES,x
          sta LEVEL_TILES + ( LEVEL_HEIGHT - 1 ) * LEVEL_WIDTH,x
          inx
          cpx #LEVEL_WIDTH
          bne -

          ldx #0
          lda #<LEVEL_TILES
          sta ZEROPAGE_POINTER_1
          lda #>LEVEL_TILES
          sta ZEROPAGE_POINTER_1 + 1
-

          ldy #0
          lda #TILE_WALL_TOP
          sta (ZEROPAGE_POINTER_1),y
          ldy #LEVEL_WIDTH - 1
          sta (ZEROPAGE_POINTER_1),y

          lda ZEROPAGE_POINTER_1
          clc
          adc #LEVEL_WIDTH
          sta ZEROPAGE_POINTER_1
          bcc +
          inc ZEROPAGE_POINTER_1 + 1
+

          inx
          cpx #LEVEL_HEIGHT
          bne -

          ;exit south
          lda #<( LEVEL_TILES + 5 + 6 * 20 )
          sta ZEROPAGE_POINTER_2
          lda #>( LEVEL_TILES + 5 + 6 * 20 )
          sta ZEROPAGE_POINTER_2 + 1

          ldx CURRENT_SCREEN_GRID
          lda SCREEN_GRID,x
          and #EXIT_S
          beq .NoExitS

          jsr GeneratePseudoRandomNumber
          and #$03
          clc
          adc #28
          ldx #10
          ldy #6
          jsr DrawMapPart
          jmp .SouthEndDone

          ;lda #TILE_FLOOR
          ;sta LEVEL_TILES +  8 + ( LEVEL_HEIGHT - 1 ) * LEVEL_WIDTH
          ;sta LEVEL_TILES +  9 + ( LEVEL_HEIGHT - 1 ) * LEVEL_WIDTH
          ;sta LEVEL_TILES + 10 + ( LEVEL_HEIGHT - 1 ) * LEVEL_WIDTH
          ;sta LEVEL_TILES + 11 + ( LEVEL_HEIGHT - 1 ) * LEVEL_WIDTH

.NoExitS
          jsr GeneratePseudoRandomNumber
          and #$03
          clc
          adc #32
          ldx #10
          ldy #6
          jsr DrawMapPart

.SouthEndDone
          ;exit top
          lda #<( LEVEL_TILES + 5 )
          sta ZEROPAGE_POINTER_2
          lda #>( LEVEL_TILES + 5 )
          sta ZEROPAGE_POINTER_2 + 1

          ldx CURRENT_SCREEN_GRID
          lda SCREEN_GRID,x
          and #EXIT_N
          beq .NoExitN

          jsr GeneratePseudoRandomNumber
          and #$03
          clc
          adc #20
          ldx #10
          ldy #6
          jsr DrawMapPart
          jmp .NorthDone

          ;lda #TILE_FLOOR
          ;sta LEVEL_TILES +  8
          ;sta LEVEL_TILES +  9
          ;sta LEVEL_TILES + 10
          ;sta LEVEL_TILES + 11

.NoExitN
          jsr GeneratePseudoRandomNumber
          and #$03
          clc
          adc #24
          ldx #10
          ldy #6
          jsr DrawMapPart

.NorthDone
          ;west exit
          lda #<LEVEL_TILES
          sta ZEROPAGE_POINTER_2
          lda #>LEVEL_TILES
          sta ZEROPAGE_POINTER_2 + 1

          ldx CURRENT_SCREEN_GRID
          lda SCREEN_GRID,x
          and #EXIT_W
          beq .NoExitW

          jsr GeneratePseudoRandomNumber
          and #$03
          clc
          adc #4
          ldx #5
          ldy #12
          jsr DrawMapPart
          jmp .WestEndDone
;
;          lda #TILE_FLOOR
;          sta LEVEL_TILES + 4 * LEVEL_WIDTH
;          sta LEVEL_TILES + 5 * LEVEL_WIDTH
;          sta LEVEL_TILES + 6 * LEVEL_WIDTH
;          sta LEVEL_TILES + 7 * LEVEL_WIDTH

.NoExitW
          ;no exit west
          jsr GeneratePseudoRandomNumber
          and #$03
          clc
          adc #12
          ldx #5
          ldy #12
          jsr DrawMapPart
          jmp .WestEndDone



.WestEndDone
          ;exit east
          lda #<( LEVEL_TILES + 15 )
          sta ZEROPAGE_POINTER_2
          lda #>( LEVEL_TILES + 15 )
          sta ZEROPAGE_POINTER_2 + 1

          ldx CURRENT_SCREEN_GRID
          lda SCREEN_GRID,x
          and #EXIT_E
          beq .NoExitE

          jsr GeneratePseudoRandomNumber
          and #$03
          clc
          adc #8
          ldx #5
          ldy #12
          jsr DrawMapPart
          jmp .EastEndDone

          ;lda #TILE_FLOOR
          ;sta LEVEL_TILES + LEVEL_WIDTH - 1 + 4 * LEVEL_WIDTH
          ;sta LEVEL_TILES + LEVEL_WIDTH - 1 + 5 * LEVEL_WIDTH
          ;sta LEVEL_TILES + LEVEL_WIDTH - 1 + 6 * LEVEL_WIDTH
          ;sta LEVEL_TILES + LEVEL_WIDTH - 1 + 7 * LEVEL_WIDTH

.NoExitE
          jsr GeneratePseudoRandomNumber
          and #$03
          clc
          adc #16
          ldx #5
          ldy #12
          jsr DrawMapPart

.EastEndDone
          jmp .BeautifyLevel

ENEMY_LIST
          !byte TYPE_LARVA
          !byte TYPE_AMOEBA
          !byte TYPE_POST
          !byte TYPE_AMOEBA
          !byte TYPE_LARVA
          !byte TYPE_POST



.FixedScreen
          lda MAPMAP_LIST_LO,y
          sta ZEROPAGE_POINTER_1
          lda MAPMAP_LIST_HI,y
          sta ZEROPAGE_POINTER_1 + 1
          sty CURRENT_SPECIAL_SCREEN

          ldy #0
-
          lda (ZEROPAGE_POINTER_1),y
          sta LEVEL_TILES,y
          iny
          cpy #LEVEL_WIDTH * LEVEL_HEIGHT
          bne -


          lda CURRENT_SPECIAL_SCREEN
          cmp #1
          beq .Eye
          cmp #2
          beq .Eye
          cmp #3
          beq .Heart

          ;start/tongue screen
          lda MAP_MODE
          bne .BeautifyLevel

          ldy CURRENT_SPECIAL_SCREEN
          lda SCREEN_GRID,y
          and #$20
          bne .EnemyDefeated

          lda #18
          sta PARAM1
          lda #10
          sta PARAM2
          lda #TYPE_TONGUE
          sta PARAM3
          jsr AddObject
          jmp .BeautifyLevel


.Heart
          ;heart screen
          lda MAP_MODE
          bne .BeautifyLevel

          ldy CURRENT_SPECIAL_SCREEN
          lda SCREEN_GRID,y
          and #$20
          bne .EnemyDefeated

          lda #18
          sta PARAM1
          lda #10
          sta PARAM2
          lda #TYPE_BOSS_HEART
          sta PARAM3
          jsr AddObject
          jmp .BeautifyLevel

.Eye
          lda MAP_MODE
          bne .BeautifyLevel

          ldy CURRENT_SPECIAL_SCREEN
          lda SCREEN_GRID,y
          and #$20
          bne .EnemyDefeated

          lda #18
          sta PARAM1
          lda #10
          sta PARAM2
          lda #TYPE_BOSS_EYE
          sta PARAM3
          jsr AddObject


.EnemyDefeated
.BeautifyLevel
          ;"beautify" tiles
          ldx #0
-
          lda LEVEL_TILES,x
          cmp #TILE_FLOOR
          beq .Randomize
          cmp #TILE_WALL_TOP
          beq .Randomize
          cmp #TILE_WALL
          beq .Randomize
          cmp #TILE_FLOOR_SHADOW
          beq .Randomize

          jmp .NoRandomize

.Randomize
          sta LOCAL1

          jsr GeneratePseudoRandomNumber
          and #$03
          clc
          adc LOCAL1
          sta LEVEL_TILES,x

.NoRandomize
          inx
          cpx #LEVEL_WIDTH * LEVEL_HEIGHT
          bne -

          ;draw screen from tiles
          lda #0
          sta PARAM1
          sta PARAM2
          sta PARAM3

--
          ldy PARAM2
          lda SCREEN_LINE_OFFSET_TABLE_LO,y
          sta ZEROPAGE_POINTER_1
          sta ZEROPAGE_POINTER_2
          lda SCREEN_LINE_OFFSET_TABLE_HI,y
          sta ZEROPAGE_POINTER_1 + 1
          clc
          adc #>( SCREEN_COLOR - SCREEN_CHAR )
          sta ZEROPAGE_POINTER_2 + 1

-
          ldx PARAM3
          lda LEVEL_TILES,x
          tax

          ldy PARAM1
          lda MAP_TILE_CHARS_0_0,x
          sta (ZEROPAGE_POINTER_1),y
          lda MAP_TILE_COLORS_0_0,x
          sta (ZEROPAGE_POINTER_2),y

          iny
          lda MAP_TILE_CHARS_1_0,x
          sta (ZEROPAGE_POINTER_1),y
          lda MAP_TILE_COLORS_1_0,x
          sta (ZEROPAGE_POINTER_2),y

          tya
          clc
          adc #39
          tay
          lda MAP_TILE_CHARS_0_1,x
          sta (ZEROPAGE_POINTER_1),y
          lda MAP_TILE_COLORS_0_1,x
          sta (ZEROPAGE_POINTER_2),y

          iny
          lda MAP_TILE_CHARS_1_1,x
          sta (ZEROPAGE_POINTER_1),y
          lda MAP_TILE_COLORS_1_1,x
          sta (ZEROPAGE_POINTER_2),y

          inc PARAM3
          inc PARAM1
          inc PARAM1

          lda PARAM1
          cmp #40
          bne -

          lda #0
          sta PARAM1
          inc PARAM2
          inc PARAM2
          lda PARAM2
          cmp #24
          bne --


          ;place enemies
          lda MAP_MODE
          beq +

          jmp .NoEnemies
+
          ;special screen?
          lda CURRENT_SPECIAL_SCREEN
          bmi +
          jmp .NoEnemies
+
          ;num of enemies = difficulty, but max. 6
          lda GAME_DIFFICULTY
          clc
          adc #1
          cmp #6
          bcc +
          lda #6
+
          sta PARAM12

.AnotherEnemy
.WasBlocking
          ;spawn random enemies
          lda #5
          sta PARAM5
          lda #34
          sta PARAM6
          jsr GenerateRangedRandom
          sta PARAM1

          lda #5
          sta PARAM5
          lda #18
          sta PARAM6
          jsr GenerateRangedRandom
          sta PARAM2

          ;check if spot is free
          ldy PARAM2
          lda SCREEN_LINE_OFFSET_TABLE_LO,y
          sta ZEROPAGE_POINTER_1
          lda SCREEN_LINE_OFFSET_TABLE_HI,y
          sta ZEROPAGE_POINTER_1 + 1
          ldy PARAM1
          lda (ZEROPAGE_POINTER_1),y
          jsr IsCharBlocking
          bne .WasBlocking

          iny
          lda (ZEROPAGE_POINTER_1),y
          jsr IsCharBlocking
          bne .WasBlocking

          tya
          clc
          adc #39
          tay
          lda (ZEROPAGE_POINTER_1),y
          jsr IsCharBlocking
          bne .WasBlocking

          iny
          lda (ZEROPAGE_POINTER_1),y
          jsr IsCharBlocking
          bne .WasBlocking


          ;TODO - check bg?

          ;make sure it's not too close to the player
          lda SPRITE_CHAR_POS_X
          clc
          adc #4
          cmp PARAM1
          bcc .FarEnoughFromPlayer
          sec
          sbc #8
          cmp PARAM1
          bcs .FarEnoughFromPlayer

          lda SPRITE_CHAR_POS_Y
          clc
          adc #3
          cmp PARAM2
          bcc .FarEnoughFromPlayer
          sec
          sbc #6
          cmp PARAM2
          bcs .FarEnoughFromPlayer
          ;retry
          jmp .AnotherEnemy

.FarEnoughFromPlayer
          lda #0
          sta PARAM5
          lda GAME_DIFFICULTY
          beq +
          sta PARAM6
          ;check for max enemy type
          cmp #5
          bcc ++
          lda #5
          sta PARAM6
++

          jsr GenerateRangedRandom
+
          tay
          lda ENEMY_LIST,y
          sta PARAM3
          ldx #2
          jsr AddObjectStartingWithSlot
          beq .NoSlotFree

          ;every xth enemy is twice as strong
          jsr GenerateRandomNumber
          and #$0f
          bne +

          asl SPRITE_HP,x
          inc VIC.SPRITE_COLOR,x

+

.NoSlotFree
          dec PARAM12
          beq .NoEnemies
          jmp .AnotherEnemy

.NoEnemies
          rts



;ZEROPAGE_POINTER_2 = pos in tile grid
;a = map index
;x = width
;y = height
!lzone DrawMapPart
          stx PARAM1
          sty PARAM2

          tay
          lda MAPMAP_LIST_LO,y
          sta ZEROPAGE_POINTER_1
          lda MAPMAP_LIST_HI,y
          sta ZEROPAGE_POINTER_1 + 1

          ;draw map row
.DrawRow
          ldy #0
-
          lda (ZEROPAGE_POINTER_1),y
          sta (ZEROPAGE_POINTER_2),y
          iny
          cpy PARAM1
          bne -

          tya
          clc
          adc ZEROPAGE_POINTER_1
          sta ZEROPAGE_POINTER_1
          bcc +
          inc ZEROPAGE_POINTER_1 + 1
+
          lda ZEROPAGE_POINTER_2
          clc
          adc #LEVEL_WIDTH
          sta ZEROPAGE_POINTER_2
          bcc +
          inc ZEROPAGE_POINTER_2 + 1
+
          dec PARAM2
          bne .DrawRow

          rts



MAP_MODE
          !byte 0


LEVEL_TILES
          !fill LEVEL_WIDTH * LEVEL_HEIGHT

LEVEL_COLOR_BG
          !byte 2,5,6,12

LEVEL_COLOR_MC_1
          !byte 10,13,14,15



