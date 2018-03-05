;===================================================================================================
; Circle
;
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Package: GrLib
;
; Description: 
; Draws a circle
;===================================================================================================
LOCALS @@

;----------------------------------------------------------
; Draws a circle
; Credit: https://stackoverflow.com/questions/37564442/assembly-draw-a-circle
;
; push Xcenter
; push Ycenter
; push Radius
; call GR_DrawCircle
;----------------------------------------------------------
PROC GR_DrawCircle
   store_sp_bp
   sub sp, 4
   pusha
   push es

    ; now the stack is
    ; bp-4 => y
    ; bp-2=> x
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => param4 (Radius)
    ; bp+6 => param3 (Ycenter)
    ; bp+8 => param2 (Xcenter)
    ; saved registers


  IsDblBuffering @@NotDbl
  GetDblBufferSeg es
@@NotDbl:    

    mov cx, 0               ; x = 0
    mov bx, [word bp+4]     ; radius
    mov di, [word bp+6]     ; Ycenter
    mov dx, [word bp+8]     ; Xcenter
    mov si, bx

@@circle0:
    call      @@8pixels           ;Set 8 pixels 
    sub       bx,cx               ;D=D-X 
    inc       cx                  ;X+1 
    sub       bx,cx               ;D=D-(2x+1) 
    jg        @@circle1           ;>> no step for Y 
    add       bx,si               ;D=D+Y 
    dec       si                  ;Y-1 
    add       bx,si               ;D=D+(2Y-1) 
@@circle1: 
    cmp       si,cx               ;Check X>Y 
    jae       @@circle0           ;>> Need more pixels 
    jmp       @@fin
@@8pixels:
    call      @@4pixels           ;4 pixels 
@@4pixels:
    xchg      cx,si               ;Swap x and y 
    call      @@2pixels           ;2 pixels 
@@2pixels:
    neg       si 

    mov al,   [gr_pen_color]      ; color
    push      di 
    add       di,si 
    imul      di,VGA_SCREEN_WIDTH
    add       di,dx 
    push di
    add       di, cx
    mov       [BYTE es:di],al 
    pop di
    sub       di,cx 
    stosb 
    pop       di 
    ret
@@fin:
    pop es
    popa
    restore_sp_bp
    ret 6
ENDP GR_DrawCircle

;----------------------------------------------------------
; Fills a circle
; Credit: https://stackoverflow.com/questions/31563382/what-is-the-easiest-way-to-draw-a-perfectly-filled-circledisc-in-assembly
;
; push Xcenter
; push Ycenter
; push Radius
; call GR_FillCircle
;----------------------------------------------------------
PROC GR_FillCircle
    store_sp_bp
    sub sp, 6h

    ; now the stack is
    ; bp-6 => y
    ; bp-4 => x
    ; bp-2 => tmp
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => param4 (radius)
    ; bp+6 => param3 (ycenter)
    ; bp+8 => param2 (xcenter)
    ; saved registers  

    mov cx,[WORD bp+04h]   ;Radius

    mov ax, cx              
    mul ax                  ;AX = R^2
    mov[WORD bp-02h], ax   ;[bp-02h] = R^2

    mov ax,[WORD bp+06h]
    sub ax, cx              ;i = cY-R
    mov bx,[WORD bp+08h]
    sub bx, cx              ;j = cX-R

    shl cx, 1
    mov dx, cx              ;DX = Copy of 2R

@@advance_v:
    push cx
    push bx

    mov cx,  dx

@@advance_h:
    ;Save values
    push bx
    push ax
    push dx

    ;Compute (i-y) and (j-x)
    sub ax,[WORD bp+06h]
    sub bx,[WORD bp+08h]

    mul ax                  ;Compute (i-y)^2

    push ax
    mov ax, bx             
    mul ax
    pop bx                  ;Compute (j-x)^2 in ax, (i-y)^2 is in bx now

    add ax, bx              ;(j-x)^2 + (i-y)^2
    cmp ax,[WORD bp-02h]   ;;(j-x)^2 + (i-y)^2 <= R^2

    ;Restore values before jump
    pop dx
    pop ax
    pop bx

    ja @@continue            ;Skip pixel if (j-x)^2 + (i-y)^2 > R^2

    ;Write pixel
    mov [word bp-4], bx
    mov [word bp-6], ax
    gr_set_pixel [bp-4], [bp-6], [gr_pen_color]

@@continue:
    ;Advance j
    inc bx
    loop @@advance_h

 ;Advance i
    inc ax

    pop bx            ;Restore j
    pop cx            ;Restore counter

loop @@advance_v
    
    restore_sp_bp
    ret 06h
ENDP GR_FillCircle

;////////////////////////////////////////////////////////////////////////////
; FUNCTION LIKE MACROS
;////////////////////////////////////////////////////////////////////////////

;----------------------------------------------------------------------
; Fills a circle
;
; grm_FillCircle (Xcenter, Ycenter, Radius)
;----------------------------------------------------------------------
MACRO grm_FillCircle Xcenter, Ycenter, Radius
    push Xcenter
    push Ycenter
    push Radius
    call GR_FillCircle
ENDM

;----------------------------------------------------------------------
; Draw a circle
;
; grm_DrawCircle (Xcenter, Ycenter, Radius)
;----------------------------------------------------------------------
MACRO grm_DrawCircle Xcenter, Ycenter, Radius
    push Xcenter
    push Ycenter
    push Radius
    call GR_DrawCircle
ENDM