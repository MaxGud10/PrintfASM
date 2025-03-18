extern int myPrintfC (char* format, ...);
 
int main (void)
{
    myPrintfC ("Hello!, %c s", 'x');
    myPrintfC ("binary number: %b, %o, %x", 11, 11, 11);
    return 0;
}

// gcc -g -no-pie -Wl,-z,noexecstack main.o 0-Linux-nasm-64.o -o program
