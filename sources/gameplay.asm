SECTION "Joypad Variables", WRAM0
wJoypadCurrent:: db ; TODO Move to another file "input.asm" 
wJoypadPrevious:: db

SECTION "Interrupts Variables", WRAM0
wVBlankInterrupt:: db

SECTION "Player Variables", WRAM0
; 2 bytes for pixel position in world. 
; Have it as u16  is not useful right now but will be necessary when we will be using streaming
;   And its challenging
wPlayerPositionX:: dw 
wPlayerPositionY:: dw
wPlayerDirection:: db ; 1 byte for direction (only uses 2 bits)

; Shadowing of rSCX & rSCY to update only in vblanks (to avoid tearing)
wShadowScreenPositionX:: db
wShadowScreenPositionY:: db

DEF PLAYER_SPEED EQU 1

DEF PLAYER_FACE_LEFT EQU 0
DEF PLAYER_FACE_RIGHT EQU 1
DEF PLAYER_FACE_DOWN EQU 2
DEF PLAYER_FACE_UP EQU 3

DEF PLAYER_OAM_INDEX EQU 0
DEF PLAYER_START_TILE_ID EQU low( map_village_tileset_size / TILE_SIZE ) 

; Interupts 
SECTION "Vblank", 			ROM0[INT_HANDLER_VBLANK]
    push af
    ld a, 1
    ld [wVBlankInterrupt], a
    pop af
	reti
SECTION "LCDC", 			ROM0[INT_HANDLER_STAT]
	reti
SECTION "Timer_Overflow", 	ROM0[INT_HANDLER_TIMER]
	reti
SECTION "Serial", 			ROM0[INT_HANDLER_SERIAL]
	reti
SECTION "Joypad", 			ROM0[INT_HANDLER_JOYPAD]
	reti


SECTION "Player Code", ROM0

Gameplay_Init::
    call Gameplay_InitMap
    call Gameplay_InitPlayer

    ret

Gameplay_InitMap::

    ; Copy tile data (village tiles & player tiles)
    MEMCOPY map_village_tileset, TILE_DATA_START_ADDR, map_village_tileset_size
	MEMCOPY character_tileset, TILE_DATA_START_ADDR + map_village_tileset_size, character_tileset_size

    MEMCOPY map_village_tilemap, TILE_MAP_START_ADDR, map_village_tilemap

    ret

Gameplay_InitPlayer::
    xor a

    ld [wJoypadCurrent], a
    ld [wJoypadPrevious], a
    ld [wShadowScreenPositionX], a
    ld [wShadowScreenPositionY], a
    
    CLEAR_16_BITS wPlayerPositionX
    CLEAR_16_BITS wPlayerPositionY

    ld a, 56 ; TODO Load the value from entity_start_position (from ldtk)
    ld [wPlayerPositionX], a

    ld a, 56
    ld [wPlayerPositionY], a

    ld a, PLAYER_FACE_DOWN
    ld [wPlayerDirection], a

    ret

UpdateInput::
    ; Get joypad inputs
    ld a, JOYP_GET_CTRL_PAD ; Load P1F_GET_DPAD flag into A to select reading the buttons
    ld [rJOYP], a

    REPT 4 ; Repeat to stabilize input reading after select
    ld a, [rJOYP] ; Read the joypad inputs
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

    ret

    ; TODO There is a lot of things optimizable here
UpdatePlayerPositionAndDirection::
    ; b: x speed, c: y speed
    ld bc, 0

.check_right
    ld a, [wJoypadCurrent]
    and JOYP_RIGHT ; Select right
    jr nz, .check_left
    ; Player facing right
    ld a, PLAYER_FACE_RIGHT
    ld [wPlayerDirection], a

    ld b, PLAYER_SPEED

    jr .end_check_input
.check_left
    ld a, [wJoypadCurrent]
    and JOYP_LEFT ; Select left
    jr nz, .check_up

    ; Player facing left
    ld a, PLAYER_FACE_LEFT
    ld [wPlayerDirection], a

    ld b, -PLAYER_SPEED

    jr .end_check_input
.check_up
    ld a, [wJoypadCurrent]
    and JOYP_UP ; Select up
    jr nz, .check_down

    ; Player facing up
    ld a, PLAYER_FACE_UP
    ld [wPlayerDirection], a

    ld c, -PLAYER_SPEED

    jr .end_check_input
.check_down
    ld a, [wJoypadCurrent]
    and JOYP_DOWN; Select down
    jr nz, .end_check_input

    ; Player facing down
    ld a, PLAYER_FACE_DOWN
    ld [wPlayerDirection], a

    ld c, PLAYER_SPEED

    jr .end_check_input

.end_check_input

    ; Update 16 bits X
    ld a, [wPlayerPositionX]
    add b
    ld [wPlayerPositionX], a

    ld a, [wPlayerPositionX+1]
    adc 0
    ld [wPlayerPositionX+1], a

    ; Update 16 bits Y
    ld a, [wPlayerPositionY]
    add c
    ld [wPlayerPositionY], a

    ld a, [wPlayerPositionY+1]
    adc 0
    ld [wPlayerPositionY+1], a

    ; 1) if Player position is between 0 and SCREEN_WIDTH_PX/2;SCREEN_HEIGHT_PX/2
    ;   ScreenPos should be lock to 0;0
    ; 2) if Player position is between TILEMAP_WIDTH_PX - SCREEN_WIDTH_PX;TILEMAP_HEIGHT_PX - SCREEN_HEIGHT_PX and 256;256
    ;   Screen position should be locked to  TILEMAP_WIDTH_PX - SCREEN_WIDTH_PX;TILEMAP_HEIGHT_PX - SCREEN_HEIGHT_PX
    ; 3) Otherwize, position should be 
    ;   PlayerX-(SCREEN_WIDTH_PX/2);PlayerY-(SCREEN_HEIGHT_PX/2)

    ; 1)
    ld a, [wPlayerPositionX]
    cp (SCREEN_WIDTH_PX/2)
    jr nc, .x_above_half_screen
    xor a 
    ld [wShadowScreenPositionX], a
    jr .check_y_screen_pos
.x_above_half_screen
    ; 2)
    ld a, [wPlayerPositionX]
    cp TILEMAP_WIDTH_PX - (SCREEN_WIDTH_PX / 2)
    jr c, .x_in_between
    ld a, TILEMAP_WIDTH_PX - (SCREEN_WIDTH_PX)
    ld [wShadowScreenPositionX], a
    jr .check_y_screen_pos
.x_in_between
    ; 3)
    ld a, [wPlayerPositionX]
    sub a, SCREEN_WIDTH_PX/2
    ld [wShadowScreenPositionX], a

.check_y_screen_pos
    ld a, [wPlayerPositionY]
    cp (SCREEN_HEIGHT_PX/2)
    jr nc, .y_above_half_screen
    xor a 
    ld [wShadowScreenPositionY], a
    jr .end_camera_check
.y_above_half_screen
    ; 2)
    ld a, [wPlayerPositionY]
    cp TILEMAP_HEIGHT_PX - (SCREEN_HEIGHT_PX / 2)
    jr c, .y_in_between
    ld a, TILEMAP_HEIGHT_PX - (SCREEN_HEIGHT_PX)
    ld [wShadowScreenPositionY], a
    jr .end_camera_check
.y_in_between
    ; 3)
    ld a, [wPlayerPositionY]
    sub a, SCREEN_HEIGHT_PX/2
    ld [wShadowScreenPositionY], a
   

.end_camera_check

    ret

Gameplay_Update::
    call UpdateInput
    call UpdatePlayerPositionAndDirection

    ; Update player OAM Data
    ld a, [wShadowScreenPositionY]
    ld b, a
    ld a, [wPlayerPositionY]
    sub b
    ld [wShadowOAM+(PLAYER_OAM_INDEX * OBJ_SIZE)+OAMA_Y], a

    ld a, [wShadowScreenPositionX]
    ld b, a
    ld a, [wPlayerPositionX]
    sub b
    ld [wShadowOAM+(PLAYER_OAM_INDEX * OBJ_SIZE)+OAMA_X], a

    ld a, [wPlayerDirection]
    ld b, PLAYER_START_TILE_ID
    add a, b
    ld [wShadowOAM+(PLAYER_OAM_INDEX * OBJ_SIZE)+OAMA_TILEID], a
    
    ld a, 0b00000001
    ld [wShadowOAM+(PLAYER_OAM_INDEX * OBJ_SIZE)+OAMA_FLAGS], a

    ret
