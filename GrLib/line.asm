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
	mov ax, [word bp+10]			; x1
	cmp ax, [word bp+6]				; x2
	jbe DrawLine2DDY_l1				; jump if x1 <= x2
	neg dx 							; turn delta to -1
DrawLine2DDY_l1:
	mov ax, [word bp+4]				; y2
	shr ax, 1 						; y2 /  2		
	mov [word bp-6], ax				; tmp = y2 / 2
	mov ax, [word bp+10]			; x1
	mov [word bp-2], ax				; x = x1
	mov ax, [word bp+8]				; y1
	mov [word bp-4], ax				; y = y1
	mov bx, [word bp+4]				; y2
	sub bx, [word bp+8]				; y1 - y2
	gr_absolute bx					; |y1 - y2|
	mov cx, [word bp+6]				; x2
	sub cx, [word bp+10]			; x1
	gr_absolute cx					; |x1 - x2|
	mov ax, [word bp+4]				; y2
DrawLine2DDY_lp:
	gr_set_pixel [bp-2], [bp-4], [gr_pen_color] ; (x,y)
	inc [word bp-4]					; y++
	cmp [word bp-6], 0				; tmp
	jge DrawLine2DDY_nxt			; jump if (tmp >= 0)
	add [word bp-6], bx 			; tmp = delyaY		bx = (p2Y - p1Y) = deltay
	add [word bp-2], dx 			; x = delta			dx = delta
DrawLine2DDY_nxt:
	sub [word bp-6], cx 			; tmp = deltax		cx = abs(p2X - p1X) = daltax
	cmp [word bp-4], ax 			; ax = y2
	jne DrawLine2DDY_lp				; jump if y != y2
	gr_set_pixel [bp-2], [bp-4], [gr_pen_color]
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
	mov ax, [word bp+8]			; y1
	cmp ax, [word bp+4]			
	jbe DrawLine2DDX_l1			; jump if y1 <= y2
	neg dx 						; else turn delta to -1
DrawLine2DDX_l1:
	mov ax, [word bp+6]			; y1
	shr ax, 1 ; div by 2		; y1 / 2
	mov [word bp-6], ax			; tmp = y1 / 2
	mov ax, [word bp+10]		; x1
	mov [word bp-2], ax			; x = x1
	mov ax, [word bp+8]			; y1
	mov [word bp-4], ax			; y = y1
	mov bx, [word bp+6]			; x2
	sub bx, [word bp+10]		; x2 - x1
	gr_absolute bx				; bx = |x2 - x1|
	mov cx, [word bp+4]			; y2
	sub cx, [word bp+8]			; y1
	gr_absolute cx				; cx = |y2 - y1|
	mov ax, [word bp+6]			; x2
DrawLine2DDX_lp:
	gr_set_pixel [bp-2], [bp-4], [gr_pen_color]	; (x,y)
	inc [word bp-2]				; x++
	cmp [word bp-6], 0			; tmp
	jge DrawLine2DDX_nxt		; jump if tmp >= 0
	add [word bp-6], bx 		; tmp = deltax     bx = abs(p2X - p1X) = deltax
	add [word bp-4], dx 		; y <= delta       dx = delta
DrawLine2DDX_nxt:
	sub [word bp-6], cx 		; tmp -= deltay    cx = abs(p2Y - p1Y) = deltay
	cmp [word bp-2], ax 		; ax = x2
	jne DrawLine2DDX_lp			; jump if x != x2
	gr_set_pixel [bp-2], [bp-4], [gr_pen_color]
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

	; init vars
	mov [word bp-6],0
	mov [word bp-4],0
	mov [word bp-2],0

	mov cx, [word bp+10]	; x1
	sub cx, [word bp+6]		; x1 - x2
	gr_absolute cx			; deltaX = |x1 - x2|
	mov bx, [word bp+8]		; y1
	sub bx, [word bp+4]		; y1 - y2
	gr_absolute bx			; deltaY = |y1 - y2|
	cmp cx, bx				
	jae @@DrawLine2Dp1 		; jump if deltaX >= deltaY
	mov ax, [word bp+10]	; x1
	mov bx, [word bp+6]		; x2
	mov cx, [word bp+8]		; y1
	mov dx, [word bp+4]		; y2
	cmp cx, dx				
	jbe @@DrawLine2DpNxt1 	; jump if point1Y <= point2Y
	xchg ax, bx			 
	xchg cx, dx
@@DrawLine2DpNxt1:
	mov [word bp+10], ax	; x1
	mov [word bp+6], bx		; x2
	mov [word bp+8], cx		; y2
	mov [word bp+4], dx		; y2
	DrawLine2DDY 
	jmp @@DrawLine2D_exit	; return
@@DrawLine2Dp1:
	mov ax, [word bp+10]	; x1
	mov bx, [word bp+6]		; x2
	mov cx, [word bp+8]		; y1
	mov dx, [word bp+4]		; y2
	cmp ax, bx
	jbe @@DrawLine2DpNxt2 	; jump if point1X <= point2X
	xchg ax, bx
	xchg cx, dx
@@DrawLine2DpNxt2:
	mov [word bp+10], ax	; x1
	mov [word bp+6], bx		; x2
	mov [word bp+8], cx		; y1
	mov [word bp+4], dx		; y2
	DrawLine2DDX 

@@DrawLine2D_exit:
  popa
  restore_sp_bp
  ret 8
ENDP GR_DrawLine
