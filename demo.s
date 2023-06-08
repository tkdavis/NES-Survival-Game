.segment "HEADER"
  ; .byte "NES", $1A      ; iNES header identifier
  .byte $4E, $45, $53, $1A
  .byte 2               ; 2x 16KB PRG code
  .byte 1               ; 1x  8KB CHR data
  .byte $01, $00        ; mapper 0, vertical mirroring

.segment "VECTORS"
  ;; When an NMI happens (once per frame if enabled) the label nmi:
  .addr nmi
  ;; When the processor first turns on or is reset, it will jump to the label reset:
  .addr reset
  ;; External interrupt IRQ (unused)
  .addr 0

; "nes" linker config requires a STARTUP section, even if it's empty
.segment "STARTUP"

.segment "ZEROPAGE"
player_x: .res 1

; Main code segment for the program
.segment "CODE"

reset:
  sei		; disable IRQs
  cld		; disable decimal mode
  ldx #$40
  stx $4017	; disable APU frame IRQ
  ldx #$ff 	; Set up stack
  txs		;  .
  inx		; now X = 0
  stx $2000	; disable NMI
  stx $2001 	; disable rendering
  stx $4010 	; disable DMC IRQs

;; first wait for vblank to make sure PPU is ready
vblankwait1:
  bit $2002
  bpl vblankwait1

clear_memory:
  lda #$00
  sta $0000, x
  sta $0100, x
  sta $0200, x
  sta $0300, x
  sta $0400, x
  sta $0500, x
  sta $0600, x
  sta $0700, x
  inx
  bne clear_memory

;; second wait for vblank, PPU is ready after this
vblankwait2:
  bit $2002
  bpl vblankwait2

main:
load_palettes:
  lda $2002
  lda #$3f
  sta $2006
  lda #$00
  sta $2006
  ldx #$00
@loop:
  lda palettes, x
  sta $2007
  inx
  cpx #$20
  bne @loop

  ldx #$00
load_sprites:
  lda sprites, x
  sta $0200, x
  inx
  cpx #$18
  bne load_sprites

enable_rendering:
  lda #%10000000	; Enable NMI
  sta $2000
  lda #%00010000	; Enable Sprites
  sta $2001

  lda #0203  ; load x position of player
  sta player_x

forever:
  jmp forever

nmi:  ; Non Maskable Interrupt

  lda #$00 	;
  sta $2003  ;  OAM low byte (00)
  lda #$02
  sta $4014 ; OAM high byte (02) / transfer OAM DMA (direct memory access)

  ; store left sprite x values.
  ; copy to x register, clear carry, add 8, store right sprites
  ; increment x register to move character right 1px
  lda player_x
  sta $0203
  sta $020b
  sta $0213
  tax
  clc
  adc #$08
  sta $0207
  sta $020f
  sta $0217
  inx
  stx player_x

  ; lda #$3f  ; high byte? address 3f00 prevents palette corruption on NTSC ppu
  ; sta $2006  ; PPUADDR (write twice)
  ; lda #$00  ; low byte?
  ; sta $2006
  ; lda #$12 ; Blue color
  ; sta $2007 ; PPUDATA write (turns screen blue in this case)
  ;  $0200 - y coord
  ;  $0201 - tile index of sprite from pattern table
  ;  $0202 - attribute table (look up binary values for vflip, palette, etc)
  ;  $0203 - x coord

  rti

sprites:
        ;y   tile attr x
  .byte $10, $00, $00, $08
  .byte $10, $01, $00, $10
  .byte $18, $02, $00, $08
  .byte $18, $03, $00, $10
  .byte $20, $04, $00, $08
  .byte $20, $05, $00, $10

palettes:
  ; Background Palette
  .byte $0f, $16, $36, $0c
  .byte $0f, $16, $36, $0c
  .byte $0f, $16, $36, $0c
  .byte $0f, $16, $36, $0c

  ; Sprite Palette
  .byte $0f, $0f, $1a, $27
  .byte $0f, $1a, $0f, $11
  .byte $0f, $15, $26, $20
  .byte $0f, $15, $26, $20

; Character memory
.segment "CHARS"

  .incbin "survival.chr"
