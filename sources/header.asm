; 0100-014F — Cartridge header
SECTION "Header", 			ROM0[$100]
	nop
	jp EntryPoint

SECTION "Nintendo logo", 	ROM0[$104]
	ds $134 - @, 0

SECTION "Title", 			ROM0[$134] ; 16 chars long
	db "StardewCheapley"
	ds $0143-@, 0

SECTION "Compatibility mode", 	ROM0[$143]
	db $00

SECTION "Licensee code (new)", 	ROM0[$144]
	ds $145 - @, 0

SECTION "SGB flag", 		ROM0[$146]
	db $00

SECTION "Cartridge type", 	ROM0[$147] ; TODO To define
	db $00

SECTION "ROM size", 		ROM0[$148]
	db $00

SECTION "RAM size", 		ROM0[$149] 
	db $00

SECTION "Destination", 		ROM0[$014A] 
	db $01

SECTION "Licensee code (old)", 	ROM0[$014B] 
	ds $014C - @, 0

SECTION "Checksums", 	ROM0[$014C] 
	ds $014FC- @, 0