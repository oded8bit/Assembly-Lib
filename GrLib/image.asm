;===================================================================================================
; Images
;
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Package: GrLib
;
; Description: 
; Managing images (not BMP)
;===================================================================================================
LOCALS @@

;======================================= SCREEN READ / WRITE================================================

;------------------------------------------------------------------------
; Copy a posrtion of the screen (x,y) into ScreenCache
; 
; Input: 
;   memAddress = memory variable offset that stores the data. Should be in the correct length (w*h)
;   memAddressSeg - segment of memAddress
;   x = top left X coordinate (must be 0..320-width)
;   y = top left Y coordinate (must be 0..200-height)
;   w = width of the area to copy
;   h = height of the area to copy
;
; SaveScreen(word *memAddress, word x, word y, word w, word h)
;------------------------------------------------------------------------
PROC SaveScreen 
    store_sp_bp
    sub sp,2
    pusha
    push es
    push ds

    ; now the stack is
    ; bp-2 => current y
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => h
    ; bp+6 => w
    ; bp+8 => y
    ; bp+10 => x
    ; bp+12 => memSeg
    ; bp+14 => *memAddress
    ; saved registers

    ;{
    rectHeight      equ         [word bp+4]
    rectWidth       equ         [word bp+6]
    yCoord          equ         [word bp+8]
    xCoord          equ         [word bp+10]
    memSeg          equ         [word bp+12]    
    memAddress      equ         [word bp+14]    

    vatCurY         equ         [word bp-2]
    ;}

    is_valid_coord_vga_mem bp+10,bp+8,bp+6,bp+4
    cmp ax,1
    je @@end                      ; invalid coords

    ; set ES
    push [WORD _dss]
    pop es
    ; set DS
    push [WORD GR_START_ADDR]
    pop ds
    mov ax, rectHeight
    add ax, yCoord
    mov bx, yCoord
    mov vatCurY, bx
    mov dx,0            ; dx = row in buffer
@@cpy:    
    push ax
    push dx
    ; set SI
    translate_coord_to_vga_addr bp+10,bp-2
    mov si, di
    ; set DI
    mov di, memAddress
    mov ax, dx
    mov dx, rectHeight
    mul dx              ; y * height
    add di, ax

    push memSeg
    pop es

    ; set length
    mov cx, rectWidth
    ; copy DS:SI to ES:DI
    cld  
    rep movsb
    inc vatCurY
    pop dx
    inc dx
    pop ax
    cmp vatCurY,ax
    jbe @@cpy
@@end:
    pop ds
    pop es
    popa
    restore_sp_bp
    ret 12
ENDP SaveScreen
;------------------------------------------------------------------------
; Copy ScreenCache into the screen memory (x,y)
;
; Input: 
;   memAddress = memory variable offset that stores the data. Should be in the right length (w*h)
;   memAddressSeg - segment of memAddress
;   x = top left X coordinate (must be 0..320-width)
;   y = top left Y coordinate (must be 0..200-height)
;   w = width of the area to copy
;   h = height of the area to copy
;
; WriteScreen(word *memAddress, word x, word y, word w, word h)
;------------------------------------------------------------------------
PROC WriteScreen
    store_sp_bp
    sub sp, 2

    pusha
    push es
    push ds

    ; now the stack is
    ; bp-2 => current y
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => h
    ; bp+6 => w
    ; bp+8 => y
    ; bp+10 => x
    ; bp+12 => memSeg
    ; bp+14 => *memAddress
    ; saved registers

    ;{
    rectHeight      equ         [word bp+4]
    rectWidth       equ         [word bp+6]
    yCoord          equ         [word bp+8]
    xCoord          equ         [word bp+10]
    memSeg          equ         [word bp+12]    
    memAddress      equ         [word bp+14]    

    vatCurY         equ         [word bp-2]
    ;}
    
    is_valid_coord_vga_mem bp+10,bp+8,bp+6,bp+4
    cmp ax,1
    je @@end                      ; invalid coords
    
    ; set DS
    push [WORD _dss]
    pop ds
    ; set ES
    push [WORD GR_START_ADDR]
    pop es

    mov ax, rectHeight
    add ax, yCoord                   ; ax = yBottom
    mov bx, yCoord                   ; bx = current y on screen
    mov vatCurY, bx
    mov dx, 0                             ; dx = current y in buffer
@@cpy:    
    push ax
    push dx
    ; set DI
    translate_coord_to_vga_addr bp+10,bp-2
    ; set SI
    mov si, memAddress
    mov ax, dx
    mov dx, rectHeight
    mul dx              ; y * height
    add si, ax

    push memSeg
    pop ds
    ; set length
    mov cx, rectWidth
    ; copy DS:SI to ES:DI
    cld  
    rep movsb
    inc vatCurY
    pop dx
    inc dx
    pop ax    
    cmp vatCurY,ax
    jbe @@cpy
@@end:
    pop ds
    pop es
    popa
    restore_sp_bp
    ret 12
ENDP WriteScreen
;------------------------------------------------------------------------
; Writes BLACK to a (x,y) coordinates
;
; Input: 
;   x = top left X coordinate (must be 0..320-width)
;   y = top left Y coordinate (must be 0..200-height)
;   w = width of the area to copy
;   h = height of the area to copy
;
; WriteBlackScreen(word x, word y, word w, word h)
;------------------------------------------------------------------------
PROC WriteBlackScreen 
    store_sp_bp
    sub sp, 2
    pusha
    push es
    push ds
    
    ; now the stack is
    ; bp-2 => current y
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => h
    ; bp+6 => w
    ; bp+8 => y
    ; bp+10 => x
    ; saved registers

    ;{
    rectHeight      equ         [word bp+4]
    rectWidth       equ         [word bp+6]
    yCoord          equ         [word bp+8]
    xCoord          equ         [word bp+10]

    vatCurY         equ         [word bp-2]
    ;}
    
     
    is_valid_coord_vga_mem bp+10,bp+8,bp+6,bp+4
    cmp ax,1
    je @@end                      ; invalid coords

    ; set ES and DS
    push [WORD GR_START_ADDR]
    pop es
    push [WORD _dss]
    pop ds

    mov dx, rectHeight         ; h
    add dx, yCoord         ; dx = yBottom
    mov bx, yCoord         ; bx = current y on screen
    mov vatCurY, bx
    xor ax,ax
    mov al, GR_COLOR_BLACK
@@cpy:    
    ; set DI
    translate_coord_to_vga_addr bp+10,bp-2
    ; set length
    mov cx, rectWidth
    ; copy DS:SI to ES:DI
    cld  
    rep stosb
    inc vatCurY
    cmp vatCurY,dx
    jbe @@cpy
@@end:
    pop ds
    pop es
    popa
    restore_sp_bp
    ret 8
ENDP WriteBlackScreen


;////////////////////////////////////////////////////////////////////////////
; FUNCTION LIKE MACROS
;////////////////////////////////////////////////////////////////////////////

;----------------------------------------------------------------------
; Copy a posrtion of the screen (x,y) into ScreenCache
;
; grm_SaveScreen (memAddress, memSeg, x, y, w, h)
;----------------------------------------------------------------------
MACRO grm_SaveScreen memAddress, memSeg, x, y, w, h
    push memAddress
    push memSeg
    push x
    push y
    push w
    push h
    call SaveScreen
ENDM

;----------------------------------------------------------------------
; Copy ScreenCache into the screen memory (x,y)
;
; grm_WriteScreen (memAddress, memSeg, x, y, w, h)
;----------------------------------------------------------------------
MACRO grm_WriteScreen memAddress, memSeg, x, y, w, h
    push memAddress
    push memSeg
    push x
    push y
    push w
    push h
    call WriteScreen
ENDM

;----------------------------------------------------------------------
; Copy ScreenCache into the screen memory (x,y)
;
; grm_WriteBlackScreen (x, y, w, h)
;----------------------------------------------------------------------
MACRO grm_WriteBlackScreen x, y, w, h
    push x
    push y
    push w
    push h
    call WriteBlackScreen
ENDM
