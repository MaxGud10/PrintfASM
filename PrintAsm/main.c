extern int myPrintf (char* format, ...);

int main (void)
{
    // int res = myPrintf("%o\n%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b\n", -1, -1, "love", 3802, 100, 33, 127,
    //                                                                    -1, "love", 3802, 100, 33, 127);

        myPrintf ("binary number: %b, %o, %x\n", 11, 11, 11);
        // // return 0;

        myPrintf ("binary number: %b, %o, %x\n%d %s %x %d%%%c%b\n", 11, 11, 11, -1, "love", 3802, 100, 33, 126);

        myPrintf ("binary number: %b, %o, %x\n", 11, 11, 11);   
        
        myPrintf ("My name is %s and I'm %d years old\n", "Dedloh", 1000, 11);
        myPrintf ("My name is %s and I'm %d years old\n",              "Dedloh", 1000);
        myPrintf ("My name is %s and I'm %d years old\n",              "Dedloh", 1000);


    return 0;
}

// System V AMD64 ABI

// gcc -g -no-pie -Wl,-z,noexecstack main.o 0-Linux-nasm-64.o -o program

// TODO flushbuf
// TODO переполнение 