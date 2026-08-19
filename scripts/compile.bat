
REM Go to the build folder inside the root folder (working dir should be the script folder)
cd ..
mkdir build
cd build 

REM Erase build files
del /f /s "*.o" "*.sym" "*.map" "*.gb"

REM Compile
..\\bin\\win64\\rgbasm.exe -o stardewcheapley.o -I ..\\sources ..\\sources\\stardewcheapley.asm
..\\bin\\win64\\rgblink.exe -o stardewcheapley.gb --map stardewcheapley.map --sym stardewcheapley.sym stardewcheapley.o 
..\\bin\\win64\\rgbfix.exe  -v -p 0xFF  -v -p 0xFF --fix-spec lhg stardewcheapley.gb
