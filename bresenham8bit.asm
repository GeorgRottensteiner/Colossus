;PARAM3 - number of steps
;moves object in X
;returns 0 if blocked, 1 if moved
!zone DeltaMove
DeltaMove
          lda SPRITE_MOVE_DX,x
          cmp SPRITE_MOVE_DY,x
          bcc .DYGreaterThanDX

.loop1
          ;loop
          lda SPRITE_FRACTION,x
          bmi +

          ;slYStart += stepy;
          ;fraction -= dx;
          lda SPRITE_STEP_Y,x
          beq .NoYStep
          cmp #$ff
          beq .Up

          jsr ObjectMoveDownBlocking
          jmp .MovedY

.Up
          jsr ObjectMoveUpBlocking
.MovedY
          beq .Blocked
          ;lda SPRITE_POS_Y,x
          ;clc
          ;adc SPRITE_STEP_Y,x
          ;sta SPRITE_POS_Y,x

.NoYStep
          lda SPRITE_FRACTION,x
          sec
          sbc SPRITE_MOVE_DX,x
          sta SPRITE_FRACTION,x
+

          ;slXStart += stepx;
          ;fraction += dy;
          lda SPRITE_STEP_X,x
          beq .NoXStep
          cmp #$ff
          beq .Left

          jsr ObjectMoveRightBlocking
          jmp .MovedX

.Left
          jsr ObjectMoveLeftBlocking
.MovedX
          beq .Blocked
          ;lda SPRITE_POS_X,x
          ;clc
          ;adc SPRITE_STEP_X,x
          ;sta SPRITE_POS_X,x

.NoXStep
          lda SPRITE_FRACTION,x
          clc
          adc SPRITE_MOVE_DY,x
          sta SPRITE_FRACTION,x

          ;next dot
          dec PARAM3
          bne .loop1

          lda #1
          rts

.DYGreaterThanDX

.loop1b
          ;loop
          lda SPRITE_FRACTION,x
          bmi +

          ;fraction > 0
          ;slXStart += stepx;
          lda SPRITE_STEP_X,x
          beq .NoXStep2
          cmp #$ff
          beq .Left2

          jsr ObjectMoveRightBlocking
          jmp .MovedX2

.Left2
          jsr ObjectMoveLeftBlocking
.MovedX2
          beq .Blocked
          ;lda SPRITE_POS_X,x
          ;clc
          ;adc SPRITE_STEP_X,x
          ;sta SPRITE_POS_X,x

.NoXStep2
          ;fraction -= dy;
          lda SPRITE_FRACTION,x
          sec
          sbc SPRITE_MOVE_DY,x
          sta SPRITE_FRACTION,x
+

          ;slYStart += stepy;
          lda SPRITE_STEP_Y,x
          beq .NoYStep2
          cmp #$ff
          beq .Up2

          jsr ObjectMoveDownBlocking
          jmp .MovedY2

.Up2
          jsr ObjectMoveUpBlocking
.MovedY2
          beq .Blocked
          ;lda SPRITE_POS_Y,x
          ;clc
          ;adc SPRITE_STEP_Y,x
          ;sta SPRITE_POS_Y,x

.NoYStep2
          ;fraction += dx;
          lda SPRITE_FRACTION,x
          clc
          adc SPRITE_MOVE_DX,x
          sta SPRITE_FRACTION,x

          ;next dot
          dec PARAM3
          bne .loop1b

          lda #1
          rts

.Blocked
          lda #0
          rts



;von PARAM1,PARAM2 nach PARAM3,PARAM4
;sets values in object index PARAM5
!lzone CalcDelta
          ldx PARAM5

          lda #0
          sta SPRITE_FRACTION,x

          lda PARAM3
          cmp PARAM1
          beq .NoXStep
          bcs .XPos

          lda #0
          sta PARAM5

          lda PARAM1
          sec
          sbc PARAM3
          asl
          sta SPRITE_MOVE_DX,x

          lda #$ff
          sta SPRITE_STEP_X,x
          jmp +

.NoXStep
          lda #0
          sta SPRITE_STEP_X,x
          sta SPRITE_MOVE_DX,x
          jmp +

.XPos
          sec
          sbc PARAM1
          asl
          sta SPRITE_MOVE_DX,x
          lda #1
          sta PARAM5
          sta SPRITE_STEP_X,x

+
          lda PARAM4
          cmp PARAM2
          beq .NoYStep
          bcs .YPos

          lda #0
          sta PARAM6

          lda PARAM2
          sec
          sbc PARAM4
          asl
          sta SPRITE_MOVE_DY,x

          lda #$ff
          sta SPRITE_STEP_Y,x
          jmp +

.NoYStep
          lda #0
          sta SPRITE_STEP_Y,x
          sta SPRITE_MOVE_DY,x
          jmp +

.YPos
          sec
          sbc PARAM2
          asl
          sta SPRITE_MOVE_DY,x
          lda #1
          sta PARAM6
          sta SPRITE_STEP_Y,x
+

          ;prepare fraction
          lda SPRITE_MOVE_DX,x
          cmp SPRITE_MOVE_DY,x
          bcc .DYGreaterThanDX

          ;int fraction = dy - ( dx >> 1 );
          lda SPRITE_MOVE_DX,x
          lsr
          sta PARAM1

          lda SPRITE_MOVE_DY,x
          sec
          sbc PARAM1
          ;fraction
          sta SPRITE_FRACTION,x
          rts


.DYGreaterThanDX
          ;int fraction = dx - ( dy >> 1 );
          lda SPRITE_MOVE_DY,x
          lsr
          sta PARAM1

          lda SPRITE_MOVE_DX,x
          sec
          sbc PARAM1
          ;fraction
          sta SPRITE_FRACTION,x
          rts
