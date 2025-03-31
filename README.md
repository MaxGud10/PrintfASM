# Simplified Printf Clone
Written in X86 NASM Assembly for Linux as a practice problem

## Functionality
Supports those format specifiers:
```
    %d       Signed decimal integers
    %x:      Unsigned hexadecimal integers
    %o:      Unsigned octal integers
    %b:      Unsigned binary integers
    %c:      Single character
    %s:      String
    %%:      Literal percentage sign
```

## Examples
```
myPrintf("My name is %s and I'm %d years old\n", "Dedloh", 100);
Output: My name is Ded and I'm 100 years old
```
```
myPrintf("%d = 0x%x = 0q%o = 0b%b\n", 100, 100, 100, 100);
Output: 100 = 0x64 = 0q144 = 0b1100100
```
```
myPrintf ("binary number: %b, %o, %x\n%d %s %x %d%%%c%b\n", 11, 11, 11, -1, "love", 3802, 100, 33, 126);
Output: -1 love EDA 100%!1111110
        binary number: 1011, 13, B
```

## Usage

Why would anyone use it? 

Anyway, in order to compile it you'll need to have nasm installed.

That's how you can do it in Ubuntu, for example:
```
sudo apt install nasm
```
Then you can compile it into an object file and use in your C/ASM projects.
```
nasm -f elf64 printf.s -o printf.o
```
Linking can be done using GCC or any other linker:
```
gcc my_project.o ... printf.o -o my_project
```