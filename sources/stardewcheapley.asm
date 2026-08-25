INCLUDE "gameboy_defines.inc"
INCLUDE "utils.inc"

INCLUDE "header.asm"

INCLUDE "gfx/gfx.asm"
INCLUDE "hardware.asm"
INCLUDE "gameplay.asm"
INCLUDE "input.asm"

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
	ld a, ( LCDC_OFF | LCDC_WIN_9C00 | LCDC_WIN_OFF | LCDC_BLOCK01 | LCDC_BG_9800 | LCDC_OBJ_8 | LCDC_OBJ_ON | LCDC_BG_ON )
	ld [rLCDC], a

	; Set the palettes
	ld a, %11100100
	ld [rBGP], a

	ld a, %11100100
	ld [rOBP0], a
	
	ld a, %11100100
	ld [rOBP1], a

	call Input_Init
	call Gameplay_Init

	xor a
    ld [wVBlankInterrupt], a
	call TurnOnLCD

	ei ; Enable interupts, used for Vblanks

.loop
	call Input_Update
	call Gameplay_Update

	call WaitVBlank
	
	di
	ld  a, high(wShadowOAM)
 	call CopyShadowOAMToOAM
	ei 

	ld a, [wShadowScreenPositionX]
	ld [rSCX], a

	ld a, [wShadowScreenPositionY]
	ld [rSCY], a

	jr .loop
