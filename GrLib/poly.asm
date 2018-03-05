;===================================================================================================
; Polygons
;
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Package: GrLib
;
; Description: 
; Draws polygons
;===================================================================================================
LOCALS @@

;---------------------------------------------
; To draw a polygon, you need to define an array 
; and pass its pointer along with the number of 
; points in the array.
; 
; The array should contain **points** (x and y) as 
; follows:
;
; DATASEG	
;    POLY    dw     5,30,100,50,200,100
;
; This is an array with the following points:
; 1. POLY[0] = (5,30)
; 2. POLY[1] = (100,50)
; 3. POLY[2] = (200,100)
;
; and the call goes like that:
;    push 3              ; there are 3 points
;    push offset POLY    ; pointer to POLY array
;    call GR_DrawPolygon
;---------------------------------------------
PROC GR_DrawPolygon
	store_sp_bp
	pusha

	; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => param2 (array ptr)
	; bp+6 => param1 (size)
	; saved registers

    mov cx, [WORD bp+6]
    mov si, 0                   ; index to points
@@_drawpoly:
    mov di, [word bp+4]
    add di, si
    mov ax, [WORD di]           ; x1 value
    add di, 2
    mov bx, [WORD di]           ; y1 value
    push ax                 
    push bx
    cmp cx, 1
    jg @@_notlast
    mov di, [word bp+4]         ; move to first point
    sub di, 2
    mov si, 0
@@_notlast:    
    add di, 2
    mov ax, [WORD di]           ; x2 value
    add di, 2
    mov bx, [WORD di]           ; y2 value
    push ax
    push bx
    call GR_DrawLine
    add si, 4
    loop @@_drawpoly

  popa
  restore_sp_bp
  ret 4
ENDP GR_DrawPolygon

;////////////////////////////////////////////////////////////////////////////
; FUNCTION LIKE MACROS
;////////////////////////////////////////////////////////////////////////////

;----------------------------------------------------------------------
; Draw a polygon
;
; grm_DrawPolygon (numPoints, polygonOffset)
;----------------------------------------------------------------------
MACRO grm_DrawPolygon numPoints, polygonOffset
    push numPoints
    push polygonOffset
    call GR_DrawPolygon
ENDM
