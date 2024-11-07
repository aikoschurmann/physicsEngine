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


PUBLIC drawLine
PROC drawLine
    ; 10 10 20 20
    ARG @@x1:dword, @@y1:dword, @@x2:dword, @@y2:dword, @@color:byte, @@epsilon:dword
    LOCAL @@dx:dword, @@dy:dword, @@sx:dword, @@sy:dword, @@err:dword, @@e2:dword
    USES eax, ebx, ecx, edx, edi

    ; Print initial newline
    call printNewline

    ; Print x1 and y1
    call printString, offset string_x1_y1
    call printNewline
    call printFloat, [@@x1], [scale]
    call printNewline
    call printFloat, [@@y1], [scale]
    call printNewline

    ; Print x2 and y2
    call printString, offset string_x2_y2
    call printNewline
    call printFloat, [@@x2], [scale]
    call printNewline
    call printFloat, [@@y2], [scale]
    call printNewline

    ; dx = abs(x2 - x1) (floats)
    fld [dword ptr @@x2]             ; Load x2 into FPU stack
    fsub [dword ptr @@x1]            ; Subtract x1 from x2
    fabs                             ; Get absolute value
    fstp [dword ptr @@dx]            ; Store dx as float

    ; dy = abs(y2 - y1) (floats)
    fld [dword ptr @@y2]             ; Load y2 into FPU stack
    fsub [dword ptr @@y1]            ; Subtract y1 from y2
    fabs                             ; Get absolute value
    fstp [dword ptr @@dy]            ; Store dy as float

    ; Calculate sx = sign(x2 - x1)
    fld [dword ptr @@x1]             ; Load x1 into FPU stack
    fcom [dword ptr @@x2]            ; Compare x1 and x2
    fstsw ax                         ; Store FPU status word in AX
    sahf                             ; Store AH in flags (affecting the CPU flags)
    jae @@skipSx                     ; If x1 >= x2, skip the next instruction (sx = -1)
    mov [@@sx], 1                    ; Set sx to 1 (x1 < x2)
    jmp @@doneSx
@@skipSx:
    mov [@@sx], -1                   ; Set sx to -1 (x1 >= x2)
@@doneSx:

    ; Calculate sy = sign(y2 - y1)
    fld [dword ptr @@y1]             ; Load y1 into FPU stack
    fcom [dword ptr @@y2]            ; Compare y1 and y2
    fstsw ax                         ; Store FPU status word in AX
    sahf                             ; Store AH in flags (affecting the CPU flags)
    jae @@skipSy                     ; If y1 >= y2, skip the next instruction (sy = -1)
    mov [@@sy], 1                    ; Set sy to 1 (y1 < y2)
    jmp @@doneSy
@@skipSy:
    mov [@@sy], -1                   ; Set sy to -1 (y1 >= y2)
@@doneSy:

    ; err = dx - dy  // Error term
    fld [dword ptr @@dx]             ; Load dx into FPU stack
    fsub [dword ptr @@dy]            ; Subtract dy from dx
    fstp [dword ptr @@err]           ; Store err as float

    ;initialize loop variables
    mov eax, [@@x1]                  ; set current x into EAX
    mov ebx, [@@y1]                  ; set current y into EBX

@@loopStart:
    ; Draw pixel at (x, y)
    call drawPixel, eax, ebx, @@color
    
    ;if abs(x1 - x2) < epsilon and abs(y1 - y2) < epsilon: break
    fld [dword ptr @@x2]             ; Load x2 into FPU stack
    fsub [dword ptr @@x1]            ; Subtract x1 from x2
    fabs                             ; Get absolute value
    fcom [dword ptr @@epsilon]       ; Compare with epsilon
    fstsw ax                         ; Store FPU status word in AX
    sahf                             ; Store AH in flags (affecting the CPU flags)
    jae @@skipEpsilon                 ; If abs(x1 - x2) >= epsilon, skip the next instruction
    fld [dword ptr @@y2]             ; Load y2 into FPU stack
    fsub [dword ptr @@y1]            ; Subtract y1 from y2
    fabs                             ; Get absolute value
    fcom [dword ptr @@epsilon]       ; Compare with epsilon
    fstsw ax                         ; Store FPU status word in AX
    sahf                             ; Store AH in flags (affecting the CPU flags)
    jae @@skipEpsilon                 ; If abs(y1 - y2) >= epsilon, skip the next instruction
    jmp @@breakLoop                  ; Break the loop

@@skipEpsilon:
    ; e2 = 2 * err
    fld [dword ptr @@err]            ; Load err into FPU stack
    fadd [dword ptr @@err]           ; Add err to err
    fstp [dword ptr @@e2]            ; Store e2 as float

    ; if e2 > -dy: err -= dy, x += sx
    fld [dword ptr @@e2]             ; Load e2 into FPU stack
    fcom [dword ptr @@dy]            ; Compare with -dy
    fstsw ax                         ; Store FPU status word in AX
    sahf                             ; Store AH in flags (affecting the CPU flags)
    jg @@skipErrDy                   ; If e2 <= -dy, skip the next instruction
    

    
    




    ; Print dx, dy, sx, sy, and err values
    call printString, offset string_dx
    call printFloat, [@@dx], [scale]
    call printNewline
    call printString, offset string_dy
    call printFloat, [@@dy], [scale]
    call printNewline
    call printString, offset string_sx
    call printSignedNumber, [@@sx], [scale]
    call printNewline
    call printString, offset string_sy
    call printSignedNumber, [@@sy], [scale]
    call printNewline
    call printString, offset string_err
    call printFloat, [@@err], [scale]
    call printNewline

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