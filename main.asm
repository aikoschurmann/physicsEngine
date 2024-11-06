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
    sti  ; Set the interrupt flag => enable interrupts.
    cld  ; Clear the direction flag => auto-increment source
         ; and destination indices.
    EXTRN printSignedNumber:PROC
    call printSignedNumber, [number]
    
    mov ah,0h		; wait for keystroke
    int 16h
	mov	ax,4C00h 	; terminate
	int 21h

ENDP main


; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------
DATASEG
    number dd -106789987
    

; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END main
