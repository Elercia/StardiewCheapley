python3 build_asset.py

# Go to the build folder inside the root folder (working dir should be the script folder)
cd ..
mkdir -p build
cd build 

# Erase build files
rm -f *.o *.sym *.map *.gb

# Compile
../bin/linux/rgbasm -o stardewcheapley.o -I ../sources ../sources/stardewcheapley.asm &&
../bin/linux/rgblink -o stardewcheapley.gb --map stardewcheapley.map --sym stardewcheapley.sym stardewcheapley.o &&
../bin/linux/rgbfix -v -p 0xFF --fix-spec lhg stardewcheapley.gb &&
echo Done
