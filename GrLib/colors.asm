;===================================================================================================
; Colors
;
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Package: GrLib
;
; Description: 
; managing colors
;===================================================================================================
LOCALS @@

;=======================================================================
; Basic graphics library for DOS VGA mode 320x200 pixels, 256 colors
; Color Pallete
;=======================================================================
DATASEG
    GR_COLOR_BLACK          equ     0h
    GR_COLOR_BLUE           equ     01h
    GR_COLOR_GREEN          equ     02h
    GR_COLOR_CYAN           equ     03h
    GR_COLOR_RED            equ     04h
    GR_COLOR_MAGENTA        equ     05h
    GR_COLOR_BROWN          equ     06h
    GR_COLOR_LIGHTGRAY      equ     07h
    GR_COLOR_DARKGRAY       equ     08h
    GR_COLOR_LIGHTBLUE      equ     09h
    GR_COLOR_LIGHTGREEN     equ     0ah
    GR_COLOR_LIGHTCYAN      equ     0bh
    GR_COLOR_LIGHTRED       equ     0ch
    GR_COLOR_LIGHTMAGENTA   equ     0dh
    GR_COLOR_YELLOW         equ     0eh
    GR_COLOR_WHITE          equ     0fh

CODESEG
;----------------------------------------------------------
; SetPaletteBios
;
; input:
;   bl = color index
;   dh = red (0..63)
;   ch = green (0..63)
;   cl = blue (0..63)
;----------------------------------------------------------
MACRO SetPaletteBios
    mov ax,1010h    ; Video BIOS function to change palette color
    ;mov bx,0        ; color number 0 (usually background, black)
    mov dh,60       ; red color value (0-63, not 0-255!)
    mov ch, 0       ; green color component (0-63)
    mov cl,30       ; blue color component (0-63)
    int 10h         ; Video BIOS interrupt
ENDM
;----------------------------------------------------------
; _SetPaletteRGB 
; Input:
;   al = color index
;   bh = red color component (0..63)
;   ch = green color component (0..63)
;   cl = blue color component (0..63)
;----------------------------------------------------------
MACRO _SetPaletteDirect
    push dx

    mov  dx,03c8h                 ; RGB write register        
    out  dx,al                    ; Set the palette index     
    inc  dx                       ; 03C9 RGB data register   

    mov al, bh
    out  dx,al                    ; Red component  
    mov al, ch
    out  dx,al                    ; Green component
    mov al, cl
    out  dx,al                    ; Blue component 

    pop dx
ENDM
;----------------------------------------------------------
; push index
; push R
; push G
; push B
; call SetPaletteRGB
;----------------------------------------------------------
PROC SetPaletteDirect
;(reg,R,G,B:byte);                            assembler;
    store_sp_bp
    push ax
    push bx
    push cx
    push dx
    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => B (0..63)
	; bp+6 => G (0..63)
	; bp+8 => R (0..63)
	; bp+10 => index
	; saved registers

    mov  ax,[word bp+10]          ; al = index
    mov  dx,[word bp+8]           ; Red
    mov bh,dl
    mov  dx,[word bp+6]           ; Green
    mov ch, dl
    mov  dx,[word bp+4]           ; Blue
    mov cl, dl

    _SetPaletteDirect

    pop dx
    pop cx
    pop bx
    pop ax
    restore_sp_bp
    ret 8
ENDP SetPaletteDirect 
;----------------------------------------------------------
; GetPaletteBios 
; Input:
;   bx = color index
; Output:
;   dh = red color component (0..63)
;   ch = green color component (0..63)
;   cl = blue color component (0..63)
;----------------------------------------------------------
MACRO GetPaletteBios
    push ax
    mov ax,1015h
    ;mov bx,index          ; color index
    int 10h
    pop ax
ENDM


;////////////////////////////////////////////////////////////////////////////
; FUNCTION LIKE MACROS
;////////////////////////////////////////////////////////////////////////////

;----------------------------------------------------------------------
; 
;
; grm_SetPaletteDirect (index, R, G, B)
;----------------------------------------------------------------------
MACRO grm_SetPaletteDirect index, R, G, B
    push index
    push R
    push G
    push B
    call SetPaletteDirect
ENDM
