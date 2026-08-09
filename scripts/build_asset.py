from mimetypes import init
import subprocess
import os
import glob

class Tilset:
    input_image : str
    name : str

    def __init__(self, p_input_file_name: str, p_name: str):
        self.input_image = p_input_file_name
        self.name = p_name

class Tilemap:
    input_image : str
    name : str
    tileset_name : str

    def __init__(self, p_input_image : str, p_name, p_tileset_name: str):
        self.input_image = p_input_image
        self.name = p_name
        self.tileset_name = p_tileset_name

standalone_tilesets : list[Tilset] = [
    Tilset("../Data/font_tileset.png", "font_tileset"),
    Tilset("../Data/character_tileset.png", "character_tileset"),
    Tilset("../Data/village_tileset.png", "village_tileset")
]
tilemaps : list[Tilemap] = [
    Tilemap("../Data/stardiew_cheapley/simplified/Village/Background.png", "map_village", "village_tileset")
]

max_level_tileset = 128 # Max 128 tile for a level

if __name__ == "__main__":
    # Erase previous built files
    files = glob.glob('../sources/gfx/*')
    for f in files:
        os.remove(f)

    gfx_file_content = '''SECTION "GFX", ROM0\n\n'''
    
    for tileset in standalone_tilesets:
        subprocess.run(["../bin/macos/rgbgfx",
                        "--auto-palette", 
                        "--group-outputs",
                        "--unique-tiles",
                        #"--base-tile", "{}".format(max_level_tileset), 
                        "-o", "../sources/gfx/{}.2bpp".format(tileset.name), 
                        tileset.input_image])

        gfx_file_content += (
            "{tilesetname}:\n"
            "    INCBIN \"gfx/{tilesetname}.2bpp\"\n"
            "   .end\n"
            "\n").format(tilesetname = tileset.name)
        
    for tilemap in tilemaps:
        subprocess.run(["../bin/macos/rgbgfx", 
                        "--auto-palette",
                        "--group-outputs",
                        "--auto-attr-map",
                        "--unique-tiles",
                        "--input-tileset", "../sources/gfx/{}.2bpp".format(tilemap.tileset_name),
                        "--tilemap", "../sources/gfx/{}.tilemap".format(tilemap.name),
                        "-o", "../sources/gfx/{}.2bpp".format(tilemap.name), 
                        tilemap.input_image])

        gfx_file_content += (
            "{tilesetname}_tilemap:\n"
            "    INCBIN \"gfx/{tilesetname}.tilemap\"\n"
            "    .end\n").format(tilesetname = tilemap.name)

    with open("../sources/gfx/gfx.asm", "w") as f:
        f.write(gfx_file_content)
