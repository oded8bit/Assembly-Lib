;===================================================================================================
; Graphics Lib
;
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Package: GrLib
;
; Description: 
; Common graphics utils
;===================================================================================================
LOCALS @@

DATASEG 
  ; Constants
  GR_SCREEN_HEIGHT    dw   200
  GR_SCREEN_WIDTH     dw   320
  VGA_SCREEN_WIDTH    equ  320 
  VGA_SCREEN_HEIGHT   equ  200

  ; Internal variables
  gr_pen_color      db  0        ; Pen color
  GR_START_ADDR     dw  0a000h   ; Start Address of VGA Video memory

CODESEG
;----------------------------------------------------------
; Sets the MS-DOS BIOS Video Mode
;----------------------------------------------------------
MACRO gr_set_video_mode mode
  mov al, mode
  mov ah, 0
  int 10h
ENDM
;----------------------------------------------------------
; Explicitly sets the MS-DOS BIOS Video Mode
; to 320x200 256 color graphics
;----------------------------------------------------------
MACRO gr_set_video_mode_vga 
  gr_set_video_mode 13h
  mov es, [GR_START_ADDR]
  mov [GR_SCREEN_HEIGHT], 200
  mov [GR_SCREEN_WIDTH], 320
  gr_set_color GR_COLOR_WHITE  
ENDM
;----------------------------------------------------------
; Explicitly sets the MS-DOS BIOS Video Mode
; to 80x25 Monochrome text 
;----------------------------------------------------------
MACRO gr_set_video_mode_txt 
  gr_set_video_mode 03h
ENDM
;----------------------------------------------------------
; Sets pen color
;----------------------------------------------------------
MACRO gr_set_color color
  mov [gr_pen_color], color
ENDM
;-+-+-+-+-+- COORD VALIDATION & CORRECTION -+-+-++-+-+-+-+-+

;================================================
; Description - check that the coordinates are within
; screen range. If not, fix them
; INPUT: ax = x, bx = y
; OUTPUT: ax, bx - valid coordinates
; Register Usage: ax, bx
;================================================
PROC GR_VideoCheckValidCoord
	cmp		ax,	0
	jae		@@video_coord_x_not_zero
	mov 	ax, 0
	jmp		@@video_check_y
@@video_coord_x_not_zero:
	cmp		ax, [GR_SCREEN_WIDTH]
	jna		@@video_check_y
	mov		ax, [GR_SCREEN_WIDTH]

@@video_check_y:
	cmp		bx, 0
	jae		@@video_coord_y_not_zero
	mov		bx, 0
	ret
@@video_coord_y_not_zero:
	cmp		bx, [GR_SCREEN_HEIGHT]
	jna		@@video_coord_valid_end
	mov		bx, [GR_SCREEN_HEIGHT]
@@video_coord_valid_end:
	ret
ENDP GR_VideoCheckValidCoord

;+-+-+-+-+-+-+-+-+- SET PIXELS +-+-+-+-+-+-+-+-++-+-+-+-+-+

;----------------------------------------------------------
; Checks if the coords are within the VGA screen size
; Output:
;   if valid => ax = 1   else   ax = 0
;----------------------------------------------------------
MACRO is_valid_coord_vga x,y,w,h
  local end, valid, invalid

  mov ax, x
  cmp ax,0
  jl invalid

  add ax, w
  cmp ax,VGA_SCREEN_WIDTH
  ja invalid

  mov ax, y
  cmp ax,0
  jl invalid

  add ax, h
  cmp ax,VGA_SCREEN_HEIGHT
  ja invalid

valid:
  mov ax,0  
  jmp end
invalid:
  mov ax,1  
end:  
ENDM
;----------------------------------------------------------
; Checks if the coords are within the VGA screen size
; Output:
;   if valid => ax = 1   else   ax = 0
;----------------------------------------------------------
MACRO is_valid_coord_vga_mem x,y,w,h
  local end, valid, invalid

  mov ax, [word x]
  cmp ax,0
  jl invalid

  add ax, [word w]
  cmp ax,VGA_SCREEN_WIDTH
  ja invalid

  mov ax, [word y]
  cmp ax,0
  jl invalid

  add ax, [word h]
  cmp ax,VGA_SCREEN_HEIGHT
  ja invalid

valid:
  mov ax,0  
  jmp end
invalid:
  mov ax,1  
end:  
ENDM
;----------------------------------------------------------
; Translate (x,y) coordinates to the video memory address
; Output:
;   di = offset in video memory
;----------------------------------------------------------
MACRO translate_coord_to_vga_addr x, y
    push ax bx cx dx
    mov bx, [word y]
    mov ax, VGA_SCREEN_WIDTH    ; width
    mul bx                      ; ax = y * width
    add ax, [word x]            ; ax = (y * width) + x
    mov di, ax                  ; return value
    pop dx cx bx ax
ENDM
;----------------------------------------------------------
; Translate (x,y) coordinates to the video memory address
; Output:
;   di = offset in video memory
;----------------------------------------------------------
MACRO translate_coord_to_vga_addr_values x, y
    push ax bx cx dx
    mov bx, y
    mov ax, VGA_SCREEN_WIDTH    ; width
    mul bx                      ; ax = y * width
    add ax, x                   ; ax = (y * width) + x
    mov di, ax                  ; return value
    pop dx cx bx ax
ENDM
;----------------------------------------------------------
; Translate (x,y) coordinates to a memory address
;
; Input:
;   addr - start address of memory block
;   x,y  - coordinates
;   width - line width within memory
; Output:
;   si = offset 
;----------------------------------------------------------
MACRO translate_coord_to_buf_addr addr, x, y, width
    push ax bx cx
    mov bx, [word y]            ; y
    mov ax, [word width]        ; width
    mul bx                      ; ax = y * width
    add ax, [word x]            ; ax = (y * width) + x
    mov si, ax                  ; return value
    add si,[word addr]          ; start address of buffer
    pop cx bx ax
ENDM
;----------------------------------------------------------
; Sets a pixel using the BIOS int10h API 
;----------------------------------------------------------
MACRO gr_set_pixel_intr x, y, color
    mov ah, 0CH     ; set graphics pixel DOS function
    mov al, color   ; al stores the color
    mov cx, x       ; cx stores the x coordinate
    mov dx, y       ; dx stores the y coordinare
    int 10h         ; interrupt
ENDM
;----------------------------------------------------------
; Sets a pixel using Video Memory 
; Cannot use registers ax, bx, di as arguments
;----------------------------------------------------------
MACRO gr_set_pixel x, y, color
  local _NotDbl, _out
  push ax bx dx di es

  IsDblBuffering _NotDbl
  GetDblBufferSeg es
  
_NotDbl:    
  mov ax, y
  mov bx, VGA_SCREEN_WIDTH
  mul bx
  mov di, ax
  add di, x
  mov al, color
  mov [es:di], al

_out:  
  pop es di dx bx ax
ENDM
;----------------------------------------------------------
; Sets a pixel using Video Memory 
; Cannot use registers ax, bx, di or dx as arguments
;----------------------------------------------------------
MACRO gr_set_pixel_xy x, y
    gr_set_pixel x,y, [gr_pen_color]
ENDM
;----------------------------------------------------------
; Clears a rectangle (draws in black)
; 
; push x
; push y
; push width
; push height
; call GR_ClearRect
;----------------------------------------------------------
PROC GR_ClearRect
    store_sp_bp
    pusha
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => param4 (height)
    ; bp+6 => param3 (width)
    ; bp+8 => param2 (y)
    ; bp+10 => param1 (x)
    ; saved registers  

    ; save current color
    xor ax,ax
    mov al, [gr_pen_color]
    ; set color to black
    gr_set_color  GR_COLOR_BLACK
    ; push coordinates and params
    push [word bp+10]
    push [word bp+8]
    push [word bp+6]
    push [word bp+4]
    call GR_FillRect

    ; restore color
    mov [gr_pen_color], al

    popa
    restore_sp_bp
    ret 8
ENDP GR_ClearRect
;----------------------------------------------------------
; Clears the entire screen (VGA mode)
;----------------------------------------------------------
MACRO clear_screen_vga
  local _NotDbl, _out

  push es ds di ax cx

  IsDblBuffering _NotDbl
  GetDblBufferSeg es

_NotDbl:
    xor   di,di
    xor   ax,ax
    mov   cx,VGA_SCREEN_WIDTH*VGA_SCREEN_HEIGHT/2
    rep   stosw

    IsDblBuffering _out
    call CopyDblBufToVideo

_out:
    pop cx ax di ds es
ENDM
;----------------------------------------------------------
; Clears the entire screen 
;----------------------------------------------------------
MACRO clear_screen_mouse
  HideMouse
  clear_screen_vga
  ShowMouse
ENDM
;----------------------------------------------------------
; Clears the entire screen (TXT mode)
;----------------------------------------------------------
MACRO clear_screen_txt
    gr_set_video_mode_txt
ENDM