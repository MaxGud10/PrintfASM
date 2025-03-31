section .text
global myPrintf

;-----Macros-------------------------------------------------------------------
%macro checkOverflow 0
        cmp rdi, buffer + BUFFER_LEN - 64 - 1

        jb %%noFlush

        call flushBuffer

        test rax, rax
        jnz myPrintfImpl.endWithError
%%noFlush:
%endmacro

%macro multipush 1-* 

        %rep %0

        push %1

        %rotate 1
        
        %endrep 
%endmacro

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

                xor rbx, rbx            ; argument counter

                xor r11, r11            ; init byte counter

.processFormatString:

                lodsb

                test al, al
                jz .endProcessing       ; end if null terminator

                cmp al, '%'
                je .conversionSpecifier ; handle format specifier

                stosb
                inc r11

                checkOverflow

                jmp .processFormatString

.conversionSpecifier:

                lodsb

                cmp al, '%'
                je .handlePercent

                cmp al, 'b'
                jb .invalidSpecifier

                cmp al, 'x'
                ja .invalidSpecifier

                ; use jump table to handle specifier
                movzx rdx, al
                sub rdx, 'b'
                imul rdx, ADDRESS_SIZE
                mov rcx, [specifierHandlers + rdx]
                jmp rcx

.invalidSpecifier:
                mov byte [rdi], '%'

                inc rdi
                inc r11

                checkOverflow
                
                jmp .processFormatString

.endProcessing:

                call flushBuffer

                test rax, rax
                jnz .endWithError

                mov rax, r11
                ret

.endWithError:
                mov rax, ERROR

                ret

;-----handlers (global labels)-------------------------------------------
.handlePercent:

                stosb

                inc r11

                checkOverflow

                jmp .processFormatString

handleChar:
                inc rbx

                mov rax, rbx
                imul rax, ADDRESS_SIZE
                mov al, [rbp + 16 + rax]

                stosb 

                inc r11

                checkOverflow

                jmp myPrintfImpl.processFormatString

handleString:
                inc rbx
                push rsi
                mov rax, rbx
                imul rax, ADDRESS_SIZE
                mov rsi, [rbp + 16 + rax]

                call copyStringToBuffer

                pop rsi

                jmp myPrintfImpl.processFormatString

handleDecimal:

                call printDecimalNumber
                jmp myPrintfImpl.processFormatString

handleBinary:

                mov cl, 1
                call printNumBase2n
                jmp myPrintfImpl.processFormatString

handleOctal:

                mov cl, 3
                call printNumBase2n
                jmp myPrintfImpl.processFormatString

handleHex:

                mov cl, 4
                call printNumBase2n
                jmp myPrintfImpl.processFormatString

;-----helper functions-------------------------------------------------
copyStringToBuffer:

.copyByte:

                checkOverflow

                lodsb

                test al, al
                jz .end

                stosb

                inc r11
                jmp .copyByte

.end:
                ret

flushBuffer:

                push rsi
                push rdx
                push rdi
                
                mov rdx, rdi
                sub rdx, buffer
                jz .success            ; nothing to flush
                
                mov rax, 1             ; sys_write
                mov rdi, 1             ; stdout
                mov rsi, buffer
                syscall
                
                cmp rax, 0
                jl .error
        
.success:

                mov rdi, buffer        ; reset buffer pointer
                xor rax, rax
                jmp .end
        
.error:

                mov rax, ERROR
        
.end:

                pop rdi
                pop rdx
                pop rsi
                ret

printNumBase2n:

                ; print number in base 2^n (binary/octal/hex)
                inc rbx
                mov rdx, [rbp + 16 + 8 * rbx]  
                push rdi       

                call countBytesNumBase2n

                add rdi, rax               
                mov byte [rdi], ' '

                push rax          

                mov r8, 01b              
                shl r8, cl
                dec r8

.isNegative:

                test edx, edx
                jns .printDigits

                mov al, '-'

                stosb

                inc r11
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

                pop rax
                pop rdi
                add rdi, rax
                inc rdi                 
                add r11, rax            
                inc r11            

                checkOverflow

                ret

printDecimalNumber:

                inc rbx
                mov r8, [rbp + 16 + 8 * rbx]

.isNegative:

                mov rdx, r8
                test edx, edx
                jns .continue

                mov al, '-'
                stosb
                inc r11
                neg edx
                mov r8, rdx
.continue:

                mov r10, 10 
                mov rax, r8
                xor r9, r9

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
                add r11, r9         
                ret

countBytesNumBase2n:       

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

;-----Data sections at the end--------------------------------------------------
section .rodata
hexTable    db '0123456789ABCDEF'

;-------------------------------------------------------------------------------
;
; Jump table for symbols: b, c, d, o, s, x.
;
;-------------------------------------------------------------------------------

specifierHandlers:
                                  dq handleBinary                   ; case 'b'
                                  dq handleChar                     ; case 'c'
                                  dq handleDecimal                  ; case 'd'
            times ('o' - 'd' - 1) dq myPrintfImpl.invalidSpecifier      
                                  dq handleOctal                    ; case 'o'              
            times ('s' - 'o' - 1) dq myPrintfImpl.invalidSpecifier           
                                  dq handleString                   ; case 's'              
            times ('x' - 's' - 1) dq myPrintfImpl.invalidSpecifier           
                                  dq handleHex                      ; case 'x'

;-----Start of constants--------------------------------------------------------
EOL          equ 00
BUFFER_LEN   equ 1024
ADDRESS_SIZE equ 8
SUCCESS      equ 0
ERROR        equ -1
;-----End of constants----------------------------------------------------------

section .bss
buffer      resb BUFFER_LEN                                         ; output buffer

section .note.GNU-stack noalloc noexec nowrite progbits