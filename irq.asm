BOTTOM_BORDER_RASTER_POS = 242

!lzone InitGameIRQ

          ;wait for exact frame so we don't end up on the wrong
          ;side of the raster
          jsr WaitFrame
          sei

          lda #$35 ; make sure that IO regs at $dxxx
          sta PROCESSOR_PORT ;are visible

          lda #$7f ;disable cia #1 generating timer irqs
          sta CIA1.IRQ_CONTROL  ;which are used by the system to flash cursor, etc

          lda #$01 ;tell VIC we want him generate raster irqs
          sta VIC.IRQ_MASK

          lda #BOTTOM_BORDER_RASTER_POS ;nr of rasterline we want our irq occur at
          sta VIC.RASTER_POS

          ;MSB of d011 is the MSB of the requested rasterline
          ;as rastercounter goes from 0-312
          lda VIC.CONTROL_1
          and #$7f
          sta VIC.CONTROL_1

          ;set irq vector to point to our routine
          lda #<IrqSetGame
          sta $0314
          lda #>IrqSetGame
          sta $0315

          ;nr of rasterline we want our irq occur at
          lda #$01
          sta VIC.RASTER_POS

          ;acknowledge any pending cia timer interrupts
          ;this is just so we're 100% safe
          lda CIA1.IRQ_CONTROL
          lda CIA2.NMI_CONTROL

          lda #$37
          sta PROCESSOR_PORT

          cli
          rts



!lzone IrqSetGame

          ;acknowledge VIC irq
          lda VIC.IRQ_REQUEST
          sta VIC.IRQ_REQUEST

          ;install next state
          lda #<IrqSetPanel
          sta $0314
          lda #>IrqSetPanel
          sta $0315

          ;Enable char/bitmap multicolour
          lda #$18
          sta VIC.CONTROL_2

          lda #$0b
          ora SCREEN_OFF
          sta VIC.CONTROL_1

          lda CURRENT_BG
          sta VIC.BACKGROUND_COLOR

          ;nr of rasterline we want our irq occur at
          lda #BOTTOM_BORDER_RASTER_POS
          sta VIC.RASTER_POS

          lda PROCESSOR_PORT
          pha

          lda #$35
          sta PROCESSOR_PORT

          ldx #0
-
          lda SPRITE_IMAGE,x
          sta SPRITE_POINTER_BASE,x

          inx
          cpx #8
          bne -

          pla
          sta PROCESSOR_PORT

          lda JOYSTICK_PORT_II
          sta JOY_VALUE

          and #$1f
          ora JOY_VALUE_RELEASED
          sta JOY_VALUE_RELEASED

          jsr MUSIC_PLAYER + 3
          ;jsr SFXUpdate

          jmp IRQ_RETURN_KERNAL



!lzone IrqSetPanel
          ;acknowledge VIC irq

          lda PROCESSOR_PORT
          pha

          lda #$35
          sta PROCESSOR_PORT

          ldx #$1b
          lda #$08
          ldy #0


          nop
          nop
          nop
          nop
          nop

          ;na. set panel charset
          sty VIC.BACKGROUND_COLOR
          sta VIC.CONTROL_2
          stx VIC.CONTROL_1

          lda VIC.IRQ_REQUEST
          sta VIC.IRQ_REQUEST

          ;install top part
          lda #<IrqSetGame
          sta $0314
          lda #>IrqSetGame
          sta $0315


          ;nr of rasterline we want our irq occur at
          lda #$01
          sta VIC.RASTER_POS

          pla
          sta PROCESSOR_PORT

          jmp IRQ_RETURN_KERNAL
