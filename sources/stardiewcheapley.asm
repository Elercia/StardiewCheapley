INCLUDE "hardware.inc"
INCLUDE "utils.inc"

; 0100-014F — Cartridge header
SECTION "Header", 			ROM0[$100]
	nop
	jp EntryPoint

SECTION "Nintendo logo", 	ROM0[$104]
	ds $134 - @, 0

SECTION "Title", 			ROM0[$134] ; 16 chars long
	db "StardewCheapley"
	ds $0143-@, 0

SECTION "Compatibility mode", 	ROM0[$143]
	db $00

SECTION "Licensee code (new)", 	ROM0[$144]
	ds $145 - @, 0

SECTION "SGB flag", 		ROM0[$146]
	db $00

SECTION "Cartridge type", 	ROM0[$147] ; TODO To define
	db $00

SECTION "ROM size", 		ROM0[$148]
	db $00

SECTION "RAM size", 		ROM0[$149] 
	db $00

SECTION "Destination", 		ROM0[$014A] 
	db $01

SECTION "Licensee code (old)", 	ROM0[$014B] 
	ds $014C - @, 0

SECTION "Checksums", 	ROM0[$014C] 
	ds $014FC- @, 0

SECTION "CodeStart", 		ROM0[$150]

INCLUDE "gfx/gfx.asm"
INCLUDE "gameplay.asm"

; OAM DMA Routine
; Reserve into HRAM some memory space to copy the code of CopyDMARoutine

SECTION "Shadow OAM", WRAM0,ALIGN[8]
wShadowOAM:
  ds 4 * 40 ;

; ROM Storage of the routine (and copy utility function)
SECTION "OAM DMA routine", ROM0
CopyDMARoutine:
  ld  hl, CopyShadowOAMToOAM_ROM
  ld  b, CopyShadowOAMToOAM_ROM.end - CopyShadowOAMToOAM_ROM ; Number of bytes to copy
  ld  c, low(CopyShadowOAMToOAM) ; Low byte of the destination address
.copy
  ld  a, [hli]
  ldh [c], a
  inc c
  dec b
  jr  nz, .copy
  ret

CopyShadowOAMToOAM_ROM:
  ldh [rDMA], a
  
  ld  a, 40
.wait
  dec a
  jr  nz, .wait
  ret
.end

SECTION "OAM DMA", HRAM

CopyShadowOAMToOAM::
  ds CopyShadowOAMToOAM_ROM.end - CopyShadowOAMToOAM_ROM ; Reserve space to copy the routine to

SECTION "EntryPoint section", ROM0
EntryPoint:
	xor a

	; Shut down audio circuitry
	ld [rAUDENA], a
	
	ld [rSCX], a
	ld [rSCY], a

	ld [rWX], a
	ld [rWY], a

	; Enable interupts, only VBlanks tho
	ei
	ld hl, rIE
	ld [hl], $01

	; Wait for vblank and disable the LCD
	call TurnOffLCD

	; Setup OAM DMA routine
	; clear shadow OAM
	; clear OAM (using DMA)
	call CopyDMARoutine
	ld de, OAM_SIZE
	ld hl, wShadowOAM
	call MemClear

	ld  a, high(wShadowOAM)
 	call CopyShadowOAMToOAM

	; Disable interupts
	di

	; Set the LCD control register
	ld a, ( LCDC_OFF | LCDC_WIN_9800 | LCDC_WIN_OFF | LCDC_BLOCK01 | LCDC_BG_9800 | LCDC_OBJ_8 | LCDC_OBJ_ON | LCDC_BG_ON )
	ld [rLCDC], a

	; Set the palette
	ld a, %11100100
	ld [rBGP], a

	call Gameplay_Init

	xor a
    ld [wVBlankInterrupt], a
	call TurnOnLCD

	ei ; Enable interupts, used for Vblanks

.loop
	call Gameplay_Update

	call WaitVBlank
	ld  a, high(wShadowOAM)
 	call CopyShadowOAMToOAM

	ld a, [wShadowScreenPositionX]
	ld [rSCX], a

	ld a, [wShadowScreenPositionY]
	ld [rSCY], a

	jr .loop
