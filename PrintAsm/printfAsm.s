EOL equ 00
BUFFER_LEN equ 256

global myPrintf

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

myPrintf:    
            pop r10                 ; сохраняем адрес возврата

            push r9                 ; 
            push r8                 ;
            push rcx                ; сохраняем аргументы
            push rdx                ;
            push rsi                ;
            push rdi                ;

            push r10                ; кладем адрес возврата обратно

            push rbp                
            mov  rbp, rsp            

            call myPrintfImpl       

            pop rbp                 ; эпилог стека

            pop r10                 ; достаем старый адрес возврата

            add rsp, 6 * 8          ; балансируем стек

            push r10                ; кладем адрес возврата обратно

            ret

;-----конец функции myPrintf----------------------------------------------------

;-------------------------------------------------------------------------------
;
; [Brief]: реализация printf
;
; [Expects]: 
;   - rdi: строка формата (например, "Hello, %s! %d").
;   - rsi, rdx, rcx, r8, r9: первые пять аргументов.
;   - Остальные аргументы передаются через стек (соглашение cdecl).    
;
; [Example of the arrangement of arguments on the stack]:
;   | n-й аргумент    | <- rbp + 16 + 8n
;   |      ...        |
;   | 2-й аргумент    | <- rbp + 24
;   | 1-й аргумент    | <- rbp + 16
;   | адрес возврата  | <- rbp + 8
;   | сохраненный rbp | <- rbp
;
;  [Save]: rsi, rdi, rbx, rbp.
;   TODO добавить проверку на переполнение буфера
;-------------------------------------------------------------------------------

myPrintfImpl:
            mov rsi, [rbp + 16]     ; строка формата 

            mov rdi, buffer         ; буфер 

            mov rbx, 0              ; счетчик аргументов

.mainLoop:
            xor rax, rax            ; очищаем rax

            lodsb                   ; загружаем следующий символ

            cmp al, EOL             ; проверка на конец строки
            je .end

            cmp al, '%'             
            je .conversionSpecifier 

            mov [rdi], al           ; копируем символ в буфер 
            inc  rdi                ; сдвигаем адрес буфера

            jmp .mainLoop           ; переходим к следующему символу

.conversionSpecifier:

            xor rax, rax            ; очищаем rax

            lodsb                   ; загружаем следующий символ                   

            cmp al, '%'             ; случай '%'
            je .symbolPercent

            cmp al, 'x'             ; символ > x
            ja .differentSymbol

            cmp al, 'b'             ; символ < b
            jb .differentSymbol     

            sub al, 'b'             ; получаем номер адреса

            mov rax, [.formatSpecifiers + rax * 8]
            jmp rax                 ; переход

;-------------------------------------------------------------------------------
;
; Таблица переходов для символов: b, c, d, o, s, x.
;
;-------------------------------------------------------------------------------

.formatSpecifiers:

            dq .symbolB             ; case 'b'
            dq .symbolC             ; case 'c'
            dq .symbolD             ; case 'd'

            times ('n' - 'd') dq .differentSymbol           
                                                            
            dq .symbolO             ; case 'o'              
                                                             
            times ('r' - 'o') dq .differentSymbol           
                                                            
            dq .symbolS             ; case 's'              
                                                            
            times ('w' - 's') dq .differentSymbol           

            dq .symbolX             ; case 'x'
;------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; обработка спецификатора '%c' 
;-------------------------------------------------------------------------------

.symbolC:
            inc rbx

            mov al, [rbp + 16 + 8 * rbx]

            stosb

            jmp .mainLoop
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; обработка спецификатора '%s' 
;-------------------------------------------------------------------------------

.symbolS:

            inc rbx

            push rsi                ; сохраняем rsi

            mov rsi, [rbp + 16 + 8 * rbx]

            call copy2Buffer

            pop rsi                 ; восстанавливаем rsi

            jmp .mainLoop
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; обработка спецификатора '%d' 
;-------------------------------------------------------------------------------

.symbolD:

            call printNumBase10
            jmp .mainLoop
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; обработка спецификатора '%b' 
;-------------------------------------------------------------------------------

.symbolB:

            mov cl, 1
            call printNumBase2n
            jmp .mainLoop 
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; обработка спецификатора '%o' 
;-------------------------------------------------------------------------------

.symbolO:

            mov cl, 3
            call printNumBase2n
            jmp .mainLoop
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; обработка спецификатора '%x' 
;-------------------------------------------------------------------------------

.symbolX:

            mov cl, 4
            call printNumBase2n
            jmp .mainLoop 
;-------------------------------------------------------------------------------

.differentSymbol:

            mov byte [rdi], '%'
            inc rdi

            jmp .mainLoop

.symbolPercent:

            stosb

            jmp .mainLoop

.end:

            call flushBuffer

            xor rax, rax            ; rdi - возвращаемое значение 0
            ret

copy2Buffer:

.copyByte:

            ; проверка на переполнение буфера
            lodsb
            cmp al, EOL

            je .end

            stosb

            jmp .copyByte

.end:

            ret

printNumBase2n:

            inc rbx                 ; увеличиваем счетчик аргументов

            mov rdx, [rbp + 16 + 8 * rbx]

            call countBytes
            
            add rdi, rax

            mov byte [rdi], EOL
            dec rdi

            push rax

            mov r8, 01b
            shl r8, cl
            dec r8

.isNegative:

            test edx, edx
            jns .loop
            
            mov al, '-'
            stosb

            neg edx

.loop:

            mov rax, r8
            and rax, rdx

            shr edx, cl

            mov al, [hexTable + rax]  
            mov [rdi], al
            dec di

            test edx, edx

            jne .loop

            pop rax

            add rdi, rax

            inc rdi

            ret

printNumBase10:

            inc rbx

            mov rdx, [rbp + 16 + 8 * rbx]

            call countBytes

            add rdi, rax

            mov byte [rdi], EOL

            push rax

            push rbx               ; сохраняем rbx

.isNegative:

            mov ebx, 10 
            mov eax, edx

            test edx, edx           ; проверка на знак
            jns .loop

            mov al, '-'             ; символ '-'
            stosb

            mov eax, edx                  

            neg eax                 ; делаем число беззнаковым


.loop:

            xor edx, edx            ; очищаем rdx 
            div ebx

            add dl, '0'
            mov [rdi], dl
            dec rdi

            test eax, eax

            jne .loop

            pop rbx

            pop rax

            add rdi, rax

            inc rdi
            inc rdi

            ret

; rdx - значение, cl - основание, результат - ch
countBytes:

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


flushBuffer:
            push rsi
            push rdx

            sub rdi, buffer         ; '\n' добавляется
            mov rdx, rdi

            mov rax, 0x01           ; системный вызов write ()
            mov rdi, 1
            mov rsi, buffer
            syscall

            pop rdx
            pop rsi

            mov rdi, buffer         ; сбрасываем буфер

            ret

section .note.GNU-stack noalloc noexec nowrite progbits