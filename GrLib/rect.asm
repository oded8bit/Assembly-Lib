;===================================================================================================
; Rectangle
;
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Package: GrLib
;
; Description: 
; Draw rectangles
;===================================================================================================
LOCALS @@

;----------------------------------------------------------
; Draws a rectangle 
; 
; push x
; push y
; push width
; push height
; call GR_DrawRect
;----------------------------------------------------------
PROC GR_DrawRect
  store_sp_bp
  sub sp, 8   ; 2 bytes * 4 local vars
  pusha

  ; now the stack is
  ; bp-8 => x2
  ; bp-6 => y2
  ; bp-4 => x1 - not in use
  ; bp-2 => y1 - not in use
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => param4 (height)
	; bp+6 => param3 (width)
	; bp+8 => param2 (y)
	; bp+10 => param1 (x)
	; saved registers

  mov ax, [word bp+10]   
  add ax, [word bp+6]    ; x + width
  mov [bp-8], ax    ; x2 = x + width

  mov ax, [word bp+8]   
  add ax, [word bp+4]    ; y + height
  mov [word bp-6], ax    ; y2 = y + height

  push [word bp+10]      ; x - Horz top
  push [word bp+8]       ; y
  push [word bp-8]       ; x2
  push [word bp+8]       ; y
  call GR_DrawLine

  push [word bp+10]      ; x -  Horz bottom
  push [word bp-6]       ; y2
  push [word bp-8]       ; x2
  push [word bp-6]       ; y2
  call GR_DrawLine

  push [word bp-8]      ; x2 -  Vert right
  push [word bp+8]       ; y
  push [word bp-8]      ; x2
  push [word bp-6]       ; y2
  call GR_DrawLine

  push [word bp+10]      ; x -  Vert left
  push [word bp+8]       ; y
  push [word bp+10]      ; x
  push [word bp-6]       ; y2
  call GR_DrawLine

  popa
  restore_sp_bp
  ret 8
ENDP GR_DrawRect

;+-+-+-+-+-+-+-+-+-+- RECTANGLE +-+-+-+-+-+-+-+-++-+-+-+-+-+

;----------------------------------------------------------
; Fills a rectangle 
; 
; push x
; push y
; push width
; push height
; call GR_FillRect
;----------------------------------------------------------
PROC GR_FillRect
  store_sp_bp
  sub sp, 8   ; 2 bytes * 4 local vars
  pusha

  ; now the stack is
  ; bp-8 => x2
  ; bp-6 => y2
  ; bp-4 => x1
  ; bp-2 => y1
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => param4 (height)
	; bp+6 => param3 (width)
	; bp+8 => param2 (y)
	; bp+10 => param1 (x)
	; saved registers

  mov ax, [bp+10]   
  add ax, [bp+6]    ; x + width
  mov [bp-8], ax    ; x2 = x + width

  mov ax, [bp+8]   
  add ax, [bp+4]    ; y + height
  mov [bp-6], ax    ; y2 = y + height

@@GR_draw_rect__rect:
  push [word bp+8]
  pop [word bp-2]
@@GR_draw_rect__v:
  push [word bp+10]
  pop [word bp-4]
@@GR_draw_rect__h:
  gr_set_pixel [bp-4], [bp-2], [gr_pen_color] ; draw pixel at (x1,y1)
  inc [word bp-4]               ; x1++
  cmpv [bp-4], [bp-8], ax       
  jl @@GR_draw_rect__h          ; if (x1 < x2) goto GR_draw_rect__h
  inc [word bp-2]                    ; y2++
  cmpv [bp-2], [bp-6], ax
  jl @@GR_draw_rect__v          ; if (y1 < y2) goto GR_draw_rect__v

  popa
  restore_sp_bp
  ret 8
ENDP GR_FillRect

;////////////////////////////////////////////////////////////////////////////
; FUNCTION LIKE MACROS
;////////////////////////////////////////////////////////////////////////////

;----------------------------------------------------------------------
; Draw Rect
;
; grm_DrawRect (x, y, width, height)
;----------------------------------------------------------------------
MACRO grm_DrawRect x, y, width, height
    push x
    push y
    push width
    push height
    call GR_DrawRect
ENDM

;----------------------------------------------------------------------
; Fill Rect
;
; grm_FillRect (x, y, width, height)
;----------------------------------------------------------------------
MACRO grm_FillRect x, y, width, height
    push x
    push y
    push width
    push height
    call GR_FillRect
ENDM
