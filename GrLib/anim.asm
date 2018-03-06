;===================================================================================================
; Animations
;
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Package: GrLib
;
; Description: 
; Managing animations
;===================================================================================================
LOCALS @@

;---------------------------------------------------------------
; Plays a sprite in a given coords
;
; PlaySpriteInPlace(word index_to_draw, word bmp_struct_addr, 
;                   word bmp_struct_seg, word x, word y,
;                   word sprite_w, word num_sprites)
;
;---------------------------------------------------------------
PROC PlaySpriteInPlace
    store_sp_bp
    define_local_vars 6
    pusha
    push ds
    push es
    
    ; now the stack is
    ; bp-12 => sprite y
    ; bp-10 => img data ptr
    ; bp-8 => current y
    ; bp-6 => img width
    ; bp-4 => img height
    ; bp-2 => xTop
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => num_sprites
    ; bp+6 => sprite_w
    ; bp+8 => y
    ; bp+10 => x
    ; bp+12 => bmp_struct_seg
    ; bp+14 => bmp_struct_addr
    ; bp+16 => index_to_draw
    ; saved registers
   
    ;{
    varXTop             equ             [word bp-2]
    varXTop_            equ             bp-2
    varImgHeight        equ             [word bp-4]
    varImgHeight_       equ             bp-4
    varImgWidth         equ             [word bp-6]
    varImgWidth_        equ             bp-6
    varCurrY            equ             [word bp-8]
    varCurrY_           equ             bp-8
    varDataPtr          equ             [word bp-10]
    varDataPtr_         equ             bp-10
    varSpriteY          equ             [word bp-12]
    varSpriteY_         equ             bp-12

    frameIndex          equ             [word bp+16]
    structAddress       equ             [word bp+14]
    structSegment       equ             [word bp+12]
    xCoord              equ             [word bp+10]
    xCoord_             equ             bp+10
    yCoord              equ             [word bp+8]
    yCoord_             equ             bp+8
    spriteWidth         equ             [word bp+6]
    spriteWidth_        equ             bp+6
    numSprites          equ             [word bp+4]
    ;}

    mov ax, frameIndex                      ; index
    cmp ax, numSprites                      ; num frames
    jb @@frames_ok

    mov bx, numSprites                      ; num frames
    div bl

    shr ax,8                                ; mod stored in ah
    mov frameIndex,ax                       ; index = index mod frames

@@frames_ok:
    mov ax, frameIndex
    mul spriteWidth                     
    mov varXTop, ax                         ; xTop = x * sprite_w
   
    push structSegment 
    pop ds                                  ; ds = struct seg

    mov di, structAddress                   ; ds:di = struct ptr
    
    mov si, di
    add si, BMP_HEIGHT_OFFSET
    mov cx, [word ds:si]        
    mov varImgHeight, cx                    ; img Height
    mov dx, [word ds:si+2]      
    mov varImgWidth, dx                     ; Img Width

    is_valid_coord_vga_mem  xCoord_, yCoord_, spriteWidth_, varImgHeight_
    cmp ax,0
    ja @@err_coord

@@ok:
    mov varSpriteY,0

    push structAddress                       ; struct addr
    push structSegment                       ; struct seg    
    call SendPalStruct

    push [word GR_START_ADDR]
    pop es

    mov ax, yCoord                           ; yTop
    add ax, varImgHeight                     ; height
    mov varCurrY,ax                          ; y=Ytop+Height
    mov cx, varImgHeight                     ; height

    mov si, di
    add si, BMP_DATA_SEG_OFFSET
    mov varDataPtr,0

    push [word si]
    pop ds

    xor si,si
    xor di,di

    translate_coord_to_buf_addr varDataPtr_, varXTop_, varSpriteY_, varImgWidth_

    ; cx = height, ds:si = data, es:di = screen
 @@DrawLoop:
    push cx
    push si
    
    cld                                     ; Clear direction flag, for movsb.
    mov cx, spriteWidth                     ; sprite width
    translate_coord_to_vga_addr xCoord_, varCurrY_

    ; source DS:SI
    ; dest   ES:DI
    ; len    CX
    rep movsb                               ; Copy line in buffer to screen.
    pop si
    add si, varImgWidth                     ; si += img width

    dec varCurrY                            ; y--

    pop cx
    loop @@DrawLoop

    jmp @@end

@@err_coord:

@@end:   
    pop es
    pop ds
    popa
    restore_sp_bp
    ret 14
ENDP PlaySpriteInPlace

;////////////////////////////////////////////////////////////////////////////
; FUNCTION LIKE MACROS
;////////////////////////////////////////////////////////////////////////////

;----------------------------------------------------------------------
; 
;
; grm_XXXX (XXX, XXX)
;----------------------------------------------------------------------
MACRO grm_PlaySpriteInPlace index_to_draw, bmp_struct_addr, bmp_struct_seg, x, y, sprite_w, num_sprites
    push index_to_draw
    push bmp_struct_addr
    push bmp_struct_seg
    push x
    push y
    push sprite_w
    push num_sprites
    call PlaySpriteInPlace
ENDM
