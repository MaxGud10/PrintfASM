EOL        equ 00
BUFFER_LEN equ 256

global myPrintf

section .bss

buffer      resb BUFFER_LEN

%macro checkOverflow 0

        cmp rdi, buffer + BUFFER_LEN - 64 - 1  ; проверяем, не достиг ли указатель буфера предела
        jb %%noFlush                           ; если нет, пропускаем flush

        call flushBuffer                       ; иначе вызываем flushBuffer
%%noFlush:

%endmacro

section .data

hexTable    db '0123456789ABCDEF'

section .text

;-------------------------------------------------------------------------------
;
; [Function]: myPrintf
;
; [Description]:
;   реализация функции, аналогичной printf из стандартной библиотеки C.
;   поддерживает форматированный вывод с использованием спецификаторов:
;   %c, %s, %d, %b, %o, %x. функция обрабатывает строку формата и выводит
;   данные в стандартный вывод (stdout) с использованием буфера.
;
; [Arguments]:
;   - rdi: указатель на строку формата (format string).
;          строка формата может содержать обычные символы и спецификаторы:
;          %c (символ), %s (строка), %d (десятичное число),
;          %b (двоичное число), %o (восьмеричное число), %x (шестнадцатеричное число).
;   - rsi, rdx, rcx, r8, r9: первые пять аргументов, соответствующие спецификаторам.
;   - остальные аргументы передаются через стек (соглашение cdecl).
;
; [Stack Layout]:
;   | n-й аргумент    | <- rbp + 16 + 8n
;   |      ...        |
;   | 2-й аргумент    | <- rbp + 24
;   | 1-й аргумент    | <- rbp + 16
;   | адрес возврата  | <- rbp + 8
;   | сохраненный rbp | <- rbp
;  
; [Registers Usage]:
;   - rdi: указатель на строку формата.
;   - rsi: указатель на текущий символ строки формата.
;   - rbx: счетчик аргументов.
;   - rbp: указатель на стековый фрейм.
;   - r10: временное хранение адреса возврата.
;
; [Save]: rsi, rdi, rbx, rbp.
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

            add rsp, 6 * 8          ; балансируем стек (удаляем 6 аргументов (6 * 8 байт))

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
;   - остальные аргументы передаются через стек (соглашение cdecl).    
;
; [Example of the arrangement of arguments on the stack]:
;   | n-й аргумент    | <- rbp + 16 + 8n
;   |      ...        |
;   | 2-й аргумент    | <- rbp + 24
;   | 1-й аргумент    | <- rbp + 16
;   | адрес возврата  | <- rbp + 8
;   | сохраненный rbp | <- rbp
;
; [Save]: rsi, rdi, rbx, rbp.
;-------------------------------------------------------------------------------

myPrintfImpl:
            mov rsi, [rbp + 16]     ; строка формата 

            mov rdi, buffer         ; буфер 

            mov rbx, 0              ; счетчик аргументов

.processFormatString:
            xor rax, rax            ; очищаем rax

            lodsb                   ; загружаем следующий символ

            cmp al, EOL             ; проверка на конец строки
            je endProcessing

            cmp al, '%'             
            je .conversionSpecifier 

            mov [rdi], al           ; копируем символ в буфер 
            inc  rdi                ; сдвигаем адрес буфера

            checkOverflow           ; проверка на переполнение буфера

            jmp .processFormatString           ; переходим к следующему символу

.conversionSpecifier:

            xor rax, rax            ; очищаем rax

            lodsb                   ; загружаем следующий символ                   

            cmp al, '%'             ; случай '%'
            je .printPercent

            cmp al, 'x'             ; символ > x
            ja .invalidSpecifier

            cmp al, 'b'             ; символ < b
            jb .invalidSpecifier     

            ; jmp rax, [.specifierHandlers + rax * 8 ] 

            ;sub al, 'b'             ; получаем номер адреса

            ;mov rax, [.specifierHandlers + rax * 8]  
            jmp [.specifierHandlers + (rax - 'b') * 8]              

;-------------------------------------------------------------------------------
;
; Таблица переходов для обработки спецификаторов:
;   - %b: двоичное число
;   - %c: символ
;   - %d: десятичное число
;   - %o: восьмеричное число
;   - %s: строка
;   - %x: шестнадцатеричное число
;
;-------------------------------------------------------------------------------

.specifierHandlers:

            dq .handleBinary             ; case 'b'
            dq .handleChar               ; case 'c'
            dq .handleDecimal            ; case 'd'

            times ('n' - 'd') dq .invalidSpecifier           
                                                            
            dq .handleOctal              ; case 'o'              
                                                             
            times ('r' - 'o') dq .invalidSpecifier           
                                                            
            dq .handleString             ; case 's'              
                                                            
            times ('w' - 's') dq .invalidSpecifier           

            dq .handleHex                  ; case 'x'
;------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; обработка спецификатора '%c' 
;-------------------------------------------------------------------------------

.handleChar:
            inc rbx

            mov al, [rbp + 16 + 8 * rbx]

            stosb

            checkOverflow           ; проверка на переполнение буфера

            jmp .processFormatString
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; обработка спецификатора '%s' 
;-------------------------------------------------------------------------------

.handleString:

            inc rbx

            push rsi                ; сохраняем rsi

            mov rsi, [rbp + 16 + 8 * rbx]

            call copyStringToBuffer

            pop rsi                 ; восстанавливаем rsi

            jmp .processFormatString
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; обработка спецификатора '%d' 
;-------------------------------------------------------------------------------

.handleDecimal:

            call printDecimalNumber
            jmp .processFormatString
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; обработка спецификатора '%b' 
;-------------------------------------------------------------------------------

.handleBinary:

            mov cl, 1
            call printNumBase2n
            jmp .processFormatString 
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; обработка спецификатора '%o' 
;-------------------------------------------------------------------------------

.handleOctal:

            mov cl, 3
            call printNumBase2n
            jmp .processFormatString
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; обработка спецификатора '%x' 
;-------------------------------------------------------------------------------

.handleHex:

            mov cl, 4
            call printNumBase2n
            jmp .processFormatString 
;-------------------------------------------------------------------------------

.invalidSpecifier:

            mov byte [rdi], '%'
            inc rdi

            checkOverflow           ; проверка на переполнение буфера

            jmp .processFormatString

.printPercent:

            stosb

            checkOverflow           ; проверка на переполнение буфера

            jmp .processFormatString

endProcessing:
            call flushBuffer

            xor rax, rax            ; rdi - возвращаемое значение 0
            ret

copyStringToBuffer:

.copyByte:

            checkOverflow           ; проверка на переполнение буфера

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
            jns .printDigits
            
            mov al, '-'
            stosb

            neg edx

.printDigits:

            checkOverflow           ; проверка на переполнение буфера

            mov rax, r8
            and rax, rdx

            shr edx, cl

            mov al, [hexTable + rax]  
            mov [rdi], al
            dec di

            test edx, edx

            jne .printDigits

            pop rax

            add rdi, rax

            inc rdi

            ret

printDecimalNumber:

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
            jns .printDigits

            mov al, '-'             ; символ '-'
            stosb

            mov eax, edx                  

            neg eax                 ; делаем число беззнаковым


.printDigits:

            checkOverflow           ; проверка на переполнение буфера

            xor edx, edx            ; очищаем rdx 
            div ebx

            add dl, '0'
            mov [rdi], dl
            dec rdi

            test eax, eax

            jne .printDigits

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

.countLoop:
            inc ch
            shr rax, cl

            test rax, rax
            jne .countLoop

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