extern int myPrintf (char* format, ...);
 
int main (void)
{
    //myPrintf (" %f", 3.14);
    int res = myPrintf ("binary number: %b, %o, %x\n", 11, 11, 11);
    // return 0;


    // int res = myPrintf (" %f", 3.14);  

    return res;
}

// System V AMD64 ABI

// gcc -g -no-pie -Wl,-z,noexecstack main.o 0-Linux-nasm-64.o -o program

// TODO flushbuf
// TODO переполнение 
//     int res = myPrintf ("%o\n%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b\n", 1, 1, "ded", 380123, 100, 33, 123,
// 1, "ded", 380123, 100, 33, 123);