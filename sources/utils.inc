SECTION "Utils", 		ROM0

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

MACRO LOAD_16_BITS ; args: dest address, value
    ld hl, \1
    ld a, low(\2)
    ld [hli], a
    ld a, high(\2)
    ld [hl], a
ENDM

MACRO COPY_16_BITS ; args : source addr, dest addr
    ld hl, \1 
    ld a, [hl]
    ld [\2], a
    inc hl
    ld a, [hl]
    ld hl, \2
    inc hl
    ld [hl], a
ENDM

; Divide a by b
; Result (quotient) is stored into d
Divide::
    ld d, 0
.loop
    cp b
    jr c, .done
    sub a, b
    inc d
    jr .loop
.done
    ret

MACRO SetupFunctionStackVariables
    add sp, -_NARG ; make space for arguments
    FOR N, 1, _NARG+1
        DEF \<N> EQU N-1
    ENDR
ENDM

MACRO SetbackFunctionStackVariables
    add sp, _NARG
ENDM

MACRO SetbackFunctionStackVariablesAndNames
    SetbackFunctionStackVariables \#
    FOR N, 1, _NARG+1
        PURGE \<N>
    ENDR
ENDM

MACRO ldr16_r16 
    ld \1 , \3
    ld \2 , \4
ENDM

; Multiply hl by arg1 (8 bits)
; Invalidate a, bc, d
MACRO Multiply 
IF \1 == 0
    ld hl, 0
ELIF \1 == 1
    ; nothing to do
ELSE
    ld a, h
    or 0 ; set the flags
    jp nz, .do_multiply\@
    ld a, l
    or 0 ; set the flags
    jp z, .end_multiply\@ ; HL is zero, nothing to do


.do_multiply\@
    ld d, \1
    dec d

    ; ld bc, hl
    ld b, h
    ld c, l
    .loop\@
        add hl, bc
        dec d
        jr nz, .loop\@

.end_multiply\@
ENDC
ENDM