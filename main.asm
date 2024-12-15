; -------------------------------------------------------------------
; 80386
; 32-bit x86 assembly language
; TASM
;
; author:	David Blinder
; date:		23/10/2017
; program:	IDEAL Function calls.
; -------------------------------------------------------------------

IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
CODESEG		

PROC main
    sti                ; Enable interrupts.
    cld                ; Clear direction flag.

    VMEMADR EQU 0A0000h    ; Video memory address
    SCRWIDTH EQU 320       ; Screen width for mode 13h
    SCRHEIGHT EQU 200      ; Screen height

    BLACK       EQU 0
    BLUE        EQU 1
    GREEN       EQU 2
    CYAN        EQU 3
    RED         EQU 4
    MAGENTA     EQU 5
    BROWN       EQU 6
    LIGHT_GRAY  EQU 7
    DARK_GRAY   EQU 8
    LIGHT_BLUE  EQU 9
    LIGHT_GREEN EQU 10
    LIGHT_CYAN  EQU 11
    LIGHT_RED   EQU 12
    LIGHT_MAGENTA EQU 13
    YELLOW      EQU 14
    WHITE       EQU 15

    EXTRN printFloat:PROC
    EXTRN drawPixel:PROC
    EXTRN drawLine:PROC
    EXTRN printNewline:PROC    



    ;call printFloat, [number], [scale]
    ;call printNewline

    ; Set video mode 13h
    mov AX, 13h
    int 10h

    ; Set start of video memory
    mov EDI, VMEMADR

    ; Set up ESI for array iteration
    mov ecx, [array_length]     ; Number of coordinates (pairs of x and y)
    mov esi, offset array       ; ESI points to the start of array
    
    ;call drawPixel, [dword ptr esi], [dword ptr esi + 4], LIGHT_CYAN
    ;call drawPixel, [dword ptr esi], [dword ptr esi + 4], LIGHT_CYAN

    call drawLine, [dword ptr esi], [dword ptr esi + 4], [dword ptr esi + 8], [dword ptr esi + 12]


    
wait_for_key:
    ; Wait for keystroke
    mov ah, 0h
    int 16h
    ;text mode
    mov ax, 3
    int 10h

    ; Terminate program
    mov ax, 4C00h
    int 21h

ENDP main

; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------
DATASEG
    number dd -10678.345
    ;must be a float
    scale dd 1000.0
    array_length dd 2
    array dd 10, 10, 20, 20
    x_val dd ?
    epsilon dd 0.0001
    

; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 200h

END main
