SECTION "Interrupts Variables", WRAM0
wVBlankInterrupt:: db

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

SECTION "Vblank Code", ROM0

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
    
; OAM DMA Routine
; Reserve into HRAM some memory space to copy the code of CopyDMARoutine

SECTION "Shadow OAM", WRAM0,ALIGN[8]
wShadowOAM:
  ds 4 * 40 ;

; ROM Storage of the routine (and copy utility function)
SECTION "OAM DMA routine", ROM0
CopyDMARoutine:
  ld  hl, CopyShadowOAMToOAM_ROM
  ld  b, CopyShadowOAMToOAM_ROM.end - CopyShadowOAMToOAM_ROM ; Number of bytes to copy
  ld  c, low(CopyShadowOAMToOAM) ; Low byte of the destination address
.copy
  ld  a, [hli]
  ldh [c], a
  inc c
  dec b
  jr  nz, .copy
  ret

CopyShadowOAMToOAM_ROM:
  ldh [rDMA], a
  
  ld  a, 40
.wait
  dec a
  jr  nz, .wait
  ret
.end

SECTION "OAM DMA", HRAM

CopyShadowOAMToOAM::
  ds CopyShadowOAMToOAM_ROM.end - CopyShadowOAMToOAM_ROM ; Reserve space to copy the routine to
