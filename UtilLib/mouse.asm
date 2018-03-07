;===================================================================================================
; Mouse Handling
;
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Package: UtilLib
;
; Description: 
; Managing input from the mouse
;===================================================================================================
LOCALS @@

;----------------------------------------------------------------------
; Show the mouse pointer
;----------------------------------------------------------------------
MACRO ShowMouse
    mov ax,01
    int 33h
ENDM
;----------------------------------------------------------------------
; Hide the mouse pointer
;----------------------------------------------------------------------
MACRO HideMouse
    mov ax,02
    int 33h
ENDM
;----------------------------------------------------------------------
; Get Mouse Position and Button Status
;
; on return:
;	CX = horizontal (X) position  (0..639)
;	DX = vertical (Y) position  (0..199)
;	BX = button status:
;
;		|F-8|7|6|5|4|3|2|1|0|  Button Status
;		  |  | | | | | | | `---- left button (1 = pressed)
;		  |  | | | | | | `----- right button (1 = pressed)
;		  `------------------- unused
;
;
;	- values returned in CX, DX are the same regardless of video mode
;----------------------------------------------------------------------
MACRO GetMouseStatus
    mov ax, 03
    int 33h
ENDM
;-----------------------------------------------------------------------
; Input:
;   CX = horizontal position
;   DX = vertical position
;-----------------------------------------------------------------------
MACRO SetMousePosition
    mov ax, 4
    int 33h
ENDM
;----------------------------------------------------------------------- 
; cx = x (0..639)
; dx = y (0..199)
;-----------------------------------------------------------------------
MACRO TranslateMouseCoords
    inc cx
    shr cx, 1
ENDM
;------------------------------------------------------------------------
; push ISR address
; push ISR segment
; push mask
; call InstallMouseInterrupt
;------------------------------------------------------------------------
PROC InstallMouseInterrupt
    push ax
    push cx
    push dx
    push es
    cli

    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => mask
	; bp+6 => ISR segment
	; bp+8 => ISR address
	; saved registers  
    ;{
        _mask           equ     [word bp+4]
        _isr_addr       equ     [word bp+6]
        _isr_seg        equ     [word bp+8]
    ;}

    ; Mouse Reset/Get Mouse Installed Flag
    xor ax, ax
    int 33h
    cmp ax,0        
    je @@end                ; mouse not installed

    ShowMouse

    ; Set Mouse User Defined Subroutine and Input Mask
    mov ax, 0Ch
    mov cx, _mask
    push _isr_seg
    pop es
    mov dx, _isr_addr
    int 33h 
@@end:
    sti
    pop es
    pop dx
    pop cx
    pop ax
    ret 6
ENDP InstallMouseInterrupt
;------------------------------------------------------------------------
; call UninstallMouseInterrupt
;------------------------------------------------------------------------
PROC UninstallMouseInterrupt
    cli
    push ax
    push cx
    push dx

    mov ax, 0Ch
    xor cx, cx
    xor dx, dx
    int 33h

@@end:
    pop dx
    pop cx
    pop ax
    sti
    ret
ENDP UninstallMouseInterrupt
