INCLUDE "hardware.inc"

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

SECTION "Nintendo logo", 	ROM0[$104]
	NINTENDO_LOGO

SECTION "Title", 			ROM0[$134] ; 16 chars long
	db "StardiewCheaple"
	ds $0143-@, 0

SECTION "Compatibility mode", 	ROM0[$143]
	db CART_COMPATIBLE_DMG

SECTION "Licensee code (new)", 	ROM0[$144]
	ds $145 - @, 0

SECTION "SGB flag", 		ROM0[$146]
	db CART_INDICATOR_GB

SECTION "Cartridge type", 	ROM0[$147] ; TODO To define
	db CART_ROM

SECTION "ROM size", 		ROM0[$148]
	db CART_ROM_32KB

SECTION "RAM size", 		ROM0[$149] 
	db CART_SRAM_NONE

SECTION "Destination", 		ROM0[$014A] 
	db CART_DEST_NON_JAPANESE

SECTION "Licensee code (old)", 	ROM0[$014B] 
	ds $014C - @, 0

Section "CodeStart", 		ROM0[$150]

EntryPoint:
	; Shut down audio circuitry
	ld a, 0
	ld [rNR52], a

	; Disable interupts
	di

	halt
