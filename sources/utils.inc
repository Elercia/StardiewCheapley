Section "Utils", 		ROM0

DEF TILE_DATA_START_ADDR EQU TILEBLOCK0
DEF TILE_MAP_START_ADDR EQU TILEMAP0

; Copy DE bytes from BC to HL
Memcopy:
.loop:
    ld a, [bc]
    ld [hl], a 
    inc hl
    inc bc
    dec de ; DEC is not setting any flags
    ld a, e ; So we need to check if any e or d is 0 
	or a, d
    jp nz, .loop
    ret

MACRO MEMCOPY
    ld de, \3
	ld bc, \1
	ld hl, \2
	call Memcopy
ENDM

WaitVBlank:
    ld a, [rLY]
    cp a, SCREEN_HEIGHT_PX
    jp c, WaitVBlank
    ret

; Turn off the lcd for copy inside vram operations
; Only unset the bit needed
; invalidates a
TurnOffLCD:
    call WaitVBlank
    ld a, [rLCDC]
    res B_LCDC_ENABLE, a
	ld [rLCDC], a
    ret

; Turn off the lcd for copy inside vram operations
; Only unset the bit needed
; invalidates aÒ
TurnOnLCD:
    ld a, [rLCDC]
    set B_LCDC_ENABLE, a
    ld [rLCDC], a
    ret
