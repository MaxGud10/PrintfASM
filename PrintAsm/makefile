# Default target
all: main

# Build final executable with sanitizers
main: main.o printfAsm.o
	gcc -fsanitize=address,undefined -no-pie main.o printfAsm.o -o main

# Compile C code with sanitizers
main.o: main.c
	gcc -fsanitize=address,undefined -c main.c -o main.o

# Compile assembly code
printfAsm.o: printfAsm.s
	nasm -f elf64 -F dwarf -g printfAsm.s -o printfAsm.o

# Cleanup
clean:
	rm -f *.o main