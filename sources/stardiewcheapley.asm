INCLUDE "hardware.inc"
INCLUDE "utils.inc"

; Interupts 
SECTION "Vblank", 			ROM0[INT_HANDLER_VBLANK]
	reti
SECTION "LCDC", 			ROM0[INT_HANDLER_STAT]
	reti
SECTION "Timer_Overflow", 	ROM0[INT_HANDLER_TIMER]
	reti
SECTION "Serial", 			ROM0[INT_HANDLER_SERIAL]
	reti
SECTION "Joypad", 			ROM0[INT_HANDLER_JOYPAD]
	reti

; 0100-014F — Cartridge header
SECTION "Header", 			ROM0[$100]
	nop
	jp EntryPoint

SECTION "Title", 			ROM0[$134] ; 16 chars long
	db "StardiewCheaple"
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

Section "CodeStart", 		ROM0[$150]

INCLUDE "gfx/gfx.asm" 

EntryPoint:
	xor a

	; Shut down audio circuitry
	ld [rNR52], a
	
	ld [rSCX], a
	ld [rSCY], a

	; Disable interupts
	di

	; Wait for vblank and disable the LCD
	call TurnOffLCD

	; Set the LCD control register
	ld a, ( LCDC_OFF | LCDC_WIN_9800 | LCDC_WIN_ON | LCDC_BLOCK01 | LCDC_BG_9800 | LCDC_OBJ_8 | LCDC_OBJ_ON | LCDC_BG_ON )
	ld [rLCDC], a

	; Set the palette
	ld a, %11100100
	ld [rBGP], a

	ld de, mapVillage_tile_data_size
	ld bc, mapVillage_tile_data
	ld hl, $8000
	call Memcopy

	ld de, mapVillage_tile_map_size
	ld bc, mapVillage_map_data
	ld hl, $9800
	call Memcopy

	ld de, AllVillagers_tile_data_size
	ld bc, AllVillagers_tile_data_size
	ld hl, $8000 + mapVillage_tile_data
	call Memcopy

	call TurnOnLCD

.loop
	jr .loop
