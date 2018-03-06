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
;   memStore = memory variable offset that stores the data. Should be in the right length (w*h)
;   x = top left X coordinate (must be 0..320-width)
;   y = top left Y coordinate (must be 0..200-height)
;   w = width of the area to copy
;   h = height of the area to copy
;
; SaveScreen(word *memStore, word x, word y, word w, word h)
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
    ; bp+12 => *memStore
    ; saved registers

    is_valid_coord_vga_mem bp+10,bp+8,bp+6,bp+4
    cmp ax,1
    je @@end                      ; invalid coords

    ; set ES
    push [WORD _dss]
    pop es
    ; set DS
    push [WORD GR_START_ADDR]
    pop ds
    mov ax, [word bp+4]
    add ax, [word bp+8]
    mov bx, [word bp+8]
    mov [word bp-2], bx
    mov dx,0            ; dx = row in buffer
@@cpy:    
    push ax
    push dx
    ; set SI
    translate_coord_to_vga_addr bp+10,bp-2
    mov si, di
    ; set DI
    mov di, [word bp+12]
    mov ax, dx
    mov dx, [word bp+4]
    mul dx              ; y * height
    add di, ax
    ; set length
    mov cx, [word bp+6]
    ; copy DS:SI to ES:DI
    cld  
    rep movsb
    inc [word bp-2]
    pop dx
    inc dx
    pop ax
    cmp [word bp-2],ax
    jbe @@cpy
@@end:
    pop ds
    pop es
    popa
    restore_sp_bp
    ret 10
ENDP SaveScreen
;------------------------------------------------------------------------
; Copy ScreenCache into the screen memory (x,y)
;
; Input: 
;   memStore = memory variable offset that stores the data. Should be in the right length (w*h)
;   x = top left X coordinate (must be 0..320-width)
;   y = top left Y coordinate (must be 0..200-height)
;   w = width of the area to copy
;   h = height of the area to copy
;
; WriteScreen(word *memStore, word x, word y, word w, word h)
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
    ; bp+12 => *memStore
    ; saved registers
    
    is_valid_coord_vga_mem bp+10,bp+8,bp+6,bp+4
    cmp ax,1
    je @@end                      ; invalid coords
    
    ; set DS
    push [WORD _dss]
    pop ds
    ; set ES
    push [WORD GR_START_ADDR]
    pop es

    mov ax, [word bp+4]
    add ax, [word bp+8]                   ; ax = yBottom
    mov bx, [word bp+8]                   ; bx = current y on screen
    mov [word bp-2], bx
    mov dx, 0                             ; dx = current y in buffer
@@cpy:    
    push ax
    push dx
    ; set DI
    translate_coord_to_vga_addr bp+10,bp-2
    ; set SI
    mov si, [word bp+12]
    mov ax, dx
    mov dx, [word bp+4]
    mul dx              ; y * height
    add si, ax
    ; set length
    mov cx, [word bp+6]
    ; copy DS:SI to ES:DI
    cld  
    rep movsb
    inc [word bp-2]
    pop dx
    inc dx
    pop ax    
    cmp [word bp-2],ax
    jbe @@cpy
@@end:
    pop ds
    pop es
    popa
    restore_sp_bp
    ret 10
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
     
    is_valid_coord_vga_mem bp+10,bp+8,bp+6,bp+4
    cmp ax,1
    je @@end                      ; invalid coords

    ; set ES and DS
    push [WORD GR_START_ADDR]
    pop es
    push [WORD _dss]
    pop ds

    mov dx, [word bp+4]         ; h
    add dx, [word bp+8]         ; dx = yBottom
    mov bx, [word bp+8]         ; bx = current y on screen
    mov [word bp-2], bx
    xor ax,ax
    mov al, GR_COLOR_BLACK
@@cpy:    
    ; set DI
    translate_coord_to_vga_addr bp+10,bp-2
    ; set length
    mov cx, [word bp+6]
    ; copy DS:SI to ES:DI
    cld  
    rep stosb
    inc [word bp-2]
    cmp [word bp-2],dx
    jbe @@cpy
@@end:
    pop ds
    pop es
    popa
    restore_sp_bp
    ret 8
ENDP WriteBlackScreen
