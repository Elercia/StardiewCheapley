from mimetypes import init
import subprocess
import os
import glob
from sys import platform
import csv 

class Tilset:
    input_image : str
    name : str
    include_in_rom : bool

    def __init__(self, p_input_file_name: str, p_name: str, p_include_in_rom : bool = True):
        self.input_image = p_input_file_name
        self.name = p_name
        self.include_in_rom = p_include_in_rom

class Level:
    level_name : str
    tileset_name : str

    def __init__(self, p_level_name : str, p_tileset_name: str):
        self.level_name = p_level_name
        self.tileset_name = p_tileset_name

standalone_tilesets : list[Tilset] = [
    Tilset("../Data/font_tileset.png", "font_tileset"),
    Tilset("../Data/character_tileset.png", "character_tileset"),
    Tilset("../Data/village_tileset.png", "village_tileset", p_include_in_rom = False)
]
levels : list[Level] = [
    Level("Village", "village_tileset")
]

max_level_tileset = 128 # Max 128 tile for a level
base_ldtk_export_path = "../Data/stardiew_cheapley/simplified/"

if __name__ == "__main__":
    # Erase previous built files
    files = glob.glob('../sources/gfx/*')
    for f in files:
        os.remove(f)

    rgbgfx_executable = ""

    if platform == "linux" or platform == "linux2":
        # linux
        rgbgfx_executable = "../bin/linux/rgbgfx"
    elif platform == "darwin":
        # OS X
        rgbgfx_executable = "../bin/macos/rgbgfx"
    elif platform == "win32":
        # Windows...
        rgbgfx_executable = "../bin/win64/rgbgfx"

    gfx_file_content = ("; ---------------------------------\n"
    "; This file is auto generated. Do not edit\n"
    "; ---------------------------------\n\n"
    "SECTION \"GFX\", ROM0\n\n")
    
    for tileset in standalone_tilesets:
        subprocess.run([rgbgfx_executable,
                        "--auto-palette", 
                        "--group-outputs",
                        "--unique-tiles",
                        #"--base-tile", "{}".format(max_level_tileset), 
                        "-o", "../sources/gfx/{}.2bpp".format(tileset.name), 
                        tileset.input_image])

        if tileset.include_in_rom:
            gfx_file_content += (
                "{tilesetname}:\n"
                "    INCBIN \"gfx/{tilesetname}.2bpp\"\n"
                "   .end\n"
                "DEF {tilesetname}_size EQU {tilesetname}.end - {tilesetname}\n"
                "\n").format(tilesetname = tileset.name)
        
    for level in levels:
        output_name = "map_" + level.level_name.lower()
        input_image_name = base_ldtk_export_path + level.level_name + "/Background.png"
        input_metadata_csv = base_ldtk_export_path + level.level_name + "/tilemetadata.csv"

        tile_metadata_bin = ""
        with open(input_metadata_csv, "r") as metadata_file:
            for line in metadata_file:
                raw_line_tile_metadata_id_list = line.split(",")
                line_processed_tile_metadata_list = []
                for tile_metadata in raw_line_tile_metadata_id_list:
                    if tile_metadata != "\n":
                        int_metadata = int(tile_metadata)
                        line_processed_tile_metadata_list.append(f'${int_metadata:x}')

                tile_metadata_bin += "\tdb " + (",".join(line_processed_tile_metadata_list)) + "\n"

        subprocess.run([rgbgfx_executable, 
                        "--auto-palette",
                        "--group-outputs",
                        "--auto-attr-map",
                        "--unique-tiles",
                        "--input-tileset", "../sources/gfx/{}.2bpp".format(level.tileset_name),
                        "--tilemap", "../sources/gfx/{}.tilemap".format(output_name),
                        "-o", "../sources/gfx/{}.2bpp".format(output_name), 
                        input_image_name])

        gfx_file_content += (
            "{tilesetname}_tilemap:\n"
            "    INCBIN \"gfx/{tilesetname}.tilemap\"\n"
            "    .end\n"
            "DEF {tilesetname}_tilemap_size EQU {tilesetname}_tilemap.end - {tilesetname}_tilemap\n"
            "").format(tilesetname = output_name)

        gfx_file_content += (
                    "{tilesetname}_tileset:\n"
                    "    INCBIN \"gfx/{tilesetname}.2bpp\"\n"
                    "   .end\n"
                    "DEF {tilesetname}_tileset_size EQU {tilesetname}_tileset.end - {tilesetname}_tileset\n"
                    "\n").format(tilesetname = output_name)
        gfx_file_content += (
            "{id}_collisions:\n"
            "{content}\n"
            "   .end\n"
        ).format(content = tile_metadata_bin, id = output_name)

    with open("../sources/gfx/gfx.asm", "w") as f:
        f.write(gfx_file_content)
