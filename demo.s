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

enable_rendering:
  lda #%10000000	; Enable NMI
  sta $2000
  lda #%00010000	; Enable Sprites
  sta $2001

forever:
  jmp forever

nmi:  ; Non Maskable Interrupt

  lda #$00 	;
  sta $2003  ;  OAM low byte (00)
  lda #$02
  sta $4014 ; OAM high byte (02) / transfer OAM DMA (direct memory access)
;@loop:  lda hello, x
;  sta $2004
;  inx
;  cpx #$1c
;  bne @loop;


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
DrawSprite:
  lda #$10
  sta $0200 ; y
  lda #$00
  sta $0201 ; index
  lda #$00
  sta $0202 ; attributes
  lda #$08
  sta $0203 ; x
  ;sprite2
  lda #$10
  sta $0204
  lda #$01
  sta $0205 ; index
  lda #$00
  sta $0206
  lda #$10
  sta $0207
  ;sprite3
  lda #$18
  sta $0208
  lda #$02
  sta $0209 ; index
  lda #$00
  sta $020a
  lda #$08
  sta $020b
  ;sprite4
  lda #$18
  sta $020c
  lda #$03
  sta $020d ; index
  lda #$00
  sta $020e
  lda #$10
  sta $020f
  ;sprite5
  lda #$20
  sta $0210
  lda #$04
  sta $0211 ; index
  lda #$01
  sta $0212
  lda #$08
  sta $0213
  ;sprite6
  lda #$20
  sta $0214
  lda #$05
  sta $0215
  lda #$01
  sta $0216
  lda #$10
  sta $0217

  rti

hello:
  .byte $00, $00, $00, $00 	; Why do I need these here?
  .byte $00, $00, $00, $00
  .byte $6c, $00, $00, $6c
  .byte $6c, $01, $00, $76
  .byte $6c, $02, $00, $80
  .byte $6c, $02, $00, $8A
  .byte $6c, $03, $00, $94

palettes:
  ; Background Palette
  .byte $0f, $16, $36, $0c
  .byte $0f, $16, $36, $0c
  .byte $0f, $16, $36, $0c
  .byte $0f, $16, $36, $0c

  ; Sprite Palette
  .byte $00, $0f, $1a, $36
  .byte $00, $1a, $0f, $11
  .byte $0f, $15, $26, $20
  .byte $0f, $15, $26, $20

; Character memory
.segment "CHARS"
  ; .byte %11000011	; H (00)
  ; .byte %11000011
  ; .byte %11000011
  ; .byte %11111111
  ; .byte %11111111
  ; .byte %11000011
  ; .byte %11000011
  ; .byte %11000011
  ; .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; .byte %11111111	; E (01)
  ; .byte %11111111
  ; .byte %11000000
  ; .byte %11111100
  ; .byte %11111100
  ; .byte %11000000
  ; .byte %11111111
  ; .byte %11111111
  ; .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; .byte %11000000	; L (02)
  ; .byte %11000000
  ; .byte %11000000
  ; .byte %11000000
  ; .byte %11000000
  ; .byte %11000000
  ; .byte %11111111
  ; .byte %11111111
  ; .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; .byte %01111110	; O (03)
  ; .byte %11100111
  ; .byte %11000011
  ; .byte %11000011
  ; .byte %11000011
  ; .byte %11000011
  ; .byte %11100111
  ; .byte %01111110
  ; .byte $00, $00, $00, $00, $00, $00, $00, $00

  .incbin "survival.chr"
