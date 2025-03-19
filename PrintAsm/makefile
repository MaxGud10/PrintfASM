# Цель по умолчанию
all: main

# Сборка финального исполняемого файла с санитайзерами
main: main.o printfAsm.o
	gcc -fsanitize=address,undefined -no-pie main.o printfAsm.o -o main

# Компиляция C-кода с санитайзерами
main.o: main.c
	gcc -fsanitize=address,undefined -c main.c -o main.o

# Компиляция ассемблерного кода
printfAsm.o: printfAsm.s
	nasm -f elf64 -F dwarf -g printfAsm.s -o printfAsm.o

# Очистка
clean:
	rm -f *.o main