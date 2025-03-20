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
            pop r10                 ; ��������� ����� ��������

            push r9                 ; 
            push r8                 ;
            push rcx                ; ��������� ���������
            push rdx                ;
            push rsi                ;
            push rdi                ;

            push r10                ; ������ ����� �������� �������

            push rbp                
            mov  rbp, rsp            

            call myPrintfImpl       

            pop rbp                 ; ������ �����

            pop r10                 ; ������� ������ ����� ��������

            add rsp, 6 * 8          ; ����������� ����

            push r10                ; ������ ����� �������� �������

            ret

;-----����� ������� myPrintf----------------------------------------------------

;-------------------------------------------------------------------------------
;
; [Brief]: ���������� printf
;
; [Expects]: 
;   - rdi: ������ ������� (��������, "Hello, %s! %d").
;   - rsi, rdx, rcx, r8, r9: ������ ���� ����������.
;   - ��������� ��������� ���������� ����� ���� (���������� cdecl).    
;
; [Example of the arrangement of arguments on the stack]:
;   | n-� ��������    | <- rbp + 16 + 8n
;   |      ...        |
;   | 2-� ��������    | <- rbp + 24
;   | 1-� ��������    | <- rbp + 16
;   | ����� ��������  | <- rbp + 8
;   | ����������� rbp | <- rbp
;
;  [Save]: rsi, rdi, rbx, rbp.
;   TODO �������� �������� �� ������������ ������
;-------------------------------------------------------------------------------

myPrintfImpl:
            mov rsi, [rbp + 16]     ; ������ ������� 

            mov rdi, buffer         ; ����� 

            mov rbx, 0              ; ������� ����������

.mainLoop:
            xor rax, rax            ; ������� rax

            lodsb                   ; ��������� ��������� ������

            cmp al, EOL             ; �������� �� ����� ������
            je .end

            cmp al, '%'             
            je .conversionSpecifier 

            mov [rdi], al           ; �������� ������ � ����� 
            inc  rdi                ; �������� ����� ������

            jmp .mainLoop           ; ��������� � ���������� �������

.conversionSpecifier:

            xor rax, rax            ; ������� rax

            lodsb                   ; ��������� ��������� ������                   

            cmp al, '%'             ; ������ '%'
            je .symbolPercent

            cmp al, 'x'             ; ������ > x
            ja .differentSymbol

            cmp al, 'b'             ; ������ < b
            jb .differentSymbol     

            sub al, 'b'             ; �������� ����� ������

            mov rax, [.formatSpecifiers + rax * 8]
            jmp rax                 ; �������

;-------------------------------------------------------------------------------
;
; ������� ��������� ��� ��������: b, c, d, o, s, x.
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
; ��������� ������������� '%c' 
;-------------------------------------------------------------------------------

.symbolC:
            inc rbx

            mov al, [rbp + 16 + 8 * rbx]

            stosb

            jmp .mainLoop
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; ��������� ������������� '%s' 
;-------------------------------------------------------------------------------

.symbolS:

            inc rbx

            push rsi                ; ��������� rsi

            mov rsi, [rbp + 16 + 8 * rbx]

            call copy2Buffer

            pop rsi                 ; ��������������� rsi

            jmp .mainLoop
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; ��������� ������������� '%d' 
;-------------------------------------------------------------------------------

.symbolD:

            call printNumBase10
            jmp .mainLoop
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; ��������� ������������� '%b' 
;-------------------------------------------------------------------------------

.symbolB:

            mov cl, 1
            call printNumBase2n
            jmp .mainLoop 
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; ��������� ������������� '%o' 
;-------------------------------------------------------------------------------

.symbolO:

            mov cl, 3
            call printNumBase2n
            jmp .mainLoop
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; ��������� ������������� '%x' 
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

            xor rax, rax            ; rdi - ������������ �������� 0
            ret

copy2Buffer:

.copyByte:

            ; �������� �� ������������ ������
            lodsb
            cmp al, EOL

            je .end

            stosb

            jmp .copyByte

.end:

            ret

printNumBase2n:

            inc rbx                 ; ����������� ������� ����������

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

            push rbx               ; ��������� rbx

.isNegative:

            mov ebx, 10 
            mov eax, edx

            test edx, edx           ; �������� �� ����
            jns .loop

            mov al, '-'             ; ������ '-'
            stosb

            mov eax, edx                  

            neg eax                 ; ������ ����� �����������


.loop:

            xor edx, edx            ; ������� rdx 
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

; rdx - ��������, cl - ���������, ��������� - ch
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

            sub rdi, buffer         ; '\n' �����������
            mov rdx, rdi

            mov rax, 0x01           ; ��������� ����� write ()
            mov rdi, 1
            mov rsi, buffer
            syscall

            pop rdx
            pop rsi

            mov rdi, buffer         ; ���������� �����

            ret

section .note.GNU-stack noalloc noexec nowrite progbits