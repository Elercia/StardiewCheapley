; ---------------------------------
; This file is auto generated. Do not edit
; ---------------------------------

SECTION "GFX", ROM0

font_tileset:
    INCBIN "gfx/font_tileset.2bpp"
   .end
DEF font_tileset_size EQU font_tileset.end - font_tileset

character_tileset:
    INCBIN "gfx/character_tileset.2bpp"
   .end
DEF character_tileset_size EQU character_tileset.end - character_tileset

village_tileset:
    INCBIN "gfx/village_tileset.2bpp"
   .end
DEF village_tileset_size EQU village_tileset.end - village_tileset

map_village_tilemap:
    INCBIN "gfx/map_village.tilemap"
    .end
DEF map_village_tilemap_size EQU map_village_tilemap.end - map_village_tilemap
