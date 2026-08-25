SECTION "Joypad Variables", WRAM0
wJoypadCurrent:: db ; TODO Move to another file "input.asm" 
wJoypadPrevious:: db
wButtonCurrent:: db ; TODO Move to another file "input.asm" 
wButtonPrevious:: db

SECTION "Interrupts Variables", WRAM0
wVBlankInterrupt:: db

SECTION "Screen Variables", WRAM0
; Shadowing of rSCX & rSCY to update only in vblanks (to avoid tearing)
wShadowScreenPositionX:: db
wShadowScreenPositionY:: db

SECTION "Player Variables", WRAM0
; 2 bytes for pixel position in world. 
; Have it as u16  is not useful right now but will be necessary when we will be using streaming
;   And its challenging
;   But too challging atm, so we don't use it 
wPlayerPositionX:: dw 
wPlayerPositionY:: dw
wPlayerDirection:: db ; 1 byte for direction (only uses 2 bits)
wPlayerActionHelperPositionX:: db
wPlayerActionHelperPositionY:: db

wCurrentAnimationAddr:: dw ; Address of the current animation
wCurrentAnimationDelayBeforeNextFrame::db
wCurrentAnimationFrameIndex::db
wCurrentAnimationFrameCount::db ; Used to modulo the animation

rsreset
    DEF CROPS_STATE         rb ; offset 0, bitfield of useful data
        DEF CROPS_STATE_IS_VALID EQU %00000001; 1 in this bit = is planted
    DEF CROPS_POSITION_X    rb ; offset 1
    DEF CROPS_POSITION_Y    rb ; offset 2
    DEF CROPS_SIZE          rb 0 ; size of CROPS in bytes

DEF CROPS_COUNT EQU 15
DEF CROPS_SECTION_SIZE EQU CROPS_COUNT * CROPS_SIZE

SECTION "Crops Variables", WRAM0
wCropsData:: ds CROPS_SECTION_SIZE


DEF PLAYER_SPEED EQU 1
DEF PLAYER_ANIMATION_SPEED EQU 10 ; N frames per animation frame

DEF PLAYER_SPRITE_WIDTH EQU 16
DEF PLAYER_SPRITE_HEIGHT EQU 16

DEF PLAYER_FACE_LEFT EQU 0
DEF PLAYER_FACE_RIGHT EQU 1
DEF PLAYER_FACE_DOWN EQU 2
DEF PLAYER_FACE_UP EQU 3

DEF PLAYER_OAM_INDEX_UPPER_LEFT EQU 0
DEF PLAYER_OAM_INDEX_UPPER_RIGHT EQU 1
DEF PLAYER_OAM_INDEX_LOWER_LEFT EQU 2
DEF PLAYER_OAM_INDEX_LOWER_RIGHT EQU 3
DEF PLAYER_OAM_ACTION_TARGET EQU 4

DEF PLAYER_START_TILE_ID EQU 80
DEF PLAYER_TILESET_START_ADDR EQU TILE_DATA_START_ADDR + ( PLAYER_START_TILE_ID * TILE_SIZE)
DEF PLAYER_TILSET_COUNT EQU (character_tileset_size / TILE_SIZE)
DEF PLAYER_ACTION_TARGET_TILE_ID EQU PLAYER_START_TILE_ID + PLAYER_TILSET_COUNT
DEF PLAYER_ACTION_TARGET_START_ADDR EQU TILE_DATA_START_ADDR + ( PLAYER_ACTION_TARGET_TILE_ID * TILE_SIZE)

DEF TILE_MAP_METADATA_COLLISION EQU 1
DEF TILE_MAP_METADATA_CULTIVABLE EQU 2

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

	MEMCOPY character_tileset, PLAYER_TILESET_START_ADDR, character_tileset_size
    MEMCOPY action_target,PLAYER_ACTION_TARGET_START_ADDR, action_target_size

    MEMCOPY map_village_tilemap, TILE_MAP_START_ADDR, map_village_tilemap

    ld de, CROPS_SECTION_SIZE
    ld hl, wCropsData
    call MemClear 

    ret

Gameplay_InitPlayer::
    xor a

    ld [wJoypadCurrent], a
    ld [wJoypadPrevious], a
    ld [wButtonCurrent], a
    ld [wButtonPrevious], a
    ld [wShadowScreenPositionX], a
    ld [wShadowScreenPositionY], a

    ld [wPlayerActionHelperPositionX], a
    ld [wPlayerActionHelperPositionY], a
    
    CLEAR_16_BITS wPlayerPositionX
    CLEAR_16_BITS wPlayerPositionY

    ld a, 56 ; TODO Load the value from entity_start_position (from ldtk)
    ld [wPlayerPositionX], a

    ld a, 56
    ld [wPlayerPositionY], a

    ld a, PLAYER_FACE_DOWN
    ld [wPlayerDirection], a

    LOAD_16_BITS wCurrentAnimationAddr, walking_down
    ld a, walking_down_frame_count
    ld [wCurrentAnimationFrameCount], a
    ld a, 0
    ld [wCurrentAnimationFrameIndex], a
    ld [wCurrentAnimationDelayBeforeNextFrame], a

    ret

UpdateInput::
.read_pad
    ; Get joypad inputs
    ld a, JOYP_GET_CTRL_PAD ; Load P1F_GET_DPAD flag into A to select reading the direction pad
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
.read_buttons
    ; Get joypad inputs
    ld a, JOYP_GET_BUTTONS ; Load JOYP_GET_BUTTONS flag into A to select reading the buttons
    ld [rJOYP], a

    REPT 4 ; Repeat to stabilize input reading after select
    ld a, [rJOYP] ; Read the joypad inputs
    ENDR

    ld b, a ; Save the read data into b

    ; Update old inputs with current ones
    ld a, [wButtonCurrent]
    ld [wButtonPrevious], a

    ; Update current inputs variable
    ld a, b
    ld [wButtonCurrent], a
    
.cleanup_input_read
    ld a, JOYP_GET_NONE ; Load JOYP_GET_NONE flag into A to disable input reading
    ldh [rJOYP], a

    ret

; params : 
;   HL is the animation label
;   D the animation frame count
Animation_StartOrAdvanceFrame::
    ld b, l
    ld a, [wCurrentAnimationAddr]
    cp a, b
    jr nz, .change_animation
    ld b, h
    ld a, [wCurrentAnimationAddr+1]
    cp a, b
    jr nz, .change_animation
    
.advance_animation ; animation is the same, advance animation index (modulo size)
    ; Check the delay between frames
    ld a, [wCurrentAnimationDelayBeforeNextFrame]
    inc a
    cp a, PLAYER_ANIMATION_SPEED
    ld [wCurrentAnimationDelayBeforeNextFrame], a
    ret nz

    ; Change the frame index
    ld a, [wCurrentAnimationFrameCount]
    ld b, a
    ld a, [wCurrentAnimationFrameIndex]
    inc a
    cp a, b
    ld [wCurrentAnimationFrameIndex], a
    ld a, 0
    ld [wCurrentAnimationDelayBeforeNextFrame], a
    ret nz ; early return, we did not reach animation frame end
    
    ld a, 0
    ld [wCurrentAnimationFrameIndex], a ; go back to animation 0
    ld [wCurrentAnimationDelayBeforeNextFrame], a
    ret

.change_animation
    ld a, 0
    ld [wCurrentAnimationFrameIndex], a ; go back to animation 0
    ld [wCurrentAnimationDelayBeforeNextFrame], a 
    ld a, d
    ld [wCurrentAnimationFrameCount], a ; store the animation count
    ld a, l
    ld [wCurrentAnimationAddr], a
    ld a, h
    ld [wCurrentAnimationAddr+1], a
    ret

    ; TODO There is a lot of things optimizable here
UpdatePlayerPositionAndDirection::

.check_right
    ld a, [wJoypadCurrent]
    and JOYP_RIGHT ; Select right
    jr nz, .check_left

    ; Player facing right
    ld a, PLAYER_FACE_RIGHT
    ld [wPlayerDirection], a

    ld hl, walking_right
    ld d, walking_right_frame_count
    call Animation_StartOrAdvanceFrame 

    ; Check collisions
    ; 1) Upper right corner
    ; 2) Lower right corner

    ; 1)
    ld a, [wPlayerPositionX]
    add PLAYER_SPEED ; Add the speed so we check the next position
    add PLAYER_SPRITE_WIDTH-1
    ld d, a ; Setup Gameplay_GetTileMetadata params
    ld a, [wPlayerPositionY]
    ld e, a ; Setup Gameplay_GetTileMetadata params
    call Gameplay_GetTileMetadata
    cp TILE_MAP_METADATA_COLLISION
    jp z, .no_update_pos_because_colision

    ; 2)
    ld a, [wPlayerPositionX]
    add PLAYER_SPEED ; Add the speed so we check the next position
    add PLAYER_SPRITE_WIDTH-1
    ld d, a ; Setup Gameplay_GetTileMetadata params
    ld a, [wPlayerPositionY]
    add PLAYER_SPRITE_HEIGHT-1
    ld e, a ; Setup Gameplay_GetTileMetadata params
    call Gameplay_GetTileMetadata
    cp TILE_MAP_METADATA_COLLISION
    jp z, .no_update_pos_because_colision

    ld a, [wPlayerPositionX]
    add PLAYER_SPEED
    ld [wPlayerPositionX], a

    jp .end_check_input
.check_left
    ld a, [wJoypadCurrent]
    and JOYP_LEFT ; Select left
    jr nz, .check_up

    ; Player facing left
    ld a, PLAYER_FACE_LEFT
    ld [wPlayerDirection], a

    ld hl, walking_left
    ld d, walking_left_frame_count
    call Animation_StartOrAdvanceFrame 

    ; Check collisions
    ; 1) Upper left corner
    ; 2) Lower left corner

    ; 1)
    ld a, [wPlayerPositionX]
    sub PLAYER_SPEED
    ld d, a ; Setup Gameplay_GetTileMetadata params
    ld a, [wPlayerPositionY]
    ld e, a ; Setup Gameplay_GetTileMetadata params
    call Gameplay_GetTileMetadata
    cp TILE_MAP_METADATA_COLLISION
    jp z, .no_update_pos_because_colision

    ; 2)
    ld a, [wPlayerPositionX]
    sub PLAYER_SPEED
    ld d, a ; Setup Gameplay_GetTileMetadata params
    ld a, [wPlayerPositionY]
    add PLAYER_SPRITE_HEIGHT-1
    ld e, a ; Setup Gameplay_GetTileMetadata params
    call Gameplay_GetTileMetadata
    cp TILE_MAP_METADATA_COLLISION
    jp z, .no_update_pos_because_colision

    ld a, [wPlayerPositionX]
    sub PLAYER_SPEED
    ld [wPlayerPositionX], a

    jp .end_check_input
.check_up
    ld a, [wJoypadCurrent]
    and JOYP_UP ; Select up
    jr nz, .check_down

    ; Player facing up
    ld a, PLAYER_FACE_UP
    ld [wPlayerDirection], a

    ld hl, walking_up
    ld d, walking_up_frame_count
    call Animation_StartOrAdvanceFrame 

    ; Check collisions
    ; 1) Upper left corner
    ; 2) Upper right corner

    ; 1)
    ld a, [wPlayerPositionX]
    ld d, a ; Setup Gameplay_GetTileMetadata params
    ld a, [wPlayerPositionY]
    sub PLAYER_SPEED
    ld e, a ; Setup Gameplay_GetTileMetadata params
    call Gameplay_GetTileMetadata
    cp TILE_MAP_METADATA_COLLISION
    jr z, .no_update_pos_because_colision

    ; 2)
    ld a, [wPlayerPositionX]
    add PLAYER_SPRITE_WIDTH-1
    ld d, a ; Setup Gameplay_GetTileMetadata params
    ld a, [wPlayerPositionY]
    sub PLAYER_SPEED
    ld e, a ; Setup Gameplay_GetTileMetadata params
    call Gameplay_GetTileMetadata
    cp TILE_MAP_METADATA_COLLISION
    jr z, .no_update_pos_because_colision

    ld a, [wPlayerPositionY]
    sub PLAYER_SPEED
    ld [wPlayerPositionY], a

    jr .end_check_input
.check_down
    ld a, [wJoypadCurrent]
    and JOYP_DOWN; Select down
    jr nz, .end_check_input

    ; Player facing down
    ld a, PLAYER_FACE_DOWN
    ld [wPlayerDirection], a

    ld hl, walking_down
    ld d, walking_down_frame_count
    call Animation_StartOrAdvanceFrame 

    ; Check collisions
    ; 1) Lower left corner
    ; 2) Lower right corner

    ; 1)
    ld a, [wPlayerPositionX]
    ld d, a ; Setup Gameplay_GetTileMetadata params
    ld a, [wPlayerPositionY]
    add PLAYER_SPEED
    add PLAYER_SPRITE_HEIGHT-1
    ld e, a ; Setup Gameplay_GetTileMetadata params
    call Gameplay_GetTileMetadata
    cp TILE_MAP_METADATA_COLLISION
    jr z, .no_update_pos_because_colision

    ; 2) 
    ld a, [wPlayerPositionX]
    add PLAYER_SPRITE_WIDTH-1
    ld d, a ; Setup Gameplay_GetTileMetadata params
    ld a, [wPlayerPositionY]
    add PLAYER_SPEED
    add PLAYER_SPRITE_HEIGHT-1
    ld e, a ; Setup Gameplay_GetTileMetadata params
    call Gameplay_GetTileMetadata
    cp TILE_MAP_METADATA_COLLISION
    jr z, .no_update_pos_because_colision

    ld a, [wPlayerPositionY]
    add PLAYER_SPEED
    ld [wPlayerPositionY], a

.end_check_input

    ; Commented because it handle 16 bits position and I want to keep the code but everywhere else positions are
    ;   handled as 8 bits
; .update_ram_positions 
;     ; Update 16 bits X
;     ld a, [wSpeedX]
;     ld b, a

;     ld a, [wPlayerPositionX]
;     add b ; Add the X movement stored in b
;     ld [wPlayerPositionX], a

;     ld a, [wPlayerPositionX+1]
;     adc 0
;     ld [wPlayerPositionX+1], a

;     ; Update 16 bits Y
;     ld a, [wSpeedY]
;     ld b, a

;     ld a, [wPlayerPositionY]
;     add b ; Add the X movement stored in b
;     ld [wPlayerPositionY], a

;     ld a, [wPlayerPositionY+1]
;     adc 0
;     ld [wPlayerPositionY+1], a

.no_update_pos_because_colision

.update_background_scroll
    ; 1) if Player position is between 0 and SCREEN_WIDTH_PX/2;SCREEN_HEIGHT_PX/2
    ;   ScreenPos should be lock to 0;0
    ; 2) if Player position is between TILEMAP_WIDTH_PX - SCREEN_WIDTH_PX/2;TILEMAP_HEIGHT_PX - SCREEN_HEIGHT_PX/2 and 256;256
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

; Load the tile metadata from 8 bits position stored in DE (XY)
; Return in a
Gameplay_GetTileMetadata::
    push de
    
    ; Get the cell by doing : cell = ( pos_x / TILE_WIDTH ) + ( ( pos_y / TILE_HEIGHT ) * MAP_WIDTH )

    ; Begin by the y position
    ; Divide position by TILE_WIDTH (shift 3 times)
    srl e
    srl e
    srl e

    ; Multiply by the map width to get the proper collision index
    ld l, 0
    ld h, 0

    ; Dumb multiplication
    ld d, 0
    ; ld e, e
    REPT TILEMAP_WIDTH
        add hl, de
    ENDR

    pop de ; get back args

    ; Divide position by TILE_WIDTH (shift 3 times)
    srl d
    srl d
    srl d
    
    ; D is tile index on the x side
    ld e, d
    ld d, 0
    add hl, de

    ; Finaly, add the start offset of the collision map
    ld de, map_village_collisions
    add hl, de

    ld a, [hl] ; return value
    ret

UpdatePlayerAction:: 
    ; Loop through all the crops slots to search for one used with the same coordinates
    SetupStackArgs LastUnusedCropsSpot

    ; 1) We need to get the coordinate of the target tile
    ; 2) Check if it is a tile that is cultivable (metadata)
    ; Check if there is a crop already at this tile
    ;   Place something if there is not,
    ;   Remove the existing one without placing another one

    ; 1)
    ld a, [wPlayerDirection]
    cp PLAYER_FACE_LEFT
    jr nz, .check_right_x
    ld a, [wPlayerPositionX]
    sub TILE_WIDTH
    ld d, a
    jr .no_y_change
.check_right_x
    cp PLAYER_FACE_RIGHT
    jr nz, .no_x_change
    ld a, [wPlayerPositionX]
    add PLAYER_SPRITE_WIDTH
    ld d, a
    jr .no_y_change
.no_x_change
    ld a, [wPlayerPositionX]
    ld d, a
.check_y
    ld a, [wPlayerDirection]
    cp PLAYER_FACE_UP
    jr nz, .check_right_y
    ld a, [wPlayerPositionY]
    sub TILE_WIDTH
    ld e, a
    jr .end_check_direction
.check_right_y
    cp PLAYER_FACE_DOWN
    jr nz, .no_y_change
    ld a, [wPlayerPositionY]
    add PLAYER_SPRITE_HEIGHT
    ld e, a
    jr .end_check_direction
.no_y_change
    ld a, [wPlayerPositionY]
    ld e, a
.end_check_direction

    ; 2)
    push de
    call Gameplay_GetTileMetadata
    pop de

    cp a, TILE_MAP_METADATA_CULTIVABLE
    jp nz, .not_cultivable_tile

    ; Round down the position on the grid
    REPT 3
    srl d
    srl e
    ENDR
    REPT 3
    sla d
    sla e
    ENDR

    ld a, d
    ld [wPlayerActionHelperPositionX], a
    ld a, e
    ld [wPlayerActionHelperPositionY], a 

    ; Has the user pressed the button "A"
    ld a, [wButtonCurrent]
    and B_JOYP_A ; Select only the a button
    ret nz

    ld hl, wCropsData
    ldr16_r16 d, e, h, l
    ld b, 0
.find_already_existing_crops_loop
    ; crops + it
    ; inc it of CROPS_SIZE
    push bc ; need to save BC because of b
    ldr16_r16 h, l, d, e 
    ld bc, CROPS_STATE
    add hl, bc
    ld a, [hl]
    and CROPS_STATE_IS_VALID
    jr z, .find_already_existing_crops_loop_incr_and_store_current_index

    ldr16_r16 h, l, d, e
    ld bc, CROPS_POSITION_X
    add hl, bc
    ld a, [wPlayerActionHelperPositionX]
    ld c, a
    ld a, [hl]
    cp c
    jr nz, .find_already_existing_crops_loop_incr
    
    ldr16_r16 h, l, d, e
    ld bc, CROPS_POSITION_Y
    add hl, bc
    ld a, [wPlayerActionHelperPositionY]
    ld c, a
    ld a, [hl]
    cp c
    jr nz, .find_already_existing_crops_loop_incr
    jr .crops_found
.find_already_existing_crops_loop_incr
    ldr16_r16 h, l, d, e
    ld bc, CROPS_SIZE
    add hl, bc
    ldr16_r16 d, e, h, l
    pop bc
    inc b
    cp CROPS_COUNT
    jr nz, .find_already_existing_crops_loop ; on previous and
    jr .crops_not_found
.find_already_existing_crops_loop_incr_and_store_current_index
    ld hl, sp+LastUnusedCropsSpot
    ld a, b
    ld [hl], a
    jr .find_already_existing_crops_loop_incr

.crops_not_found

    ld hl, sp+LastUnusedCropsSpot
    ld a, [hl]

    ld h, 0
    ld l, a
    Multiply CROPS_SIZE
    ld bc, wCropsData
    add hl, bc

    ld bc, CROPS_POSITION_X
    add hl, bc
    ld a, [wPlayerActionHelperPositionX]
    ld [hl], a
    ldr16_r16 h, l, d, e
    ld bc, CROPS_POSITION_Y
    add hl, bc
    ld a, [wPlayerActionHelperPositionY]
    ld [hl], a
    ldr16_r16 h, l, d, e
    ld bc, CROPS_STATE
    add hl, bc
    ld a, CROPS_STATE_IS_VALID
    ld [hl], a

    SetbackStackArgs LastUnusedCropsSpot
    ret

.crops_found
    pop bc
    ; ptr is still inside DE
    ldr16_r16 h, l, d, e
    ld bc, CROPS_STATE
    add hl, bc
    ld a, 0
    ld [hl], a

    SetbackStackArgs LastUnusedCropsSpot

    ret

.not_cultivable_tile
    ld a, -16 ;  ? Set to be invisible
    ld [wPlayerActionHelperPositionX], a
    ld [wPlayerActionHelperPositionY], a

    SetbackStackArgsAndNames LastUnusedCropsSpot

    ret

UpdatePlayerOAM::
    ; Update player OAM Data

    ; OAM positions
    ld a, [wShadowScreenPositionY]
    ld b, a
    ld a, [wPlayerPositionY]
    sub b
    add 16 ; This is the OAM zone where tile are invisible (offset)
    ld [wShadowOAM+(PLAYER_OAM_INDEX_UPPER_LEFT * OBJ_SIZE)+OAMA_Y], a
    ld [wShadowOAM+(PLAYER_OAM_INDEX_UPPER_RIGHT * OBJ_SIZE)+OAMA_Y], a

    add TILE_HEIGHT
    ld [wShadowOAM+(PLAYER_OAM_INDEX_LOWER_LEFT * OBJ_SIZE)+OAMA_Y], a
    ld [wShadowOAM+(PLAYER_OAM_INDEX_LOWER_RIGHT * OBJ_SIZE)+OAMA_Y], a

    ld a, [wShadowScreenPositionX]
    ld b, a
    ld a, [wPlayerPositionX]
    sub b
    add 8 ; This is the OAM zone where tile are invisible (offset)
    ld [wShadowOAM+(PLAYER_OAM_INDEX_UPPER_LEFT * OBJ_SIZE)+OAMA_X], a
    ld [wShadowOAM+(PLAYER_OAM_INDEX_LOWER_LEFT * OBJ_SIZE)+OAMA_X], a

    add TILE_WIDTH
    ld [wShadowOAM+(PLAYER_OAM_INDEX_UPPER_RIGHT * OBJ_SIZE)+OAMA_X], a
    ld [wShadowOAM+(PLAYER_OAM_INDEX_LOWER_RIGHT * OBJ_SIZE)+OAMA_X], a

    ; OAM Tiles index and attributes byte

    ; Load the current animation start addr
    ld a, [wCurrentAnimationAddr]
    ld l, a
    ld a, [wCurrentAnimationAddr+1]
    ld h, a

    ; Add the offset * 4 (4 tiles per animation frame)
    ld a, [wCurrentAnimationFrameIndex]
    ld e, a
    REPT 3
    add e
    ENDR
    ld e, a
    ld d, 0
    add hl, de

    ld d, h ; DE is the base addr of the current animation (+1 2 3 to get the right tile)
    ld e, l

    ld a, [de] ; a is the tile we want in the source tileset. We need to convert it to the real one (lookup in tilemap)
    ld hl, character_tileset_tilemap
    ld b, 0
    ld c, a
    add hl, bc
    ld b, a
    ld a, [hl] ; a is the real tile to use
    add a, PLAYER_START_TILE_ID ; add the offset where we store tiles for player
    ld [wShadowOAM+(PLAYER_OAM_INDEX_UPPER_LEFT * OBJ_SIZE)+OAMA_TILEID], a

    ld hl, character_tileset_attribute_map
    ld c, b
    ld b, 0
    add hl, bc
    ld a, [hl]
    ld [wShadowOAM+(PLAYER_OAM_INDEX_UPPER_LEFT * OBJ_SIZE)+OAMA_FLAGS], a

    ld h, d ; get back the base address of the animation into hl
    ld l, e
    inc hl ; increment it from last tile use and store it back into DE
    ld d, h
    ld e, l

    ld a, [de] ; a is the tile we want in the source tileset. We need to convert it to the real one (lookup in tilemap)
    ld hl, character_tileset_tilemap
    ld b, 0
    ld c, a
    add hl, bc
    ld b, a
    ld a, [hl]
    add PLAYER_START_TILE_ID ; add the offset where we store tiles for player
    ld [wShadowOAM+(PLAYER_OAM_INDEX_UPPER_RIGHT * OBJ_SIZE)+OAMA_TILEID], a

    ld hl, character_tileset_attribute_map
    ld c, b
    ld b, 0
    add hl, bc
    ld a, [hl]
    ld [wShadowOAM+(PLAYER_OAM_INDEX_UPPER_RIGHT * OBJ_SIZE)+OAMA_FLAGS], a

    ld h, d ; get back the base address of the animation into hl
    ld l, e
    inc hl ; increment it from last tile use and store it back into DE
    ld d, h
    ld e, l

    ld a, [de] ; a is the tile we want in the source tileset. We need to convert it to the real one (lookup in tilemap)
    ld hl, character_tileset_tilemap
    ld b, 0
    ld c, a
    add hl, bc
    ld b, a
    ld a, [hl]
    add PLAYER_START_TILE_ID ; add the offset where we store tiles for player
    ld [wShadowOAM+(PLAYER_OAM_INDEX_LOWER_LEFT * OBJ_SIZE)+OAMA_TILEID], a

    ld hl, character_tileset_attribute_map
    ld c, b
    ld b, 0
    add hl, bc
    ld a, [hl]
    ld [wShadowOAM+(PLAYER_OAM_INDEX_LOWER_LEFT * OBJ_SIZE)+OAMA_FLAGS], a

    ld h, d
    ld l, e
    inc hl
    ld d, h
    ld e, l
    ld a, [de] ; a is the tile we want in the source tileset. We need to convert it to the real one (lookup in tilemap)
    
    ld hl, character_tileset_tilemap
    ld b, 0
    ld c, a
    add hl, bc
    ld b, a
    ld a, [hl]
    add PLAYER_START_TILE_ID ; add the offset where we store tiles for player
    ld [wShadowOAM+(PLAYER_OAM_INDEX_LOWER_RIGHT * OBJ_SIZE)+OAMA_TILEID], a

    ld hl, character_tileset_attribute_map
    ld c, b
    ld b, 0
    add hl, bc
    ld a, [hl]
    ld [wShadowOAM+(PLAYER_OAM_INDEX_LOWER_RIGHT * OBJ_SIZE)+OAMA_FLAGS], a

    ; Update Action target
    ld a, [wShadowScreenPositionY]
    ld b, a
    ld a, [wPlayerActionHelperPositionY]
    sub b
    add 16 ; This is the OAM zone where tile are invisible (offset)
    ld [wShadowOAM+(PLAYER_OAM_ACTION_TARGET * OBJ_SIZE)+OAMA_Y], a

    ld a, [wShadowScreenPositionX]
    ld b, a
    ld a, [wPlayerActionHelperPositionX]
    sub b
    add 8 ; This is the OAM zone where tile are invisible (offset)
    ld [wShadowOAM+(PLAYER_OAM_ACTION_TARGET * OBJ_SIZE)+OAMA_X], a

    ld a, PLAYER_ACTION_TARGET_TILE_ID
    ld [wShadowOAM+(PLAYER_OAM_ACTION_TARGET * OBJ_SIZE)+OAMA_TILEID], a

    ld a, 0
    ld [wShadowOAM+(PLAYER_OAM_ACTION_TARGET * OBJ_SIZE)+OAMA_FLAGS], a

    ret

Gameplay_Update::
    call UpdateInput
    call UpdatePlayerPositionAndDirection
    call UpdatePlayerAction
    call UpdatePlayerOAM

    ret
