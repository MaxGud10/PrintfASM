# ���� �� ���������
all: main

# ������ ���������� ������������ ����� � �������������
main: main.o printfAsm.o
	gcc -fsanitize=address,undefined -no-pie main.o printfAsm.o -o main

# ���������� C-���� � �������������
main.o: main.c
	gcc -fsanitize=address,undefined -c main.c -o main.o

# ���������� ������������� ����
printfAsm.o: printfAsm.s
	nasm -f elf64 -F dwarf -g printfAsm.s -o printfAsm.o

# �������
clean:
	rm -f *.o main