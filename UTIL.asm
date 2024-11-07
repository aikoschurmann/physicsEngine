; -------------------------------------------------------------------
; 80386
; 32-bit x86 assembly language
; TASM
;
; author:	Stijn Bettens, David Blinder
; date:		25/09/2017
; program:	Hello World!
; -------------------------------------------------------------------

IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
CODESEG

; uses eax as input
PUBLIC printSignedNumber
PROC printSignedNumber
    ARG @@number:dword
	USES eax, ebx, ecx, edx
    
    mov eax, [@@number] ; eax holds input integer
    test eax, eax       ; Check for sign
    jns @@skipSign      ; If the sign is not set, skip the '-' sign.
    ;push needed because ah is used for printing
    push eax            ; Save the number on the stack
    mov ah, 2h          ; Print '-' if the sign is set.
    mov dl, '-'         ; dl stores the character to print
    int 21h             ; inerupt for printing a character
    pop eax             ; Restore the number from the stack
    neg eax             ; negate eax

@@skipSign:
    mov ebx, 10         ; divider
    xor ecx, ecx        ; reset counter for digits to be printed (used by loop)

@@getNextDigit:
    ;loop decrements ecx until it reaches 0 
    ;later used for eg. printing digits
    inc ecx
    ; DIV uses EDX:EAX as input and output (64-bit dividend)
    ; We often divide 32-bit numbers, so we need to clear EDX first
    ; EDX is the high 32 bits of the dividend (64-bit number)
    xor edx, edx
    div ebx
    push edx            ;32-bit remainder is pushed onto the stack
    test eax, eax       ;sets the zero flag if eax is zero
    jnz @@getNextDigit  ;if not zero flag, repeat the process

@@printDigits:
    pop edx             ;pop the last digit from the stack
    add dl, '0'         ;convert the digit to ASCII
    mov ah, 2h          ;function for printing single characters
    int 21h             ;print the digit to the screen
    loop @@printDigits  ;untill ecx = 0

    ret
ENDP printSignedNumber

PUBLIC printUnsignedNumber
PROC printUnsignedNumber
    ARG @@number:dword
    USES eax, ebx, ecx, edx
    
    mov eax, [@@number] ; eax holds input integer
    mov ebx, 10         ; divider
    xor ecx, ecx        ; reset counter for digits to be printed (used by loop)

@@getNextDigit:
    ;loop decrements ecx until it reaches 0 
    ;later used for eg. printing digits
    inc ecx
    ; DIV uses EDX:EAX as input and output (64-bit dividend)
    ; We often divide 32-bit numbers, so we need to clear EDX first
    ; EDX is the high 32 bits of the dividend (64-bit number)
    xor edx, edx
    div ebx
    push edx            ;32-bit remainder is pushed onto the stack
    test eax, eax       ;sets the zero flag if eax is zero
    jnz @@getNextDigit  ;if not zero flag, repeat the process

@@printDigits:
    pop edx             ;pop the last digit from the stack
    add dl, '0'         ;convert the digit to ASCII
    mov ah, 2h          ;function for printing single characters
    int 21h             ;print the digit to the screen
    loop @@printDigits  ;untill ecx = 0

    ret
ENDP printUnsignedNumber

PUBLIC printFloat
PROC printFloat
    ARG @@number:dword, @@scaleFactor:dword
    USES eax, ebx, ecx, edx

    mov eax, [@@number] ; eax holds input integer
    mov ebx, 10         ; divider
    xor ecx, ecx        ; reset counter for digits to be printed (used by loop)

    fld [dword ptr @@number]  ; Load float number into FPU stack (ST(0))
    
    fmul dword ptr @@scaleFactor ; Multiply the float number by the scale factor
    
    frndint                     ; Round float number to nearest integer
    fistp dword ptr @@number  ; Store integer part into number, popping FPU stack

    call printSignedNumber, [@@number]
    
    mov ah, 2h          ; Print '.' for the decimal point
    mov dl, 'r'         ; dl stores the character to print
    int 21h             ; inerupt for printing a character

    ;this 3 is because the scale factor is 1000.0
    mov dl, '3'         ; dl stores the character to print
    int 21h             ; inerupt for printing a character
    ret

ENDP printFloat
END 