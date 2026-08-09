SECTION "Joypad Variables", WRAM0
wJoypadCurrent:: db ; TODO Move to another file "input.asm" 
wJoypadPrevious:: db

SECTION "Player Variables", WRAM0
wPlayerPositionX:: dw ; 2 bytes for pixel position in world
wPlayerPositionY:: dw
wPlayerDirection:: db ; 1 byte for direction (only uses 2 bits)

DEF PLAYER_FACE_DOWN EQU 0
DEF PLAYER_FACE_UP EQU 1 
DEF PLAYER_FACE_RIGHT EQU 2
DEF PLAYER_FACE_LEFT EQU 3


SECTION "Player Code", ROM0

Gameplay_Init:
    call Gameplay_InitMap
    call Gameplay_InitPlayer

    ret

Gameplay_InitMap:

    ; Copy tile data (village tiles & player tiles)
    MEMCOPY village_tileset, TILE_DATA_START_ADDR, village_tileset_size
	MEMCOPY character_tileset, TILE_DATA_START_ADDR + village_tileset_size, character_tileset_size

    MEMCOPY map_village_tilemap, TILE_MAP_START_ADDR, map_village_tilemap

    ret

Gameplay_InitPlayer:
    xor a

    ld [wJoypadCurrent], a
    ld [wJoypadPrevious], a

    ld [wPlayerPositionX], a
    ld [wPlayerPositionX+1], a

    ld [wPlayerPositionY], a
    ld [wPlayerPositionY+1], a

    ld [wPlayerDirection], a

    ret

Gameplay_Update:
read_inputs:
    ; Get joypad inputs
    ld a, JOYP_GET_CTRL_PAD ; Load P1F_GET_DPAD flag into A to select reading the buttons
    ldh [rJOYP], a

    REPT 4 ; Repeat to stabilize input reading after select
    ldh a, [rJOYP] ; Read the joypad inputs
    ENDR

    ld b, a ; Save the read data into b

    ; Update old inputs with current ones
    ld a, [wJoypadCurrent]
    ld [wJoypadPrevious], a

    ; Update current inputs variable
    ld a, b
    ld [wJoypadCurrent], a
    

.cleanup_input_read
    ld a, JOYP_GET_NONE ; Load JOYP_GET_NONE flag into A to disable input reading
    ldh [rJOYP], a
    
UpdatePlayerDirection:
.check_right
    ld a, [wJoypadCurrent]
    and $01 ; Select right
    jr z, .check_left
    ld a, PLAYER_FACE_RIGHT
    ld [wPlayerDirection], a
    jr .end
.check_left
    ld a, [wJoypadCurrent]
    and $02 ; Select left
    jr z, .check_up
    ld a, PLAYER_FACE_LEFT
    ld [wPlayerDirection], a
    jr .end
.check_up
    ld a, [wJoypadCurrent]
    and $03 ; Select up
    jr z, .check_down
    ld a, PLAYER_FACE_UP
    ld [wPlayerDirection], a
    jr .end
.check_down
    ld a, [wJoypadCurrent]
    and $04 ; Select down
    jr z, .end
    ld a, PLAYER_FACE_DOWN
    ld [wPlayerDirection], a
    jr .end

.end
    ret