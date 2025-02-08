cd ..
mkdir build
cd build 

..\\bin\\win64\\rgbasm.exe -o stardiewcheapley.o -I ..\\sources ..\\sources\\stardiewcheapley.asm
..\\bin\\win64\\rgblink.exe -o stardiewcheapley.gb --map stardiewcheapley.map --sym stardiewcheapley.sym stardiewcheapley.o 
..\\bin\\win64\\rgbfix.exe -v -p 0xFF stardiewcheapley.gb