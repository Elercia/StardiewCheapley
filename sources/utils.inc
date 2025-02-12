Section "Utils", 		ROM0

; Copy d bytes from BC to HL
Memcopy:
.loop:
    ld a, [bc]
    ld [hl], a 
    inc hl
    inc bc
    dec d
    jp nz, .loop
