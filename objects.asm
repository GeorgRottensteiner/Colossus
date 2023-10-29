SPRITE_CENTER_OFFSET_X  = 8
SPRITE_CENTER_OFFSET_Y  = 11

TYPE_NONE                     = 0
TYPE_PLAYER                   = 1
TYPE_PLAYER_SHOT              = 2
TYPE_LARVA                    = 3
TYPE_EXPLOSION                = 4
TYPE_AMOEBA                   = 5
TYPE_BOSS_EYE                 = 6
TYPE_BOSS_HEART               = 7
TYPE_BOSS_SHOT                = 8
TYPE_PICKUP                   = 9
TYPE_TONGUE                   = 10

SPRITE_POINTER_BASE           = SCREEN_CHAR + 1016

SPRITE_BASE                   = ( SPRITE_LOCATION % 16384 ) / 64

SPRITE_PLAYER_RIGHT           = SPRITE_BASE + 0
SPRITE_PLAYER_LEFT            = SPRITE_BASE + 2
SPRITE_PLAYER_UP              = SPRITE_BASE + 4
SPRITE_PLAYER_DOWN            = SPRITE_BASE + 6

SPRITE_PLAYER_SHOT_H          = SPRITE_BASE + 8
SPRITE_PLAYER_SHOT_V          = SPRITE_BASE + 9
SPRITE_PLAYER_SHOT_LLUR       = SPRITE_BASE + 10
SPRITE_PLAYER_SHOT_ULLR       = SPRITE_BASE + 11

SPRITE_LARVA                  = SPRITE_BASE + 12

SPRITE_PLAYER_DYING           = SPRITE_BASE + 14

SPRITE_EXPLOSION              = SPRITE_BASE + 17

SPRITE_AMOEBA                 = SPRITE_BASE + 21
SPRITE_BOSS_EYE               = SPRITE_BASE + 25
SPRITE_BOSS_HEART             = SPRITE_BASE + 28
SPRITE_BOSS_SHOT              = SPRITE_BASE + 32

SPRITE_PICKUP                 = SPRITE_BASE + 33
SPRITE_TONGUE                 = SPRITE_BASE + 34


JOY_UP                  = $01
JOY_DOWN                = $02
JOY_LEFT                = $04
JOY_RIGHT               = $08
JOY_FIRE                = $10




!lzone ObjectControl
          ldx #0
          stx CURRENT_INDEX

.ObjectLoop
          ldy SPRITE_ACTIVE,x
          beq .NextObject

          lda SPRITE_HITBACK,x
          beq +
          dec SPRITE_HITBACK,x
          bne +

          lda SPRITE_HITBACK_ORIG_COLOR,x
          sta VIC.SPRITE_COLOR,x

+

          ;enemy is active
          lda SPRITE_BEHAVIOUR_LO,x
          sta .JumpPointer + 1
          lda SPRITE_BEHAVIOUR_HI,x
          sta .JumpPointer + 2

.JumpPointer
          jsr $8000

.NextObject
          inc CURRENT_INDEX
          ldx CURRENT_INDEX
          cpx #8
          bne .ObjectLoop
          rts


;------------------------------------------------------------
;Move Sprite Left
;expect x as sprite index (0 to 7)
;------------------------------------------------------------
!lzone MoveSpriteLeft
          dec SPRITE_POS_X,x
          bpl .NoChangeInExtendedFlag

          lda BIT_TABLE,x
          eor #$ff
          and SPRITE_POS_X_EXTEND
          sta SPRITE_POS_X_EXTEND
          sta VIC.SPRITE_X_EXTEND

.NoChangeInExtendedFlag
          txa
          asl
          tay

          lda SPRITE_POS_X,x
          sta VIC.SPRITE_X_POS,y
          rts

;------------------------------------------------------------
;Move Sprite Right
;expect x as sprite index (0 to 7)
;------------------------------------------------------------
!lzone MoveSpriteRight
          inc SPRITE_POS_X,x
          lda SPRITE_POS_X,x
          bne .NoChangeInExtendedFlag

          lda BIT_TABLE,x
          ora SPRITE_POS_X_EXTEND
          sta SPRITE_POS_X_EXTEND
          sta VIC.SPRITE_X_EXTEND

.NoChangeInExtendedFlag
          txa
          asl
          tay

          lda SPRITE_POS_X,x
          sta VIC.SPRITE_X_POS,y
          rts

;------------------------------------------------------------
;Move Sprite Up
;expect x as sprite index (0 to 7)
;------------------------------------------------------------
!zone MoveSpriteUp
MoveSpriteUp
          dec SPRITE_POS_Y,x

          txa
          asl
          tay

          lda SPRITE_POS_Y,x
          sta VIC.SPRITE_Y_POS,y
          rts

;------------------------------------------------------------
;Move Sprite Down
;expect x as sprite index (0 to 7)
;------------------------------------------------------------
!zone MoveSpriteDown
MoveSpriteDown
          inc SPRITE_POS_Y,x

          txa
          asl
          tay

          lda SPRITE_POS_Y,x
          sta VIC.SPRITE_Y_POS,y
          rts




;------------------------------------------------------------
;CalcSpritePosFromCharPos
;calculates the real sprite coordinates from screen char pos
;and sets them directly
;PARAM1 = char_pos_x
;PARAM2 = char_pos_y
;X      = sprite index
;------------------------------------------------------------
!zone CalcSpritePosFromCharPos
CalcSpritePosFromCharPos

          ;offset screen to border 24,50
          lda BIT_TABLE,x
          eor #$ff
          and SPRITE_POS_X_EXTEND
          sta SPRITE_POS_X_EXTEND
          sta VIC.SPRITE_X_EXTEND

          ;need extended x bit?
          lda PARAM1
          sta SPRITE_CHAR_POS_X,x
          cmp #30
          bcc .NoXBit

          lda BIT_TABLE,x
          ora SPRITE_POS_X_EXTEND
          sta SPRITE_POS_X_EXTEND
          sta VIC.SPRITE_X_EXTEND

.NoXBit
          ;calculate sprite positions (offset from border)
          txa
          asl
          tay

          ;X = charX * 8 + ( 24 - SPRITE_CENTER_OFFSET_X=8 )
          lda PARAM1
          asl
          asl
          asl
          clc
          adc #( 24 - SPRITE_CENTER_OFFSET_X )
          sta SPRITE_POS_X,x
          sta VIC.SPRITE_X_POS,y

          ;Y = charY * 8 + ( 50 - SPRITE_CENTER_OFFSET_Y=11 )
          lda PARAM2
          sta SPRITE_CHAR_POS_Y,x
          asl
          asl
          asl
          clc
          adc #( 50 - SPRITE_CENTER_OFFSET_Y )
          sta SPRITE_POS_Y,x
          sta VIC.SPRITE_Y_POS,y

          lda #0
          sta SPRITE_CHAR_POS_X_DELTA,x
          sta SPRITE_CHAR_POS_Y_DELTA,x
          rts



;adds object
;PARAM1 = X
;PARAM2 = Y
;PARAM3 = TYPE
;returns a = 0 if no free slot found
!zone AddObject
AddObject
          ldx #0
;adds object
;PARAM1 = X
;PARAM2 = Y
;PARAM3 = TYPE
;returns a = 0 if no free slot found
AddObjectStartingWithSlot
          jsr FindEmptySpriteSlot
          bne +
          lda #0
          tax
          rts
+
          ;PARAM1 and PARAM2 hold x,y already
AddObjectInSlotX
          jsr CalcSpritePosFromCharPos

;requires PARAM3 = type, x/y already initialised
CreateObjectInSlot
          lda PARAM3
          sta SPRITE_ACTIVE,x

          ;enable sprite
          lda BIT_TABLE,x
          ora VIC.SPRITE_ENABLE
          sta VIC.SPRITE_ENABLE

          ;sprite color

          ;disable mc flag
          lda BIT_TABLE,x
          eor #$ff
          and VIC.SPRITE_MULTICOLOR
          sta VIC.SPRITE_MULTICOLOR

          ldy PARAM3

          ;initialise enemy values
          lda TYPE_START_SPRITE,y
          sta SPRITE_IMAGE,x
          sta SPRITE_BASE_IMAGE,x
          sta SPRITE_POINTER_BASE,x
          lda TYPE_START_HEIGHT_CHARS,y
          sta SPRITE_HEIGHT_CHARS,x
          lda TYPE_START_SPRITE_HP,y
          sta SPRITE_HP,x
          lda TYPE_START_BEHAVIOR_LO,y
          sta SPRITE_BEHAVIOUR_LO,x
          lda TYPE_START_BEHAVIOR_HI,y
          sta SPRITE_BEHAVIOUR_HI,x

          lda TYPE_START_WIDTH_CHARS,y
          sta SPRITE_WIDTH_CHARS,x
          lda TYPE_START_COLOR,y
          sta VIC.SPRITE_COLOR,x
          bpl +
          ;set MC flag
          lda BIT_TABLE,x
          ora VIC.SPRITE_MULTICOLOR
          sta VIC.SPRITE_MULTICOLOR

+
          txa
          sta SPRITE_MAIN_INDEX,x

          lda #0
          ;look right per default
          sta SPRITE_DIRECTION,x
          sta SPRITE_DIRECTION_Y,x
          sta SPRITE_ANIM_POS,x
          sta SPRITE_ANIM_DELAY,x
          sta SPRITE_MOVE_POS,x
          sta SPRITE_MOVE_POS_Y,x
          sta SPRITE_MOVE_DX_LO,x
          sta SPRITE_MOVE_DX_HI,x
          sta SPRITE_MOVE_DY_LO,x
          sta SPRITE_MOVE_DY_HI,x
          sta SPRITE_STATE,x
          sta SPRITE_STATE_POS,x
          sta SPRITE_LIFETIME,x
          sta SPRITE_SHOT_HIT_COUNT,x
          sta SPRITE_MOVE_DX,x
          sta SPRITE_MOVE_DY,x
          sta SPRITE_FRACTION,x
          sta SPRITE_HITBACK,x
          lda #1
          sta SPRITE_NUM_PARTS,x

          lda TYPE_START_SPRITE_OFFSET_X,y
          sta PARAM4

          lda BIT_TABLE,x
          eor #$ff
          and VIC.SPRITE_EXPAND_X
          sta VIC.SPRITE_EXPAND_X
          lda BIT_TABLE,x
          eor #$ff
          and VIC.SPRITE_EXPAND_Y
          sta VIC.SPRITE_EXPAND_Y

          lda TYPE_START_SPRITE_FLAGS,y
          and #SF_EXPAND_X
          beq +

          lda VIC.SPRITE_EXPAND_X
          ora BIT_TABLE,x
          sta VIC.SPRITE_EXPAND_X

+
          lda TYPE_START_SPRITE_FLAGS,y
          and #SF_EXPAND_Y
          beq +

          lda VIC.SPRITE_EXPAND_Y
          ora BIT_TABLE,x
          sta VIC.SPRITE_EXPAND_Y

+

          lda TYPE_START_SPRITE_FLAGS,y
          and #SF_START_INVINCIBLE
          beq +
          lda #$80
          sta SPRITE_STATE,x

+
          lda PARAM4
.AdjustX
          beq .NoXMovementNeeded
          jsr MoveSpriteRight
          dec PARAM4
          jmp .AdjustX

.NoXMovementNeeded
          ldy SPRITE_ACTIVE,x
          lda TYPE_START_SPRITE_OFFSET_Y,y
          sta PARAM4

          jsr MoveSpriteDown
          lda PARAM4
.AdjustY
          beq AddObject.NoYMovementNeeded

          ;lda SPRITE_POS_Y,x
          ;sec
          ;sbc PARAM4
          ;sta SPRITE_POS_Y,x
          ;txa
          ;asl
          ;tay
          ;sta VIC.SPRITE_Y_POS,y
          ;ldy SPRITE_ACTIVE,x

          jsr MoveSpriteUp
          dec PARAM4
          jmp .AdjustY

.NoYMovementNeeded
          lda #1
          rts



!zone FindEmptySpriteSlot
;Looks for an empty sprite slot, returns in X. Starts with Index X
;#1 in A when empty slot found, #0 when full
FindEmptySpriteSlot
.CheckSlot
          lda SPRITE_ACTIVE,x
          beq .FoundSlot

          inx
          cpx #8
          bne .CheckSlot

          lda #0
          rts

.FoundSlot
          lda #1
          rts


;Removed object from array
;X = index of object
!lzone RemoveObject
          ;remove from array
          lda #0
          sta SPRITE_ACTIVE,x

          ;disable sprite
          lda BIT_TABLE,x
          eor #$ff
          and VIC.SPRITE_ENABLE
          sta VIC.SPRITE_ENABLE

          lda BIT_TABLE,x
          eor #$ff
          and VIC.SPRITE_EXPAND_X
          sta VIC.SPRITE_EXPAND_X

          lda BIT_TABLE,x
          eor #$ff
          and VIC.SPRITE_EXPAND_Y
          sta VIC.SPRITE_EXPAND_Y

          rts



!lzone RemoveAllObjects
          jsr RemoveAllObjectsButPlayer

          lda #0
          sta VIC.SPRITE_ENABLE
          sta SPRITE_POS_X_EXTEND
          sta VIC.SPRITE_X_EXTEND
          sta SPRITE_ACTIVE
          rts



!lzone RemoveAllObjectsButPlayer
          ldx #1
.Loop
-
          lda #TYPE_NONE
          sta SPRITE_ACTIVE,x
          inx
          cpx #8
          bne -

          lda #1
          sta VIC.SPRITE_ENABLE
          lda SPRITE_POS_X_EXTEND
          and #$01
          sta SPRITE_POS_X_EXTEND
          sta VIC.SPRITE_X_EXTEND
          rts



!lzone BHNone
          rts



!lzone BHPlayer
          ;check for collision
          lda SPRITE_HITBACK
          beq .NoHitback
          jmp .CurrentlyInvincible
.NoHitback

          lda #1
          sta CURRENT_SUB_INDEX

-
          ldy CURRENT_SUB_INDEX
          lda SPRITE_ACTIVE,y
          tay
          lda IS_TYPE_ENEMY,y
          cmp #1
          beq +
          cmp #4
          beq +
          cmp #6
          beq +
          cmp #2
          beq +
          jmp .Skip
+
          jsr IsEnemyCollidingWithObject
          bne +
          jmp .Skip
+

          ;colliding!
          ldy CURRENT_SUB_INDEX
          lda SPRITE_ACTIVE,y
          tay
          lda IS_TYPE_ENEMY,y
          cmp #2
          bne +

          ;a pickup
          cpy #TYPE_TONGUE
          bne .NotTongue

          lda NUM_BOSSES_DEFEATED
          cmp #3
          bne .Skip

          lda #1
          sta GAME_COMPLETED
          jmp .Skip

.NotTongue
          lda SPRITE_HP
          cmp #3
          beq .AlreadyMax

          ldy SPRITE_HP
          lda #0
          sta SCREEN_CHAR + 24 * 40 + PANEL_HEALTH_OFFSET,y
          inc SPRITE_HP

.AlreadyMax
          ldy #SFX_POWER_UP
          jsr PlaySoundEffect

          ldx CURRENT_SUB_INDEX
          jsr RemoveObject
          ldx CURRENT_INDEX
          rts

+

          lda SPRITE_HP
          beq .AlreadyDead
          dec SPRITE_HP
.AlreadyDead
          ldy SPRITE_HP
          lda #27
          sta SCREEN_CHAR + 24 * 40 + PANEL_HEALTH_OFFSET,y
          cpy #0
          beq .Dead

          lda SPRITE_HITBACK,x
          bne .AlreadyHit

          lda #20
          sta SPRITE_HITBACK,x
          lda VIC.SPRITE_COLOR,x
          sta SPRITE_HITBACK_ORIG_COLOR,x
          lda #1
          sta VIC.SPRITE_COLOR,x
.AlreadyHit
          rts


.Dead
          ldy #0
          jsr DisplayPanelMessage

          lda #2
          jsr MUSIC_PLAYER

          lda #1
          sta PLAYER_DEAD
          lda #0
          sta PLAYER_DEAD_DELAY
          sta PLAYER_DEAD_MESSAGE

          ldx #0
          lda #<BHPlayerDead
          ldy #>BHPlayerDead
          jmp SetBehaviour

.Skip
          inc CURRENT_SUB_INDEX
          lda CURRENT_SUB_INDEX
          cmp #8
          beq .SkipDone
          jmp -

.SkipDone

          ldx CURRENT_INDEX

.CurrentlyInvincible
          ;get dir from joy
          lda JOY_VALUE
          and #$0f
          eor #$0f
          beq +
          sta PLAYER_LAST_MOVED_DIR
+

          lda JOY_VALUE
          and #JOY_FIRE
          bne .NotFire

          ;released?
          lda JOY_VALUE_RELEASED
          and #JOY_FIRE
          beq .NotReleased

          lda JOY_VALUE_RELEASED
          and #~JOY_FIRE
          sta JOY_VALUE_RELEASED

          ;get dir from joy
          lda JOY_VALUE
          and #$0f
          eor #$0f
          bne +
          lda PLAYER_LAST_MOVED_DIR
+
          tay

          lda JOY_DIR_TO_SHOT_DIR_TABLE,y
          bmi .NoValidDir
          sta LOCAL1

          lda JOY_DIR_TO_SPRITE_IMAGE,y
          sta LOCAL2

          lda SPRITE_CHAR_POS_X
          sta PARAM1
          lda SPRITE_CHAR_POS_Y
          sta PARAM2
          lda #TYPE_PLAYER_SHOT
          sta PARAM3
          jsr AddObject
          beq .NoFreeSlot

          lda LOCAL1
          sta SPRITE_DIRECTION,x
          lda LOCAL2
          sta SPRITE_IMAGE,x

          ldy #SFX_SHOOT
          jsr PlaySoundEffect

.NoFreeSlot
          ldx #0

.NoValidDir
          rts

.NotReleased

.NotFire
          ldy SPEED_TABLE_POS
          lda SPEED_TABLE + 3 * 8,y
          beq +
          jsr .PlayerMovement
+
          jsr .PlayerMovement

          lda LOCAL1
          bne .Animate
          rts

.Animate
          inc SPRITE_ANIM_DELAY,x
          lda SPRITE_ANIM_DELAY,x
          and #$03
          bne +
          dec SPRITE_ANIM_POS,x
          lda SPRITE_ANIM_POS,x
          and #$01
          clc
          adc SPRITE_BASE_IMAGE,x
          sta SPRITE_IMAGE,x
+
          rts


.PlayerMovement
          lda #0
          sta LOCAL1
          lda JOY_VALUE
          and #JOY_LEFT
          bne .NotLeft

          jsr ObjectMoveLeftBlocking
          lda #SPRITE_PLAYER_LEFT
          sta SPRITE_BASE_IMAGE,x
          inc LOCAL1
          jmp .NotRight

.NotLeft
          lda JOY_VALUE
          and #JOY_RIGHT
          bne .NotRight

          jsr ObjectMoveRightBlocking
          lda #SPRITE_PLAYER_RIGHT
          sta SPRITE_BASE_IMAGE
          inc LOCAL1

.NotRight
          lda JOY_VALUE
          and #JOY_UP
          bne .NotUp

          jsr ObjectMoveUpBlocking
          lda #SPRITE_PLAYER_UP
          sta SPRITE_BASE_IMAGE
          inc LOCAL1
          jmp .NotDown

.NotUp

          lda JOY_VALUE
          and #JOY_DOWN
          bne .NotDown

          jsr ObjectMoveDownBlocking
          lda #SPRITE_PLAYER_DOWN
          sta SPRITE_BASE_IMAGE
          inc LOCAL1

.NotDown
          rts


JOY_DIR_TO_SHOT_DIR_TABLE
          !byte 255     ;no dir
          !byte 2       ;up
          !byte 6       ;down
          !byte 255     ;invalid dir
          !byte 4       ;left
          !byte 3       ;left/up
          !byte 5       ;left/down
          !byte 255     ;invalid dir
          !byte 0       ;right
          !byte 1       ;right/up
          !byte 7       ;right/down
          !byte 255     ;invalid dir
          !byte 255     ;invalid dir
          !byte 255     ;invalid dir
          !byte 255     ;invalid dir
          !byte 255     ;invalid dir
          !byte 255     ;invalid dir

JOY_DIR_TO_SPRITE_IMAGE
          !byte 255     ;no dir
          !byte SPRITE_PLAYER_SHOT_V    ;up
          !byte SPRITE_PLAYER_SHOT_V    ;down
          !byte 255     ;invalid dir
          !byte SPRITE_PLAYER_SHOT_H    ;left
          !byte SPRITE_PLAYER_SHOT_ULLR ;left/up
          !byte SPRITE_PLAYER_SHOT_LLUR ;left/down
          !byte 255     ;invalid dir
          !byte SPRITE_PLAYER_SHOT_H    ;right
          !byte SPRITE_PLAYER_SHOT_LLUR ;right/up
          !byte SPRITE_PLAYER_SHOT_ULLR ;right/down
          !byte 255     ;invalid dir
          !byte 255     ;invalid dir
          !byte 255     ;invalid dir
          !byte 255     ;invalid dir
          !byte 255     ;invalid dir
          !byte 255     ;invalid dir



;SPRITE_DIRECTION = 0 E
;                   1 NE
;                   2 N
;                   3 NW
;                   4 W
;                   5 SW
;                   6 S
;                   7 SE
!lzone BHPlayerShot
          ;check for collision
          lda #1
          sta CURRENT_SUB_INDEX

-
          ldy CURRENT_SUB_INDEX
          lda SPRITE_ACTIVE,y
          tay
          lda IS_TYPE_ENEMY,y
          cmp #1
          beq +
          cmp #4
          beq +
          jmp .Skip
+
          jsr IsEnemyCollidingWithObject
          bne +
          jmp .Skip
+
          ;shot colliding with enemy
          jsr RemoveObject

          ldx CURRENT_SUB_INDEX
          dec SPRITE_HP,x
          beq .EnemyKilled

          ;mark as hit
          lda SPRITE_HITBACK,x
          bne .AlreadyHit

          lda #5
          sta SPRITE_HITBACK,x
          lda VIC.SPRITE_COLOR,x
          sta SPRITE_HITBACK_ORIG_COLOR,x
          lda #1
          sta VIC.SPRITE_COLOR,x

.AlreadyHit
          ;enemy only hit!
          lda #1
          ldx #PANEL_SCORE_OFFSET
          jsr IncScore

          ldy #SFX_HURT
          jsr PlaySoundEffect

          ldx CURRENT_INDEX
          rts

.EnemyKilled
          lda #0
          sta .KILLED_ENEMY_WAS_BOSS
          ldx CURRENT_SUB_INDEX
          ldy SPRITE_ACTIVE,x
          lda IS_TYPE_ENEMY,y
          cmp #4
          bne .NotABoss

          inc .KILLED_ENEMY_WAS_BOSS

.NotABoss

          ;explode or health?
          jsr GenerateRandomNumber
          and #$0f
          bne +

          lda #TYPE_PICKUP
          sta PARAM3
          jsr CreateObjectInSlot

          ldy #SFX_PICK_PLUS
          jsr PlaySoundEffect
          jmp .PickupCreated

+

          ldx CURRENT_SUB_INDEX
          lda BIT_TABLE,x
          eor #$ff
          and VIC.SPRITE_MULTICOLOR
          sta VIC.SPRITE_MULTICOLOR
          lda #SPRITE_EXPLOSION
          sta SPRITE_IMAGE,x
          sta SPRITE_BASE_IMAGE,x

          lda #<BHExplosion
          ldy #>BHExplosion
          jsr SetBehaviour

          ldy #SFX_EXPLODE
          jsr PlaySoundEffect

.PickupCreated
          lda #5
          ldx #PANEL_SCORE_OFFSET
          jsr IncScore

          ;mark boss as defeated
          lda .KILLED_ENEMY_WAS_BOSS
          beq .NotABoss2

          ldy CURRENT_SPECIAL_SCREEN
          bmi +

          lda SCREEN_GRID,y
          ora #$20
          sta SCREEN_GRID,y

          inc NUM_BOSSES_DEFEATED

+
.NotABoss2
          ldx CURRENT_INDEX
          rts

.KILLED_ENEMY_WAS_BOSS
          !byte 0

.Skip
          inc CURRENT_SUB_INDEX
          lda CURRENT_SUB_INDEX
          cmp #8
          beq .SkipDone
          jmp -

.SkipDone
          ldx CURRENT_INDEX
          ldy SPRITE_DIRECTION,x

          lda SHOT_DELTA_X,y
          sta PARAM3
          lda SHOT_DELTA_Y,y
          sta PARAM4

.VertMoveDone
          lda PARAM3
          ora PARAM4
          bne +

          rts

+
          lda PARAM3
          beq .VerticalMove
          bmi .GoLeft

          jsr ObjectMoveRightBlocking
          beq .Blocked
          dec PARAM3
          jmp .HorzMoveDone


.GoLeft
          jsr ObjectMoveLeftBlocking
          beq .Blocked
          inc PARAM3

.HorzMoveDone
.VerticalMove
          lda PARAM4
          beq .VertMoveDone
          bmi .GoUp

          jsr ObjectMoveDownBlocking
          beq .Blocked
          dec PARAM4
          jmp .VertMoveDone

.GoUp
          jsr ObjectMoveUpBlocking
          beq .Blocked
          inc PARAM4
          jmp .VertMoveDone

.Blocked
          ;TODO - explode
          jmp RemoveObject



SHOT_DELTA_X
          !byte 16,12,0,-12,-16,-12,0,12
SHOT_DELTA_Y
          !byte 0,-12,-16,-12,0,12,16,12




;state = 0 > look for random direction
;      = 1 > move
!lzone BHLarva
          lda SPRITE_STATE,x
          bne .Move

          ;von PARAM1,PARAM2 nach PARAM3,PARAM4
          ;sets values in PARAM5
          lda SPRITE_CHAR_POS_X,x
          sta PARAM1
          lda SPRITE_CHAR_POS_Y,x
          sta PARAM2
          lda SPRITE_CHAR_POS_X
          beq +
          sec
          sbc #1
+
          sta PARAM3
          lda SPRITE_CHAR_POS_Y
          sta PARAM4
          stx PARAM5
          jsr CalcDelta


          ;von PARAM1+PARAM6,PARAM2+PARAM8 nach MOVE_TARGET_X_LO+MOVE_TARGET_X_HI,MOVE_TARGET_Y+PARAM9
          ;sets values in PARAM5
          ;PARAM1 = lo x1, PARAM6 = hi x1
          ;MOVE_TARGET_X_LO = lo x2, MOVE_TARGET_X_HI = hi x2

          ;lda #0
;          sta PARAM6
;          sta PARAM8
;          sta PARAM9
;          sta MOVE_TARGET_X_HI,x
;
;          ;x
;          lda SPRITE_POS_X,x
;          sta PARAM1
;          lda SPRITE_POS_X_EXTEND
;          and BIT_TABLE,x
;          beq +
;          inc PARAM6
;+
;          ;y
;          lda SPRITE_POS_Y,x
;          sta PARAM2
;
;          ;target X
;          lda SPRITE_POS_X
;          sta MOVE_TARGET_X_LO,x
;          lda SPRITE_POS_X_EXTEND
;          and #$01
;          beq +
;          inc MOVE_TARGET_X_HI,x
;+
;
;          ;target Y
;          lda SPRITE_POS_Y
;          sta MOVE_TARGET_Y,x
;
;          jsr CalcDelta
          lda #1
          sta SPRITE_STATE,x

.Move

          ldy SPEED_TABLE_POS
          lda SPEED_TABLE + 3 * 8,y
          beq .SkipMovement

          lda #1
          sta PARAM3
          jsr DeltaMove
          ;bne .KeepMoving

          lda #0
          sta SPRITE_STATE,x

.SkipMovement
;.KeepMoving
          inc SPRITE_ANIM_POS,x
          lda SPRITE_ANIM_POS,x
          lsr
          lsr
          lsr
          and #$01
          clc
          adc SPRITE_BASE_IMAGE,x
          sta SPRITE_IMAGE,x

          rts



;state = 0 > look for random direction
;      = 1 > move
!lzone BHAmoeba
          inc SPRITE_ANIM_POS,x
          lda SPRITE_ANIM_POS,x
          lsr
          and #$03
          clc
          adc SPRITE_BASE_IMAGE,x
          sta SPRITE_IMAGE,x


          lda SPRITE_STATE,x
          bne .Move

          lda #0
          sta PARAM5
          lda #2
          sta PARAM6
          jsr GenerateRangedRandom
          sec
          sbc #1
          sta SPRITE_MOVE_DX,x

          lda #0
          sta PARAM5
          lda #2
          sta PARAM6
          jsr GenerateRangedRandom
          sec
          sbc #1
          sta SPRITE_MOVE_DY,x

          jsr GenerateRandomNumber
          and #$3f
          clc
          adc #5
          sta SPRITE_MOVE_POS,x

          inc SPRITE_STATE,x

.Move
          lda SPRITE_MOVE_DX,x
          beq .NoX
          bmi .GoL

          jsr ObjectMoveRightBlocking
          beq .Blocked
          jmp .NoX

.GoL
          jsr ObjectMoveLeftBlocking
          beq .Blocked

.NoX
          lda SPRITE_MOVE_DY,x
          beq .NoY

          bmi .GoU

          jsr ObjectMoveDownBlocking
          beq .Blocked
          jmp .NoY

.GoU
          jsr ObjectMoveUpBlocking
          beq .Blocked


.NoY
          dec SPRITE_MOVE_POS,x
          bne .NotDone

.Blocked
          lda #0
          sta SPRITE_STATE,x

.NotDone
          rts



!lzone BHPickup
          inc SPRITE_LIFETIME,x
          bne +

          jmp RemoveObject

+
          rts



!lzone BHBossShot
          jsr GenerateRandomNumber
          sta VIC.SPRITE_COLOR,x

          lda #3
          sta PARAM3
          jsr DeltaMove
          bne .KeepGoing

          jmp RemoveObject

.KeepGoing
          rts



!lzone BHBossHeart
          inc SPRITE_STATE_POS,x
          lda SPRITE_STATE_POS,x
          cmp #$3f
          bne +

          lda #0
          sta SPRITE_STATE_POS,x

          ;spawn shot
          jsr GenerateRandomNumber
          and #$03
          clc
          adc SPRITE_CHAR_POS_X,x
          sta PARAM1

          jsr GenerateRandomNumber
          and #$03
          clc
          adc SPRITE_CHAR_POS_Y,x
          sta PARAM2
          lda #TYPE_BOSS_SHOT
          sta PARAM3
          jsr AddObject

          lda SPRITE_CHAR_POS_X
          sta PARAM3
          lda SPRITE_CHAR_POS_Y
          sta PARAM4
          stx PARAM5
          jsr CalcDelta

          ldx CURRENT_INDEX


+

          ;speed up animation if hurt
          lda SPRITE_HP,x
          cmp #50
          bcs +
          inc SPRITE_ANIM_POS,x
+

          inc SPRITE_ANIM_POS,x
          lda SPRITE_ANIM_POS,x
          lsr
          lsr
          lsr
          and #$03
          clc
          adc SPRITE_BASE_IMAGE,x
          sta SPRITE_IMAGE,x
          rts



!lzone BHTitleEye
          inc SPRITE_STATE_POS,x
          lda SPRITE_STATE_POS,x
          and #$1f
          bne +

          lda #0
          sta PARAM5
          lda #2
          sta PARAM6
          jsr GenerateRangedRandom
          clc
          adc SPRITE_BASE_IMAGE,x
          sta SPRITE_IMAGE,x

+
          rts



!lzone BHBossEye
          inc SPRITE_STATE_POS,x
          lda SPRITE_STATE_POS,x
          and #$1f
          bne +

          lda #0
          sta PARAM5
          lda #2
          sta PARAM6
          jsr GenerateRangedRandom
          clc
          adc SPRITE_BASE_IMAGE,x
          sta SPRITE_IMAGE,x

+

          lda SPRITE_STATE_POS,x
          and #$3f
          bne +


          jsr GenerateRandomNumber
          and #$03
          clc
          adc SPRITE_CHAR_POS_X,x
          sta PARAM1

          jsr GenerateRandomNumber
          and #$03
          clc
          adc SPRITE_CHAR_POS_Y,x
          sta PARAM2
          lda #TYPE_LARVA
          sta PARAM3
          jsr AddObject
          ldx CURRENT_INDEX

+

          rts




;move object left if not blocked
;x = object index
;returns: a=1 if moved, a=0 if blocked
!lzone ObjectMoveLeftBlocking
          lda SPRITE_CHAR_POS_X_DELTA,x
          beq .CheckCanMoveLeft

.CanMoveLeft
          jsr ObjectMoveLeft

          lda #1
          rts

.CheckCanMoveLeft
          lda SPRITE_CHAR_POS_X,x
          beq .BlockedBorderLeft

          lda SPRITE_CHAR_POS_Y,x
          sec
          sbc SPRITE_HEIGHT_CHARS,x
          bmi .BlockedLeft
          tay
          iny
          sty PARAM2
          lda SCREEN_LINE_OFFSET_TABLE_LO,y
          sta ZEROPAGE_POINTER_1

          lda SCREEN_LINE_OFFSET_TABLE_HI,y
          sta ZEROPAGE_POINTER_1 + 1

          lda SPRITE_HEIGHT_CHARS,x
          sta PARAM6

          lda SPRITE_CHAR_POS_Y_DELTA,x
          beq +
          inc PARAM6
+

--
          lda SPRITE_CHAR_POS_X,x
          tay
          dey

          lda (ZEROPAGE_POINTER_1),y
          jsr IsCharBlocking
          bne .BlockedLeft

          inc PARAM2
          dec PARAM6
          beq .CanMoveLeft

          lda ZEROPAGE_POINTER_1
          clc
          adc #40
          sta ZEROPAGE_POINTER_1
          bcc +
          inc ZEROPAGE_POINTER_1 + 1
+
          jmp --

.BlockedBorderLeft
          cpx #0
          bne .BlockedLeft

          ;go right screen
          dec CURRENT_SCREEN_GRID
          jsr BuildScreen

          ldx #0

          lda SPRITE_CHAR_POS_X
          clc
          adc #37
          sta SPRITE_CHAR_POS_X
          lda SPRITE_POS_X
          clc
          adc #<( 37 * 8 )
          sta SPRITE_POS_X
          sta VIC.SPRITE_X_POS
          lda SPRITE_POS_X_EXTEND
          ora #1
          sta VIC.SPRITE_X_EXTEND
          sta SPRITE_POS_X_EXTEND

          jsr ScreenOn

.BlockedLeft
          lda #0
          rts




;move object left
;x = object index
!lzone ObjectMoveLeft
          lda SPRITE_NUM_PARTS,x
          sta PARAM11

-
          lda SPRITE_CHAR_POS_X_DELTA,x
          bne .NoCharStep

          lda #8
          sta SPRITE_CHAR_POS_X_DELTA,x
          dec SPRITE_CHAR_POS_X,x

.NoCharStep
          dec SPRITE_CHAR_POS_X_DELTA,x

          jsr MoveSpriteLeft

          inx
          dec PARAM11
          bne -

          lda SPRITE_MAIN_INDEX - 1,x
          tax
          rts



;move object right if not blocked
;x = object index
;return a=1 when moved, 0 when blocked
!lzone ObjectMoveRightBlocking
          lda SPRITE_CHAR_POS_X_DELTA,x
          beq .CheckCanMoveRight

.CanMoveRight
          jsr ObjectMoveRight
          lda #1
          rts

.CheckCanMoveRight
          lda SPRITE_CHAR_POS_Y,x
          sec
          sbc SPRITE_HEIGHT_CHARS,x
          bmi .BlockedRight
          tay
          iny
          sty PARAM2
          lda SCREEN_LINE_OFFSET_TABLE_LO,y
          sta ZEROPAGE_POINTER_1
          lda SCREEN_LINE_OFFSET_TABLE_HI,y
          sta ZEROPAGE_POINTER_1 + 1

          lda SPRITE_HEIGHT_CHARS,x
          sta PARAM6

          lda SPRITE_CHAR_POS_Y_DELTA,x
          beq +
          inc PARAM6
+

          lda SPRITE_CHAR_POS_X,x
          clc
          adc SPRITE_WIDTH_CHARS,x
          tay
          cpy #40
          beq .BlockedRightBorder
--
          lda (ZEROPAGE_POINTER_1),y
          jsr IsCharBlocking
          bne .BlockedRight

          inc PARAM2
          dec PARAM6
          beq .CanMoveRight

          lda ZEROPAGE_POINTER_1
          clc
          adc #40
          sta ZEROPAGE_POINTER_1
          bcc +
          inc ZEROPAGE_POINTER_1 + 1
+
          jmp --

.BlockedRightBorder
          cpx #0
          bne .BlockedRight

          ;go right screen
          inc CURRENT_SCREEN_GRID
          jsr BuildScreen

          ldx #0

          lda SPRITE_CHAR_POS_X
          sec
          sbc #37
          sta SPRITE_CHAR_POS_X
          lda SPRITE_POS_X
          sec
          sbc #<( 37 * 8 )
          sta SPRITE_POS_X
          sta VIC.SPRITE_X_POS
          lda SPRITE_POS_X_EXTEND
          and #$fe
          sta VIC.SPRITE_X_EXTEND
          sta SPRITE_POS_X_EXTEND

          jsr ScreenOn

.BlockedRight
          lda #0
          rts



;move object right
;x = object index
!lzone ObjectMoveRight
          lda SPRITE_NUM_PARTS,x
          sta PARAM11

-
          inc SPRITE_CHAR_POS_X_DELTA,x

          lda SPRITE_CHAR_POS_X_DELTA,x
          cmp #8
          bne .NoCharStep

          lda #0
          sta SPRITE_CHAR_POS_X_DELTA,x
          inc SPRITE_CHAR_POS_X,x

.NoCharStep
          jsr MoveSpriteRight
          inx
          dec PARAM11
          bne -

          lda SPRITE_MAIN_INDEX - 1,x
          tax
          rts



;move object up if not blocked
;x = object index
;return a=1 when moved, 0 when blocked
!lzone ObjectMoveUpBlocking
          lda SPRITE_CHAR_POS_Y_DELTA,x
          beq .CheckCanMoveUp

.CanMoveUp
          jsr ObjectMoveUp
          lda #1
          rts

.CheckCanMoveUp
          ;at top of screen?
          lda SPRITE_CHAR_POS_Y,x
          sec
          sbc SPRITE_HEIGHT_CHARS,x
          bmi .BlockedTop
          beq .BlockedTop

          lda SPRITE_WIDTH_CHARS,x
          sta PARAM5

          lda SPRITE_CHAR_POS_X_DELTA,x
          beq .NoSecondCharCheckNeeded
          inc PARAM5
.NoSecondCharCheckNeeded

          lda SPRITE_CHAR_POS_Y,x
          sec
          sbc SPRITE_HEIGHT_CHARS,x
          tay
          sty PARAM2
          lda SCREEN_LINE_OFFSET_TABLE_LO,y
          sta ZEROPAGE_POINTER_1
          lda SCREEN_LINE_OFFSET_TABLE_HI,y
          sta ZEROPAGE_POINTER_1 + 1

          lda SPRITE_CHAR_POS_X,x
          tay
          dey
-
          iny
          lda (ZEROPAGE_POINTER_1),y

          jsr IsCharBlocking
          bne .BlockedUp

          dec PARAM5
          bne -

          jmp .CanMoveUp

.BlockedTop
          cpx #0
          bne .BlockedUp

          ;go up screen
          lda CURRENT_SCREEN_GRID
          sec
          sbc #SCREEN_GRID_WIDTH
          sta CURRENT_SCREEN_GRID
          jsr BuildScreen

          ldx #0

          lda #19
          clc
          adc SPRITE_CHAR_POS_Y
          sta SPRITE_CHAR_POS_Y
          lda SPRITE_POS_Y
          clc
          adc #19 * 8
          sta SPRITE_POS_Y
          sta VIC.SPRITE_Y_POS

          jsr ScreenOn

.BlockedUp
          lda #0
          rts



;move object up
;x = object index
!lzone ObjectMoveUp
          lda SPRITE_NUM_PARTS,x
          sta PARAM11
-
          dec SPRITE_CHAR_POS_Y_DELTA,x

          lda SPRITE_CHAR_POS_Y_DELTA,x
          cmp #$ff
          bne .NoCharStep

          dec SPRITE_CHAR_POS_Y,x
          lda #7
          sta SPRITE_CHAR_POS_Y_DELTA,x

.NoCharStep
          jsr MoveSpriteUp

          inx
          dec PARAM11
          bne -

          lda SPRITE_MAIN_INDEX - 1,x
          tax
          rts



;returns 0 if blocked, 1 if move is possible
!lzone CheckCanMoveDown
          lda SPRITE_WIDTH_CHARS,x
          sta PARAM5

          lda SPRITE_CHAR_POS_X_DELTA,x
          beq .NoSecondCharCheckNeeded
          inc PARAM5
.NoSecondCharCheckNeeded

          ldy SPRITE_CHAR_POS_Y,x
          iny
          cpy #24
          beq .BlockedBorderDown

          lda SCREEN_LINE_OFFSET_TABLE_LO,y
          sta ZEROPAGE_POINTER_1
          lda SCREEN_LINE_OFFSET_TABLE_HI,y
          sta ZEROPAGE_POINTER_1 + 1

          lda SPRITE_CHAR_POS_X,x
          tay
          dey
-
          iny

          lda (ZEROPAGE_POINTER_1),y

          jsr IsCharBlocking
          bne .BlockedDown

          dec PARAM5
          bne -

          ;not blocked
          lda #1
          rts

.BlockedBorderDown
          cpx #0
          bne .BlockedDown

          ;go up screen
          lda CURRENT_SCREEN_GRID
          clc
          adc #SCREEN_GRID_WIDTH
          sta CURRENT_SCREEN_GRID
          jsr BuildScreen

          ldx #0

          lda SPRITE_CHAR_POS_Y
          sec
          sbc #20
          sta SPRITE_CHAR_POS_Y
          lda SPRITE_POS_Y
          sec
          sbc #20 * 8
          sta SPRITE_POS_Y
          sta VIC.SPRITE_Y_POS

          jsr ScreenOn

.BlockedDown
          lda #0
          rts



;move object down if not blocked
;x = object index
;a = 1 if moved, 0 if blocked
!lzone ObjectMoveDownBlocking

          lda SPRITE_CHAR_POS_Y_DELTA,x
          bne +

          jsr CheckCanMoveDown
          bne +

          lda #0
          rts
+

          jsr ObjectMoveDown
          lda #1
          rts



;move object down
;x = object index
;------------------------------------------------------------
!lzone ObjectMoveDown
          lda SPRITE_NUM_PARTS,x
          sta PARAM11
-
          inc SPRITE_CHAR_POS_Y_DELTA,x

          lda SPRITE_CHAR_POS_Y_DELTA,x
          cmp #8
          bne .NoCharStep

          lda #0
          sta SPRITE_CHAR_POS_Y_DELTA,x
          inc SPRITE_CHAR_POS_Y,x

.NoCharStep
          jsr MoveSpriteDown

          inx
          dec PARAM11
          bne -

          lda SPRITE_MAIN_INDEX - 1,x
          tax
          rts



!lzone BHPlayerDead
          inc SPRITE_ANIM_DELAY,x
          lda SPRITE_ANIM_DELAY,x
          and #$01
          beq +

          lda SPRITE_ANIM_POS,x
          cmp #2
          beq .Done

          inc SPRITE_ANIM_POS,x
          lda SPRITE_ANIM_POS,x
          clc
          adc #SPRITE_PLAYER_DYING
          sta SPRITE_IMAGE,x
+
.Done
          rts



!lzone BHExplosion
          inc SPRITE_ANIM_DELAY,x
          lda SPRITE_ANIM_DELAY,x
          and #$01
          beq +

          inc SPRITE_ANIM_POS,x
          lda SPRITE_ANIM_POS,x
          cmp #4
          beq .Done

          clc
          adc SPRITE_BASE_IMAGE,x
          sta SPRITE_IMAGE,x
+
          rts

.Done
          jmp RemoveObject



!zone IsEnemyCollidingWithObject


.CalculateSimpleXPos
          ;Returns a with simple x pos (x halved + 128 if > 256)
          ;modifies y
          lda BIT_TABLE,x
          and SPRITE_POS_X_EXTEND
          beq .NoXBit

          lda SPRITE_POS_X,x
          lsr
          clc
          adc #128
          rts

.NoXBit
          lda SPRITE_POS_X,x
          lsr
          rts


;modifies X
;check y pos
;check object collision with other object (object CURRENT_INDEX vs CURRENT_SUB_INDEX)
;return a = 1 when colliding, a = 0 when not
;------------------------------------------------------------
;temp PARAM8 holds height to check in pixels
IsEnemyCollidingWithObject
          ldx CURRENT_SUB_INDEX
          ldy CURRENT_INDEX
          lda SPRITE_HEIGHT_CHARS,y
          asl
          asl
          asl
          sta PARAM8
          lda SPRITE_POS_Y,y
          sta PARAM2

          lda SPRITE_POS_Y,x
          sec
          sbc PARAM8         ;offset to bottom
          cmp PARAM2
          bcs .NotTouching

          ;sprite x is above sprite y
          clc
          adc PARAM8
          sta PARAM1

          lda SPRITE_HEIGHT_CHARS,x
          asl
          asl
          asl
          clc
          adc PARAM1
          cmp PARAM2
          bcc .NotTouching

          ;X = Index in enemy-table
          lda SPRITE_WIDTH_CHARS,x
          asl
          asl
          ;asl
          sta PARAM2

          jsr .CalculateSimpleXPos
          sta PARAM1
          ldx CURRENT_INDEX
          jsr .CalculateSimpleXPos

          sec
          sbc PARAM2 ;#8    ;was 4
          sbc PARAM2 ;#8    ;was 4
          ;position X-Anfang Player - 12 Pixel
          cmp PARAM1
          bcs .NotTouching
          ;adc #16   ;was 8
          clc
          adc PARAM2
          clc
          adc PARAM2
          cmp PARAM1
          bcc .NotTouching


          lda #1
          ;sta VIC.BORDER_COLOR
          rts

.NotTouching
          lda #0
          ;sta VIC.BORDER_COLOR
          rts



;IsCharBlocking
;checks if a char is blocking
;A = character, ZEROPAGE_POINTER1 + y is char offset
;returns 1 for blocking, 0 for not blocking,
!zone IsCharBlocking
IsCharBlocking
          cmp #128
          bcc .NotBlocking

          ;blocking
          lda #1
          rts

.NotBlocking
          lda #0
          rts



;a = lo, y = hi behaviour
!lzone SetBehaviour
          sta SPRITE_BEHAVIOUR_LO,x
          tya
          sta SPRITE_BEHAVIOUR_HI,x

          lda #0
          sta SPRITE_STATE,x
          sta SPRITE_ANIM_POS,x
          sta SPRITE_ANIM_DELAY,x
          rts


;0 = normal, 1 = enemy, 2 = pickup, 3 = special behaviour (sphere), 4 = boss, 5 = check collision (player and player shot), 6 = enemy shot
;            7 = respawnable enemy
IS_TYPE_ENEMY = * - 1
          !byte 5     ;player bottom
          !byte 5     ;player shot
          !byte 1     ;larva
          !byte 0     ;explosion
          !byte 1     ;amoeba
          !byte 4     ;boss eye
          !byte 4     ;boss heart
          !byte 6     ;boss shot
          !byte 2     ;health
          !byte 2     ;tongue

TYPE_START_SPRITE_OFFSET_X = * - 1
          !byte 0     ;player bottom
          !byte 0     ;player shot
          !byte 0     ;larva
          !byte 0     ;explosion
          !byte 0     ;amoeba
          !byte 0     ;boss eye
          !byte 0     ;boss heart
          !byte 0     ;boss shot
          !byte 0     ;health
          !byte 0     ;tongue

TYPE_START_SPRITE_OFFSET_Y = * - 1
          !byte 0     ;player bottom
          !byte 0     ;player shot
          !byte 0     ;larva
          !byte 0     ;explosion
          !byte 0     ;amoeba
          !byte 0     ;boss eye
          !byte 0     ;boss heart
          !byte 0     ;boss shot
          !byte 0     ;health
          !byte 0     ;tongue

TYPE_START_HEIGHT_CHARS = * - 1
          !byte 2     ;player bottom
          !byte 1     ;player shot
          !byte 2     ;larva
          !byte 2     ;explosion
          !byte 2     ;amoeba
          !byte 5     ;boss eye
          !byte 5     ;boss heart
          !byte 1     ;boss shot
          !byte 2     ;health
          !byte 5     ;tongue

TYPE_START_WIDTH_CHARS = * - 1
          !byte 1     ;player
          !byte 1     ;player shot
          !byte 1     ;larva
          !byte 1     ;explosion
          !byte 1     ;amoeba
          !byte 3     ;boss eye
          !byte 3     ;boss heart
          !byte 1     ;boss shot
          !byte 2     ;health
          !byte 3     ;tongue

TYPE_START_SPRITE = * - 1
          !byte SPRITE_PLAYER_RIGHT
          !byte SPRITE_PLAYER_SHOT_H
          !byte SPRITE_LARVA
          !byte SPRITE_EXPLOSION
          !byte SPRITE_AMOEBA
          !byte SPRITE_BOSS_EYE
          !byte SPRITE_BOSS_HEART
          !byte SPRITE_BOSS_SHOT
          !byte SPRITE_PICKUP
          !byte SPRITE_TONGUE

TYPE_START_COLOR = * - 1
          !byte $8C   ;player bottom
          !byte $07   ;player shot
          !byte $85   ;larva
          !byte $02   ;explosion
          !byte $83   ;amoeba
          !byte $8f   ;boss eye
          !byte $8a   ;boss heart
          !byte $8d   ;boss shot
          !byte $8a   ;health
          !byte $8a   ;tongue

SF_DOUBLE_V             = $01     ;two sprites on top of each other
SF_DOUBLE_H             = $02     ;two sprites beside each other
SF_START_INVINCIBLE     = $04   ;sprite starts out invincible (enemy shots) = SPRITE_STATE is set to $80
SF_EXPAND_X             = $08
SF_EXPAND_Y             = $10
SF_HIDDEN_WITHOUT_GUN   = $20   ;object is not spawned if player has no gun
;SF_DOUBLE_V, SF_DOUBLE_H, SF_START_INVINCIBLE, SF_EXPAND_X, SF_EXPAND_Y, SF_HIDDEN_WITHOUT_GUN
TYPE_START_SPRITE_FLAGS = * - 1
          !byte 0     ;player
          !byte 0     ;player top
          !byte 0     ;larva
          !byte 0     ;explosion
          !byte 0     ;amoeba
          !byte SF_EXPAND_X | SF_EXPAND_Y   ;boss eye
          !byte SF_EXPAND_X | SF_EXPAND_Y   ;boss heart
          !byte 0     ;boss shot
          !byte 0     ;health
          !byte SF_EXPAND_X | SF_EXPAND_Y   ;tongue

TYPE_START_SPRITE_HP = * - 1
          !byte 3     ;player
          !byte 1     ;player shot
          !byte 1     ;larva
          !byte 0     ;explosion
          !byte 2     ;amoeba
          !byte 150   ;boss eye
          !byte 220   ;boss heart
          !byte 200   ;boss shot
          !byte 0     ;health
          !byte 0     ;tongue

TYPE_START_BEHAVIOR_LO = * - 1
          !byte <BHPlayer
          !byte <BHPlayerShot
          !byte <BHLarva
          !byte <BHExplosion
          !byte <BHAmoeba
          !byte <BHBossEye
          !byte <BHBossHeart
          !byte <BHBossShot
          !byte <BHPickup
          !byte <BHNone

TYPE_START_BEHAVIOR_HI = * - 1
          !byte >BHPlayer
          !byte >BHPlayerShot
          !byte >BHLarva
          !byte >BHExplosion
          !byte >BHAmoeba
          !byte >BHBossEye
          !byte >BHBossHeart
          !byte >BHBossShot
          !byte >BHPickup
          !byte >BHNone

SPRITE_POS_X_EXTEND
          !byte 0

;all these sprite thingies require 8 bytes for copy to work!
SPRITE_POS_X
          !byte 0,0,0,0,0,0,0,0
SPRITE_CHAR_POS_X
          !byte 0,0,0,0,0,0,0,0
SPRITE_CHAR_POS_X_DELTA
          !byte 0,0,0,0,0,0,0,0
SPRITE_CHAR_POS_Y
          !byte 0,0,0,0,0,0,0,0
SPRITE_CHAR_POS_Y_DELTA
          !byte 0,0,0,0,0,0,0,0
SPRITE_POS_Y
          !byte 0,0,0,0,0,0,0,0

;0 = empty/TYPE_NONE
SPRITE_ACTIVE
          !byte 0,0,0,0,0,0,0,0
;0 = right, 1 = left
SPRITE_DIRECTION
          !byte 0,0,0,0,0,0,0,0
SPRITE_DIRECTION_Y
          !byte 0,0,0,0,0,0,0,0
SPRITE_ANIM_POS
          !byte 0,0,0,0,0,0,0,0
SPRITE_ANIM_DELAY
          !byte 0,0,0,0,0,0,0,0
SPRITE_MOVE_POS
          !byte 0,0,0,0,0,0,0,0
SPRITE_MOVE_POS_Y
          !byte 0,0,0,0,0,0,0,0
SPRITE_BASE_IMAGE
          !byte 0,0,0,0,0,0,0,0
SPRITE_STATE
          !byte 0,0,0,0,0,0,0,0
SPRITE_STATE_POS
          !byte 0,0,0,0,0,0,0,0
SPRITE_WIDTH_CHARS
          !byte 0,0,0,0,0,0,0,0
SPRITE_HEIGHT_CHARS
          !byte 0,0,0,0,0,0,0,0
SPRITE_MAIN_INDEX
          !byte 0,0,0,0,0,0,0,0
SPRITE_NUM_PARTS
          !byte 0,0,0,0,0,0,0,0
SPRITE_IMAGE
          !byte 0,0,0,0,0,0,0,0
SPRITE_HP
          !byte 0,0,0,0,0,0,0,0
SPRITE_HITBACK
          !byte 0,0,0,0,0,0,0,0
SPRITE_HITBACK_ORIG_COLOR
          !byte 0,0,0,0,0,0,0,0
;how many times has a shot hit this enemy
SPRITE_SHOT_HIT_COUNT
          !fill 8
SPRITE_LIFETIME
          !fill 8

;SPRITE_SPEED
;          !fill 8

;bresenham members
SPRITE_MOVE_DX
          !fill NUM_SPRITES,0
SPRITE_MOVE_DY
          !fill NUM_SPRITES,0
SPRITE_FRACTION
          !fill NUM_SPRITES,0

SPRITE_BEHAVIOUR_LO
          !fill 8
SPRITE_BEHAVIOUR_HI
          !fill 8


;bresenham members
SPRITE_MOVE_DX_LO
          !fill 8
SPRITE_MOVE_DX_HI
          !fill 8
SPRITE_MOVE_DY_LO
          !fill 8
SPRITE_MOVE_DY_HI
          !fill 8
;$ff = left, 0 = stay, 1 = right
SPRITE_STEP_X
          !fill 8
;$ff = up, 0 = stay, 1 = down
SPRITE_STEP_Y
          !fill 8
;SPRITE_FRACTION_LO
;          !fill 8
;SPRITE_FRACTION_HI
;          !fill 8

;MOVE_TARGET_X_LO
;          !fill 8
;MOVE_TARGET_X_HI
;          !fill 8
;MOVE_TARGET_Y
;LAST_SPRITE_ARRAY
;          !fill 8

BIT_TABLE
          !byte 1,2,4,8,16,32,64,128

SPEED_TABLE
          !byte 0,0,0,0,0,0,0,0
          !byte 0,0,0,0,0,0,0,1
          !byte 0,0,0,1,0,0,0,1
          !byte 0,1,0,0,1,0,0,1
          !byte 1,0,1,0,1,0,1,0
          !byte 1,1,0,1,1,0,1,0
          !byte 1,1,1,0,1,1,1,0
          !byte 1,1,1,1,1,1,1,0
          !byte 1,1,1,1,1,1,1,1

SPEED_TABLE_POS
          !byte 0

PLAYER_LAST_MOVED_DIR
          !byte 0