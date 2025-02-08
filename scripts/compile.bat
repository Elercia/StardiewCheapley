
REM Go to the build folder inside the root folder (working dir should be the script folder)
cd ..
mkdir build
cd build 

REM Erase build files
del /f /s "*.o" "*.sym" "*.map" "*.gb"

REM Compile
..\\bin\\win64\\rgbasm.exe -o stardiewcheapley.o -I ..\\sources ..\\sources\\stardiewcheapley.asm
..\\bin\\win64\\rgblink.exe -o stardiewcheapley.gb --map stardiewcheapley.map --sym stardiewcheapley.sym stardiewcheapley.o 
..\\bin\\win64\\rgbfix.exe -v -p 0xFF stardiewcheapley.gb