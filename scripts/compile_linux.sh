
# Go to the build folder inside the root folder (working dir should be the script folder)
cd ..
mkdir -p build
cd build 

# Erase build files
rm -f *.o *.sym *.map *.gb

# Compile
../bin/linux/rgbasm -o stardiewcheapley.o -I ../sources ../sources/stardiewcheapley.asm &&
../bin/linux/rgblink -o stardiewcheapley.gb --map stardiewcheapley.map --sym stardiewcheapley.sym stardiewcheapley.o &&
../bin/linux/rgbfix -v -p 0xFF --fix-spec lhg stardiewcheapley.gb &&
echo Done