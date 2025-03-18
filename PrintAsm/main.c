#include <stdio.h>
 
 int sum (int x, int y)
 {
     printf("sum: %d\n", x + y);
 
     return x + y;
 }

// gcc -g -no-pie -Wl,-z,noexecstack main.o 0-Linux-nasm-64.o -o program

// # Компиляция ассемблерного кода
// nasm -f elf64 -l printfAsm.lst printfAsm.s

// # Компиляция C-кода
// gcc -c main.c -o main.o

// # Компоновка объектных файлов
// gcc main.o printfAsm.o -o main

// # Запуск программы
// ./main