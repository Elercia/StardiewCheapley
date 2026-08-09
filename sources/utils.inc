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

; Clear DE bytes from HL
MemClear:
.loop:
    ld [hl], 0 
    inc hl
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

MACRO CLEAR_16_BITS
    ld hl, \1 
    ld [hl], 0
    inc hl
    ld [hl], 0
ENDM


MACRO COPY_16_BITS ; arg : source addr, dest addr
    ld hl, \1 
    ld a, [hl]
    ld [\2], a
    inc hl
    ld a, [hl]
    ld hl, \2
    inc hl
    ld [hl], a
ENDM


WaitVBlank:
    ld hl, wVBlankInterrupt  ; hl = pointer to wVBlankInterrupt
    xor a
.wait
    halt ; suspend CPU - wait for ANY enabled interrupt
    cp a, [hl] ; is the wVBlankInterrupt still zero?
    jr z, .wait ; keep waiting if zero
    ld [hl], a ; set the wVBlankInterrupt back to zero

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

; Turn on the lcd for copy inside vram operations
; Only unset the bit needed
; invalidates a
TurnOnLCD:
    ld a, [rLCDC]
    set B_LCDC_ENABLE, a
    ld [rLCDC], a
    ret
