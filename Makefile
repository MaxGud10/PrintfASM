# Compiler and flags
CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra -fsanitize=address,undefined -g
ASM = nasm
ASMFLAGS = -f elf64 -F dwarf -g
LDFLAGS = -fsanitize=address,undefined -no-pie

# Targets
all: main

main: main.o printfAsm.o
	$(CXX) $(LDFLAGS) main.o printfAsm.o -o main

main.o: main.cpp
	$(CXX) $(CXXFLAGS) -c main.cpp -o main.o

printfAsm.o: printfAsm.s
	$(ASM) $(ASMFLAGS) printfAsm.s -o printfAsm.o

clean:
	rm -f *.o main

.PHONY: all clean