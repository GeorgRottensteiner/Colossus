MUSIC_PLAY_SFX          = MUSIC_PLAYER + 6


;y = sfx to play
!lzone PlaySoundEffect
          tya
          tax

          lda SFX_TABLE_LO,x
          ldy SFX_TABLE_HI,x
          ;channel 0, 7, 14
          ldx #$0e
          jmp MUSIC_PLAY_SFX



SFX_BONUS_BLIP  = 0
SFX_POWER_UP    = 1
SFX_SHOOT       = 2
SFX_HURT        = 3
SFX_PICK_PLUS   = 4
SFX_EXPLODE     = 5

SFX_TABLE_LO
          !byte <SFX_DATA_BONUS_BLIP
          !byte <SFX_DATA_POWER_UP
          !byte <SFX_DATA_SHOOT
          !byte <SFX_DATA_HURT
          !byte <SFX_DATA_PICK_PLUS
          !byte <SFX_DATA_EXPLODE

SFX_TABLE_HI
          !byte >SFX_DATA_BONUS_BLIP
          !byte >SFX_DATA_POWER_UP
          !byte >SFX_DATA_SHOOT
          !byte >SFX_DATA_HURT
          !byte >SFX_DATA_PICK_PLUS
          !byte >SFX_DATA_EXPLODE


SFX_DATA_BONUS_BLIP
                !bin "Colossus_-_Simple_Blip.ins.bin"
SFX_DATA_POWER_UP
                !bin "Colossus_-_Health_Pick_Up.ins.bin"
SFX_DATA_SHOOT
                !bin "Colossus_-_Lazer.ins.bin"
SFX_DATA_HURT
                !bin "Colossus_-_Hurt_Effect.ins.bin"
SFX_DATA_PICK_PLUS
                !bin "Colossus_-_Pickup_Spawn.ins.bin"
SFX_DATA_EXPLODE
                !bin "Colossus_-_Explode.ins.bin"
