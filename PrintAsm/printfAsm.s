global main
 
 extern sum
 
 extern printf
 
 section .text
 
 main:   push rbp
         mov rbp, rsp
 
         mov rdi, 1
         mov rsi, 2
 
         call sum
 
         mov rdi, str
         mov rsi, arg
         mov rdx, '!'
 
         call printf WRT ..plt
 
         pop rbp
         mov rax, 0
 
         ret
 
 section .data
 
 str:    db 'Hll %s, %c', 0x0a, 0
 arg:    db 'wrld', 0

section .note.GNU-stack noalloc noexec nowrite progbits