SECTION "Joypad Variables", WRAM0
wJoypadCurrent:: db ; TODO Move to another file "input.asm" 
wJoypadPrevious:: db
wButtonCurrent:: db ; TODO Move to another file "input.asm" 
wButtonPrevious:: db


SECTION "Input Code", ROM0

Input_Init::
    xor a

    ld [wJoypadCurrent], a
    ld [wJoypadPrevious], a
    ld [wButtonCurrent], a
    ld [wButtonPrevious], a

    ret

Input_Update::
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