EOL        equ 00
BUFFER_LEN equ 256

global myPrintf

section .bss

buffer      resb BUFFER_LEN

%macro checkOverflow 0

        cmp rdi, buffer + BUFFER_LEN - 64 - 1  ; ���������, �� ������ �� ��������� ������ �������
        jb %%noFlush                           ; ���� ���, ���������� flush

        call flushBuffer                       ; ����� �������� flushBuffer
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
;   ���������� �������, ����������� printf �� ����������� ���������� C.
;   ������������ ��������������� ����� � �������������� ��������������:
;   %c, %s, %d, %b, %o, %x. ������� ������������ ������ ������� � �������
;   ������ � ����������� ����� (stdout) � �������������� ������.
;
; [Arguments]:
;   - rdi: ��������� �� ������ ������� (format string).
;          ������ ������� ����� ��������� ������� ������� � �������������:
;          %c (������), %s (������), %d (���������� �����),
;          %b (�������� �����), %o (������������ �����), %x (����������������� �����).
;   - rsi, rdx, rcx, r8, r9: ������ ���� ����������, ��������������� ��������������.
;   - ��������� ��������� ���������� ����� ���� (���������� cdecl).
;
; [Stack Layout]:
;   | n-� ��������    | <- rbp + 16 + 8n
;   |      ...        |
;   | 2-� ��������    | <- rbp + 24
;   | 1-� ��������    | <- rbp + 16
;   | ����� ��������  | <- rbp + 8
;   | ����������� rbp | <- rbp
;  
; [Registers Usage]:
;   - rdi: ��������� �� ������ �������.
;   - rsi: ��������� �� ������� ������ ������ �������.
;   - rbx: ������� ����������.
;   - rbp: ��������� �� �������� �����.
;   - r10: ��������� �������� ������ ��������.
;
; [Save]: rsi, rdi, rbx, rbp.
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

            add rsp, 6 * 8          ; ����������� ���� (������� 6 ���������� (6 * 8 ����))

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
; [Save]: rsi, rdi, rbx, rbp.
;-------------------------------------------------------------------------------

myPrintfImpl:
            mov rsi, [rbp + 16]     ; ������ ������� 

            mov rdi, buffer         ; ����� 

            mov rbx, 0              ; ������� ����������

.processFormatString:
            xor rax, rax            ; ������� rax

            lodsb                   ; ��������� ��������� ������

            cmp al, EOL             ; �������� �� ����� ������
            je endProcessing

            cmp al, '%'             
            je .conversionSpecifier 

            mov [rdi], al           ; �������� ������ � ����� 
            inc  rdi                ; �������� ����� ������

            checkOverflow           ; �������� �� ������������ ������

            jmp .processFormatString           ; ��������� � ���������� �������

.conversionSpecifier:

            xor rax, rax            ; ������� rax

            lodsb                   ; ��������� ��������� ������                   

            cmp al, '%'             ; ������ '%'
            je .printPercent

            cmp al, 'x'             ; ������ > x
            ja .invalidSpecifier

            cmp al, 'b'             ; ������ < b
            jb .invalidSpecifier     

            ; jmp rax, [.specifierHandlers + rax * 8 ] 

            ;sub al, 'b'             ; �������� ����� ������

            ;mov rax, [.specifierHandlers + rax * 8]  
            jmp [.specifierHandlers + (rax - 'b') * 8]              

;-------------------------------------------------------------------------------
;
; ������� ��������� ��� ��������� ��������������:
;   - %b: �������� �����
;   - %c: ������
;   - %d: ���������� �����
;   - %o: ������������ �����
;   - %s: ������
;   - %x: ����������������� �����
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
; ��������� ������������� '%c' 
;-------------------------------------------------------------------------------

.handleChar:
            inc rbx

            mov al, [rbp + 16 + 8 * rbx]

            stosb

            checkOverflow           ; �������� �� ������������ ������

            jmp .processFormatString
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; ��������� ������������� '%s' 
;-------------------------------------------------------------------------------

.handleString:

            inc rbx

            push rsi                ; ��������� rsi

            mov rsi, [rbp + 16 + 8 * rbx]

            call copyStringToBuffer

            pop rsi                 ; ��������������� rsi

            jmp .processFormatString
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; ��������� ������������� '%d' 
;-------------------------------------------------------------------------------

.handleDecimal:

            call printDecimalNumber
            jmp .processFormatString
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; ��������� ������������� '%b' 
;-------------------------------------------------------------------------------

.handleBinary:

            mov cl, 1
            call printNumBase2n
            jmp .processFormatString 
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; ��������� ������������� '%o' 
;-------------------------------------------------------------------------------

.handleOctal:

            mov cl, 3
            call printNumBase2n
            jmp .processFormatString
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; ��������� ������������� '%x' 
;-------------------------------------------------------------------------------

.handleHex:

            mov cl, 4
            call printNumBase2n
            jmp .processFormatString 
;-------------------------------------------------------------------------------

.invalidSpecifier:

            mov byte [rdi], '%'
            inc rdi

            checkOverflow           ; �������� �� ������������ ������

            jmp .processFormatString

.printPercent:

            stosb

            checkOverflow           ; �������� �� ������������ ������

            jmp .processFormatString

endProcessing:
            call flushBuffer

            xor rax, rax            ; rdi - ������������ �������� 0
            ret

copyStringToBuffer:

.copyByte:

            checkOverflow           ; �������� �� ������������ ������

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
            jns .printDigits
            
            mov al, '-'
            stosb

            neg edx

.printDigits:

            checkOverflow           ; �������� �� ������������ ������

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

            push rbx               ; ��������� rbx

.isNegative:

            mov ebx, 10 
            mov eax, edx

            test edx, edx           ; �������� �� ����
            jns .printDigits

            mov al, '-'             ; ������ '-'
            stosb

            mov eax, edx                  

            neg eax                 ; ������ ����� �����������


.printDigits:

            checkOverflow           ; �������� �� ������������ ������

            xor edx, edx            ; ������� rdx 
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

; rdx - ��������, cl - ���������, ��������� - ch
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