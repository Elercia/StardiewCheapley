
# Go to the build folder inside the root folder (working dir should be the script folder)
cd ..
mkdir build
cd build 

# Erase build files
rm -f *.o *.sym *.map *.gb

# Compile
../bin/macos/rgbasm -o stardiewcheapley.o -I ../sources ../sources/stardiewcheapley.asm &&
../bin/macos/rgblink -o stardiewcheapley.gb --map stardiewcheapley.map --sym stardiewcheapley.sym stardiewcheapley.o &&
../bin/macos/rgbfix -v -p 0xFF stardiewcheapley.gb &&
echo Done