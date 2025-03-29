global myPrintf

;-----Start of constants--------------------------------------------------------

EOL          equ 00
BUFFER_LEN   equ 264
ADDRESS_SIZE equ 8

;-----End of constants----------------------------------------------------------

;----Start of checkOverflow macro-----------------------------------------------

%macro checkOverflow 0

        cmp rdi, buffer + BUFFER_LEN - 64 - 1
        jb %%noFlush

        call flushBuffer
%%noFlush:

%endmacro

;-----End of checkOverflow macro------------------------------------------------

;-----Start of multipush macro--------------------------------------------------

%macro  multipush 1-* 

        %rep  %0

        push    %1

        %rotate 1

        %endrep 

%endmacro

;-----End of multipush macro----------------------------------------------------

section .bss

buffer      resb BUFFER_LEN

section .data

hexTable    db '0123456789ABCDEF'

section .text

;-------------------------------------------------------------------------------
;
; [Brief]: printf cover for C language.
;
; [Expects]: rdi - format string, 
;            args: rsi, rdx, rcx, r8, r9,
;            stack (cdecl).        
;
;-------------------------------------------------------------------------------

;-----start of myPrintf label--------------------------------------------------

myPrintf:    
            pop r10                 ; save return address

            multipush r9, r8, rcx, rdx, rsi, rdi

            push r10                ; put return address

            push rbp                ;
            mov  rbp, rsp           ; stack frame prologue

            call myPrintfImpl          

            pop rbp                 ; stack frame epilogue

            pop r10                 ; pop old address

            add rsp, 6 * 8          ; balance the stack

            push r10                ; push return address 

            ret

;-----end of myPrintfC label----------------------------------------------------

;-------------------------------------------------------------------------------
;
; [Brief]: printf implementation
;
; [Expects]: rdi - format string, 
;            args: rsi, rdx, rcx, r8, r9,
;            stack (cdecl). 
;
; [Example]: 
;            | n'th argument  | <- rbp + 16 + 8n
;            |      ...       |
;            | 2nd argument   | <- rbp + 24
;            | 1nd argument   | <- rbp + 16
;            | return address | <- rbp + 8
;            | saved rbp      | <- rbp
;
; [Save]:    rsi, rdi, rbx, rbp 
;
;-------------------------------------------------------------------------------

;-----start of myPrintf label---------------------------------------------------
myPrintfImpl:
            mov rsi, [rbp + 16]     ; format string 

            mov rdi, buffer         ; buffer 

            mov rbx, 0              ; argument counter

.processFormatString:
            xor rax, rax            ; clean rax

            lodsb

            cmp al, EOL

            je .endProcessing

            cmp al, '%'

            je .conversionSpecifier

            mov [rdi], al           ; copy char to buffer 
            inc rdi                 ; shift buffer address

            checkOverflow           ; проверка на переполнение буфера

            jmp .processFormatString           ; proceed to next char

.conversionSpecifier:

            xor rax, rax            ; clean rax

            lodsb                   ; load next symbol                   

            cmp al, '%'             ; case '%'
            je .printPercent

            cmp al, 'x'             ; sym > x
            ja .invalidSpecifier

            cmp al, 'b'             ; sym < b
            jb .invalidSpecifier     ; TODO: error handling and put rax 

            jmp [.specifierHandlers + (rax - 'b') * ADDRESS_SIZE]                ; jump

;-------------------------------------------------------------------------------
;
; Jump table for symbols: b, c, d, o, s, x.
;
;-------------------------------------------------------------------------------

;-----Start of jump table-------------------------------------------------------

.specifierHandlers:

                                  dq .handleBinary             ; case 'b'
                                  dq .handleChar             ; case 'c'
                                  dq .handleDecimal             ; case 'd'

            times ('o' - 'd' - 1) dq .invalidSpecifier      
                                                            
                                  dq .handleOctal             ; case 'o'              
                                                             
            times ('s' - 'o' - 1) dq .invalidSpecifier           
                                                            
                                  dq .handleString             ; case 's'              
                                                            
            times ('x' - 's' - 1) dq .invalidSpecifier           

                                  dq .handleHex             ; case 'x'

;-----End of jump table---------------------------------------------------------

;-----Start of case 'c'---------------------------------------------------------

.handleChar:
            inc rbx

            mov al, [rbp + 16 + ADDRESS_SIZE * rbx]

            stosb 

            checkOverflow

            jmp .processFormatString

;-----End of case 'c'-----------------------------------------------------------

;-----Start of case 's'---------------------------------------------------------

.handleString:

            inc rbx

            push rsi                ; save rsi

            mov rsi, [rbp + 16 + ADDRESS_SIZE * rbx]

            call copyStringToBuffer

            pop rsi                 ; get rsi

            jmp .processFormatString

;-----End of case 's'-----------------------------------------------------------

;-----Start of case 'd'---------------------------------------------------------

.handleDecimal:

;-----End of case 'd'-----------------------------------------------------------

            call printDecimalNumber
            jmp .processFormatString

;-----Start of case 'b'---------------------------------------------------------

.handleBinary:

            mov cl, 1
            call printNumBase2n
            jmp .processFormatString 

;-----End of case 'b'-----------------------------------------------------------

;-----Start of case 'o'---------------------------------------------------------

.handleOctal:

            mov cl, 3
            call printNumBase2n
            jmp .processFormatString

;-----End of case 'o'-----------------------------------------------------------

;-----Start of case 'x'---------------------------------------------------------

.handleHex:

            mov cl, 4
            call printNumBase2n
            jmp .processFormatString 

;-----End of case 'x'-----------------------------------------------------------

.invalidSpecifier:

            mov byte [rdi], '%'
            inc rdi

            checkOverflow           ; проверка на переполнение буфера

            jmp .processFormatString

.printPercent:

            stosb

            checkOverflow           ; проверка на переполнение буфера

            jmp .processFormatString

.endProcessing:

            call flushBuffer

            xor rax, rax            ; rdi - return value 0
            ret

;-----End of myPrintf label-----------------------------------------------------

;-------------------------------------------------------------------------------
;
; [Brief]: Copies from src to dest
;
; [Expects]: rdi - dest
;            rsi - src
;
;           
;           
; [Destroy]: al
;
; [Save]:    rsi, rdi, rbx, rbp 
;
;-------------------------------------------------------------------------------

;-----Start of copy2Buffer label------------------------------------------------

copyStringToBuffer:

.copyByte:

            checkOverflow

            lodsb
            cmp al, EOL

            je .end

            stosb

            jmp .copyByte

.end:

            ret

;-----End of copy2Buffer label--------------------------------------------------

;-------------------------------------------------------------------------------
;
; [Brief]: Print number of base 2^n (n = 1, 3, 4)
;
; [Expects]: rdi - format string,
;            rbx - argument count
;             cl - base
;
; [Sets]:
;            r8  - bit mask
;            rdx - value 
;           
;           
; [Destroy]: rax, rdx, rcx
;
; [Save]:    rsi, rdi, rbx, rbp 
;
;-------------------------------------------------------------------------------

;-----Start of printNumBase2n label---------------------------------------------

printNumBase2n:
    inc rbx

    mov rdx, [rbp + 16 + 8 * rbx]  
    
    
    push rdi                 ; сохраняем текущую позицию в буфере
    
    ; Пропускаем место для числа
    call countBytesNumBase2n
    add rdi, rax               
    mov byte [rdi], ' '      ; добавляем пробел после числа
    push rax                 ; сохраняем размер числа
    
    ; Печатаем число справа налево
    mov r8, 01b              
    shl r8, cl
    dec r8
    
.isNegative:
    test edx, edx
    jns .printDigits
    mov al, '-'
    stosb
    neg edx

.printDigits:
    mov rax, r8
    and rax, rdx
    shr edx, cl
    mov al, [hexTable + rax]
    mov [rdi], al
    dec rdi
    test edx, edx
    jne .printDigits
    
    ; Восстанавливаем позицию в буфере
    pop rax
    pop rdi
    add rdi, rax
    inc rdi                  ; пропускаем добавленный пробел
    
    checkOverflow
    
    ret

;-----End of printNumBase2n label-----------------------------------------------

;-------------------------------------------------------------------------------
;
; [Brief]: Print number of base 10
;
; [Expects]: rdi - format string,
;            rbx - argument count
;
; [Sets]:
;            r8 - value
;            r9 - counts bytes need to print
;            r10 - quotient
;           
;           
; [Destroy]: rax, rdx
;
; [Save]:    rsi, rdi, rbx, rbp 
;
;-------------------------------------------------------------------------------

;-----Start of printNumBase10 label---------------------------------------------

printDecimalNumber:

            inc rbx

            mov r8, [rbp + 16 + 8 * rbx]

.isNegative:
            mov rdx, r8
            
            test edx, edx
            jns .continue

            mov al, '-'
            stosb

            neg edx
            mov r8, rdx
.continue:

            mov r10, 10 
            mov rax, r8
            xor r9, r9              ; for count bytes

.countBytesNumBase10:

            xor rdx, rdx
            inc r9
            div r10

            test eax, eax

            jne .countBytesNumBase10

            add rdi, r9

            mov rax, r8

.loop:
            checkOverflow

            xor rdx, rdx
            div r10

            add dl, '0'
            mov [rdi], dl
            dec rdi

            test eax, eax

            jne .loop

            add rdi, r9

            inc rdi

            ret

;-----End of printNumBase10 label-----------------------------------------------

;-------------------------------------------------------------------------------
;
; [Brief]: Count bytes need to print for a number of base 2^n (n = 1, 3, 4)
;
; [Expects]: rdx - value,
;            cl - base
;
; [Sets]:
;            r8 - value
;            r9 - counts bytes need to print
;            r10 - quotient
;           
;           
; [Destroy]: rax, rdx
;
; [Return];  ch - amount of bytes needed
;
; [Save]:    rsi, rdi, rbx, rbp 
;
;-------------------------------------------------------------------------------

;-----Start of countBytes label-------------------------------------------------

countBytesNumBase2n:                            ; TODO: use another buffer with string and then reverse

            xor rax, rax
            xor ch, ch
            mov rax, rdx

.loop:
            inc ch
            shr rax, cl

            test rax, rax
            jne .loop

            xor rax, rax

            mov al, ch

            ret

;-----End of countBytes label----------------------------------------------------

;-------------------------------------------------------------------------------
;
; [Brief]: Flushes the buffer
;
; [Expects]: rdi - address of last byte needed to be printed,
;            
;
; [Sets]:
;            rdi - back to the begining
;           
; [Destroy]: rax
;
; [Save]:    rsi, rdx
;
;-------------------------------------------------------------------------------

;-----Start of flushBuffer label------------------------------------------------

flushBuffer:
    push rsi
    push rdx
    push rdi
    
    ; Calculate length to write
    mov rdx, rdi
    sub rdx, buffer
    
    ; Skip if buffer is empty
    test rdx, rdx
    jz .end
    
    ; Write to stdout
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, buffer
    syscall
    
    ; Reset buffer position
.end:
    pop rdi
    mov rdi, buffer     ; reset buffer pointer
    pop rdx
    pop rsi
    ret

;-----End of flushBuffer lable--------------------------------------------------
; 
section .note.GNU-stack noalloc noexec nowrite progbits