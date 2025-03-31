extern "C" int myPrintf (const char* format, ...);

int main (void)
{                                                     
        myPrintf ("binary number: %b, %o, %x\n", 11, 11, 11);

        myPrintf ("binary number: %b, %o, %x\n%d %s %x %d%%%c%b\n", 11, 11, 11, -1, "love", 3802, 100, 33, 126);

        myPrintf ("binary number: %b, %o, %x\n", 11, 11, 11);   
        
        myPrintf ("My name is %s and I'm %d years old\n", "Dedloh", 1000);

    return 0;
}

// System V AMD64 ABI
