;=====================================================================
; implementation of Bresenham's line algorithm
; See https://rosettacode.org/wiki/Bitmap/Bresenham%27s_line_algorithm
;
; Javascript equivalent
;
; function GR_DrawLine(x0, y0, x1, y1) {
; 
;  var dx = Math.abs(x1 - x0);
;  var sx = x0 < x1 ? 1 : -1;
;  var dy = Math.abs(y1 - y0) 
;  var sy = y0 < y1 ? 1 : -1; 
;  var err = (dx>dy ? dx : -dy)/2;
; 
;  while (true) {
;    setPixel(x0,y0);
;    if (x0 === x1 && y0 === y1) break;
;    var e2 = err;
;    if (e2 > -dx) { err -= dy; x0 += sx; }
;    if (e2 < dy) { err += dx; y0 += sy; }
;  }
; }
;=====================================================================
LOCALS @@

;---------------------------------------------
; case: DeltaY is bigger than DeltaX		  
; input: bp+10 p1Y,		            		  
; 		 p2X p2Y,		           		      
;		 Color -> variable   
; output: line on the screen                  
;---------------------------------------------
MACRO DrawLine2DDY 
	local DrawLine2DDY_l1, DrawLine2DDY_lp, DrawLine2DDY_nxt
	mov dx, 1
	mov ax, pointX1			; x1
	cmp ax, pointX2			; x2
	jbe DrawLine2DDY_l1		; jump if x1 <= x2
	neg dx 					; turn delta to -1
DrawLine2DDY_l1:
	mov ax, pointY2			; y2
	shr ax, 1 				; y2 /  2		
	mov varTemp, ax			; tmp = y2 / 2
	mov ax, pointX1			; x1
	mov varX, ax			; x = x1
	mov ax, pointY1			; y1
	mov varY, ax			; y = y1
	mov bx, pointY2			; y2
	sub bx, pointY1			; y1 - y2
	gr_absolute bx			; |y1 - y2|
	mov cx, pointX2			; x2
	sub cx, pointX1			; x1
	gr_absolute cx			; |x1 - x2|
	mov ax, pointY2			; y2
DrawLine2DDY_lp:
	gr_set_pixel varX, varY, [gr_pen_color] ; (x,y)
	inc varY				; y++
	cmp varTemp, 0			; tmp
	jge DrawLine2DDY_nxt	; jump if (tmp >= 0)
	add varTemp, bx 		; tmp = delyaY		bx = (p2Y - p1Y) = deltay
	add varX, dx 			; x = delta			dx = delta
DrawLine2DDY_nxt:
	sub varTemp, cx 		; tmp = deltax		cx = abs(p2X - p1X) = daltax
	cmp varY, ax 			; ax = y2
	jne DrawLine2DDY_lp		; jump if y != y2
	gr_set_pixel varX, varY, [gr_pen_color]
ENDM DrawLine2DDY
;---------------------------------------------
; case: DeltaX is bigger than DeltaY		  
; input: p1X p1Y,		            		  
; 		 p2X p2Y,		           		      
;		 Color -> variable                    
; output: line on the screen                  
;---------------------------------------------
MACRO DrawLine2DDX 
	local DrawLine2DDX_l1, DrawLine2DDX_lp, DrawLine2DDX_nxt
	mov dx, 1
	mov ax, pointY1			; y1
	cmp ax, pointY2			
	jbe DrawLine2DDX_l1		; jump if y1 <= y2
	neg dx 					; else turn delta to -1
DrawLine2DDX_l1:
	mov ax, pointX2			; y1
	shr ax, 1 				; div by 2		; y1 / 2
	mov varTemp, ax			; tmp = y1 / 2
	mov ax, pointX1			; x1
	mov varX, ax			; x = x1
	mov ax, pointY1			; y1
	mov varY, ax			; y = y1
	mov bx, pointX2			; x2
	sub bx, pointX1			; x2 - x1
	gr_absolute bx			; bx = |x2 - x1|
	mov cx, pointY2			; y2
	sub cx, pointY1			; y1
	gr_absolute cx			; cx = |y2 - y1|
	mov ax, pointX2			; x2
DrawLine2DDX_lp:
	gr_set_pixel varX, varY, [gr_pen_color]	; (x,y)
	inc varX				; x++
	cmp varTemp, 0			; tmp
	jge DrawLine2DDX_nxt	; jump if tmp >= 0
	add varTemp, bx 		; tmp = deltax     bx = abs(p2X - p1X) = deltax
	add varY, dx 			; y <= delta       dx = delta
DrawLine2DDX_nxt:
	sub varTemp, cx 		; tmp -= deltay    cx = abs(p2Y - p1Y) = deltay
	cmp varX, ax 			; ax = x2
	jne DrawLine2DDX_lp		; jump if x != x2
	gr_set_pixel varX, varY, [gr_pen_color]
ENDM DrawLine2DDX
;---------------------------------------------
; Draws a line
;
; push x1
; push y1
; push x2
; push y2
; call GR_DrawLine
;---------------------------------------------
PROC GR_DrawLine
	store_sp_bp
	sub sp, 6   ; 2 bytes * 3 local vars
	pusha

	; now the stack is
	; bp-6 => temp
	; bp-4 => pointY
	; bp-2 => pointX
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => param4 (point2Y)
	; bp+6 => param3 (point2X)
	; bp+8 => param2 (point1Y)
	; bp+10 => param1 (point1X)
	; saved registers

	;{
	varTemp		equ			[word bp-6]
	varY		equ			[word bp-4]
	varX		equ			[word bp-2]

	pointX1		equ			[word bp+10]
	pointY1		equ			[word bp+8]
	pointX2		equ			[word bp+6]
	pointY2		equ			[word bp+4]	
	;}

	; init vars
	mov varTemp,0
	mov varY,0
	mov varX,0

	mov cx, pointX1		; x1
	sub cx, pointX2		; x1 - x2
	gr_absolute cx		; deltaX = |x1 - x2|
	mov bx, pointY1		; y1
	sub bx, pointY2		; y1 - y2
	gr_absolute bx		; deltaY = |y1 - y2|
	cmp cx, bx				
	jae @@DrawLine2Dp1 		; jump if deltaX >= deltaY
	mov ax, pointX1		; x1
	mov bx, pointX2		; x2
	mov cx, pointY1		; y1
	mov dx, pointY2		; y2
	cmp cx, dx				
	jbe @@DrawLine2DpNxt1 	; jump if point1Y <= point2Y
	xchg ax, bx			 
	xchg cx, dx
@@DrawLine2DpNxt1:
	mov pointX1, ax		; x1
	mov pointX2, bx		; x2
	mov pointY1, cx		; y1
	mov pointY2, dx		; y2
	DrawLine2DDY 
	jmp @@DrawLine2D_exit	; return
@@DrawLine2Dp1:
	mov ax, pointX1		; x1
	mov bx, pointX2		; x2
	mov cx, pointY1		; y1
	mov dx, pointY2		; y2
	cmp ax, bx
	jbe @@DrawLine2DpNxt2 	; jump if point1X <= point2X
	xchg ax, bx
	xchg cx, dx
@@DrawLine2DpNxt2:
	mov pointX1, ax		; x1
	mov pointX2, bx		; x2
	mov pointY1, cx		; y1
	mov pointY2, dx		; y2
	DrawLine2DDX 

@@DrawLine2D_exit:
  popa
  restore_sp_bp
  ret 8
ENDP GR_DrawLine

;////////////////////////////////////////////////////////////////////////////
; FUNCTION LIKE MACROS
;////////////////////////////////////////////////////////////////////////////

;----------------------------------------------------------------------
; Draw a line
;
; grm_DrawLine (x1, y1, x2, y2)
;----------------------------------------------------------------------
MACRO grm_DrawLine x1, y1, x2, y2
    push x1
    push y1
    push x2
    push y2
    call GR_DrawLine
ENDM
