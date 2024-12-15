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

VMEMADR EQU 0A0000h    ; Video memory address
SCRWIDTH EQU 320       ; Screen width for mode 13h
SCRHEIGHT EQU 200      ; Screen height


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
    
    fmul [dword ptr @@scaleFactor] ; Multiply the float number by the scale factor
    
    frndint                     ; Round float number to nearest integer
    fistp [dword ptr @@number]  ; Store integer part into number, popping FPU stack

    call printSignedNumber, [@@number]
    
    mov ah, 2h          ; Print '.' for the decimal point
    mov dl, 'r'         ; dl stores the character to print
    int 21h             ; inerupt for printing a character

    ;this 3 is because the scale factor is 1000.0
    mov dl, '3'         ; dl stores the character to print
    int 21h             ; inerupt for printing a character
    ret

ENDP printFloat


PUBLIC drawPixel
PROC drawPixel
    ARG @@xval:dword, @@yval:dword, @@color:byte
    LOCAL @@xtemp:dword, @@ytemp:dword
    USES eax, edi, ebx

    mov eax, [dword ptr @@xval]     ; Load x coordinate
    fld [dword ptr @@xval]          ; Load x coordinate into FPU stack
    fistp [dword ptr @@xtemp]       ; Store x coordinate as integer
    mov eax, [@@xtemp]              ; Load x coordinate as integer
    lea edi, [VMEMADR + eax]        ; Calculate x offset in video memory

    mov eax, [@@yval]               ; Load y coordinate from array
    fld [dword ptr @@yval]          ; Load y coordinate into FPU stack
    fistp [dword ptr @@ytemp]       ; Store y coordinate as integer
    mov eax, [@@ytemp]              ; Load y coordinate as integer
    mov ebx, SCRWIDTH               ; Load SCRWIDTH constant into EBX
    mul ebx                         ; Multiply EAX (y coordinate) by screen width (EBX)
    add edi, eax                    ; Add y offset to EDI

    mov AL, [@@color]                      ; Color index (e.g., white)
    mov [EDI], AL                   ; Write pixel at (x, y) position
    ret
ENDP drawPixel

PUBLIC printNewline
PROC printNewline
    USES eax, ebx, ecx, edx

    mov dl, 0Dh         ; Carriage return.
    mov ah, 2h          ; Function for printing single characters.
    int 21h             ; Print the character to the screen.

    mov dl, 0Ah         ; New line.
    mov ah, 2h          ; Function for printing single characters.
    int 21h             ; Print the character to the screen.

    ret
ENDP printNewline

Public printString
PROC printString
    ARG @@string:dword
    USES eax, ebx, ecx, edx

    mov eax, [@@string] ; Load address of string into EAX
    mov edx, eax        ; Copy address of string into EDX
    mov ah, 9h          ; Function for printing a string
    int 21h             ; Print the string to the screen

    ret
ENDP printString

; why the hell is this not working
PUBLIC drawLine
PROC drawLine
    ARG @@x1:dword, @@y1:dword, @@x2:dword, @@y2:dword
    LOCAL @@dx:dword, @@dy:dword, @@sx:dword, @@sy:dword, @@err:dword, @@err2:dword
    USES eax, ebx, ecx, edx

    ;dx = abs(x2 - x1)
    ;dy = abs(y2 - y1)
    ;sx = sign(x2 - x1)  // Step in x direction
    ;sy = sign(y2 - y1)  // Step in y direction
    ;err = dx - dy  // Error term

    mov eax, [@@x2]     ; Load x2 coordinate
    sub eax, [@@x1]     ; Subtract x1 from x2
    test eax, eax       ; Check for sign
    jns @@skipSignX2    ; If the sign is not set, skip the '-' sign.
    neg eax             ; negate eax
@@skipSignX2:
    mov @@dx, eax       ; Store dx

    mov eax, [@@y2]     ; Load y2 coordinate
    sub eax, [@@y1]     ; Subtract y1 from y2
    test eax, eax       ; Check for sign
    jns @@skipSignY2    ; If the sign is not set, skip the '-' sign.
    neg eax             ; negate eax
@@skipSignY2:
    mov @@dy, eax       ; Store dy

    mov eax, [@@x2]     ; Load x2 coordinate
    sub eax, [@@x1]     ; Subtract x1 from x2
    test eax, eax
    jns @@sx_sign       ; If the sign is not set, skip the '-' sign.
    mov @@sx, 1         ; Set sx to -1
    jmp @@endSx

@@sx_sign:
    mov @@sx, 1        ; Set sx to -1
    jmp @@endSx

@@endSx
    
        mov eax, [@@y2]     ; Load y2 coordinate
        sub eax, [@@y1]     ; Subtract y1 from y2
        test eax, eax
        jns @@sy_sign       ; If the sign is not set, skip the '-' sign.
        mov @@sy, 1         ; Set sy to -1
        jmp @@endSy

@@sy_sign:
    mov @@sy, 1        ; Set sy to -1
    jmp @@endSy

@@endSy:
    mov eax, @@dx       ; Load dx
    sub eax, @@dy       ; Subtract dy from dx
    mov @@err, eax      ; Store err

@@loop_draw
    call drawPixel, [dword ptr @@x1], [dword ptr @@y1], 15

    mov eax, @@x1       ; Load x1
    cmp eax, [@@x2]     ; Compare x1 with x2
    jne @@continue      ; If x1 does not equal x2, continue loop
    mov eax, @@y1       ; Load y1
    cmp eax, [@@y2]     ; Compare y1 with y2
    je @@endLoop        ; If y1 equals y2, end loop

@@continue 
    mov eax, @@err      ; Load err
    shl eax, 1          ; Multiply err by 2
    mov @err2, eax      ; Store err2

    mov eax, @@err2     ; Load err2
    cmp eax, @@dy       ; Compare err2 with dy



@@endLoop:
    ret
ENDP drawLine




DATASEG
    ; Scale factor for float-to-integer conversion
    scale dd 1000.0

    ; Strings for printing variable names
    string_x1_y1 db "x1 and y1: ", '$'
    string_x2_y2 db "x2 and y2: ", '$'
    string_dx db "dx (abs(x2 - x1)): ", '$'
    string_dy db "dy (abs(y2 - y1)): ", '$'
    string_sx db "sx (sign(x2 - x1)): ", '$'
    string_sy db "sy (sign(y2 - y1)): ", '$'
    string_err db "err (dx - dy): ", '$'

    ; Error value label
    error_val_string db "Error: ", '$'

END