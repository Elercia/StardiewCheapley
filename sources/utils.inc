Section "Utils", 		ROM0

; Copy DE bytes from BC to HL
Memcopy:
.loop:
    ld a, [bc]
    ld [hl], a 
    inc hl
    inc bc
    dec de ; DEC is not setting ant flags
    ld a, e ; So we need to check if any e or d is 0 
	or a, d
    jp nz, .loop
    ret

WaitVBlank:
    ld a, [rLY]
    cp a, SCRN_Y
    jp c, WaitVBlank
    ret

; Turn off the lcd for copy inside vram operations
; Only unset the bit needed
; invalidates a
TurnOffLCD:
    call WaitVBlank
    ld a, [rLCDC]
    res LCDCB_ON, a
	ld [rLCDC], a
    ret

; Turn off the lcd for copy inside vram operations
; Only unset the bit needed
; invalidates aÒ
TurnOnLCD:
    ld a, [rLCDC]
    set LCDCB_ON, a
    ld [rLCDC], a
    ret
