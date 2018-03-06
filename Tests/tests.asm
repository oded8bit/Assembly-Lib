;===================================================================================================
; Testings
;
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Package: AsmLib
;
; Description: 
; Various test to validate functionality
;===================================================================================================
LOCALS @@

DATASEG
    _bmp_file               db      "asset\\b.bmp",0
    _bmp                    db      BMP_STRUCT_SIZE dup(0)

    _sprite_w               equ     30
    _sprite_frames          equ     6
    _sprite_file            db      "asset\\sprite1.bmp",0
    _sprite                 db      BMP_STRUCT_SIZE dup(0)

    _polygon                dw      5,30,100,50,200,100,120,80,20,50

    _keyPressedMsg          db      "Key was pressed","$"

    _paletteFile            db      "asset\\bmp.pal",0
CODESEG

;///////////////////////////// BMP
PROC TestBmp

    mov dx, offset _bmp_file
    mov ax, offset _bmp
    grm_LoadBMPImage dx, [_dss], ax, [_dss]

    mov ax, offset _bmp
    grm_DisplayBMP  ax, [_dss], 0, 10

    mov ax, offset _bmp
    grm_FreeBmp ax, [_dss]

    ret
ENDP TestBmp

;///////////////////////////// SPRITES
PROC TestMySprite

    mov dx, offset _sprite_file
    mov ax, offset _sprite
    grm_LoadBMPImage dx, [_dss], ax, [_dss]

    mov bx,0
@@kk:
    grm_PlaySpriteInPlace bx, ax, ds, 0064h, 0064h, _sprite_w, _sprite_frames

    inc bx

    push 0003h
    call Delay

    cmp bx,_sprite_frames
    jb @@kk
    mov bx,0
    jmp @@kk           ; uncomment for infinite loop
@@outer:    
    ret
ENDP TestMySprite

;///////////////////////////// SOUND
PROC TestSound

    mov cx,3
    mov bx, 0122h
@@ss:
    utm_Beep bx
    utm_Sleep 1
    utm_StopBeep
    utm_Sleep 1
    add bx, 80h  
    
    loop @@ss
    ret
ENDP TestSound

;///////////////////////////// VGA PRINT
PROC TestRandomAndPrint
    call RandomSeed

    mov cx, 10
@@ddd:
    call RandomByte
    mov dx, ax
    ;PrintChar
    PrintByteNewLine
    call RandomByte
    mov dx, ax
    PrintByteNewLine
    ;PrintIntNewLine
    call RandomByte
    mov dx, ax
    PrintByteNewLine
    ;PrintIntNewLine
    loop @@ddd
    ret
ENDP TestRandomAndPrint

;///////////////////////////// PRINT 
PROC TestPrint
    mov dl, 0dfh
    call PrintByte
    ret
ENDP TestPrint

;///////////////////////////// SHAPES
PROC TestShapes
    mov ax, offset _polygon
    grm_DrawPolygon 5, ax


    gr_set_color GR_COLOR_YELLOW
    grm_DrawRect 50,50,100,100

    gr_set_color GR_COLOR_RED
    grm_DrawLine 1,1,100,100

    gr_set_color GR_COLOR_BLUE
    grm_FillRect 200,20,80,50

    call CopyDblBufToVideo

    call WaitForKeypress  
    
    clear_screen_vga
    call WaitForKeypress    

    gr_set_color GR_COLOR_BLUE
    grm_DrawCircle 200,60,50

    gr_set_color GR_COLOR_CYAN
    grm_FillCircle 100,90,50

    call CopyDblBufToVideo
@@exit:
    ret    
ENDP TestShapes

;///////////////////////////// GET KEY
PROC TestGetKey

    gr_set_video_mode_txt

@@top:    
    call GetKeyboardKey
    jnz @@cont
    
    push ax

    ; key was pressed
    mov dx, offset _keyPressedMsg
    call PrintStr

    call PrintSpace
    pop ax
    mov dx,ax
    call PrintChar

    cmp ax, SC_Q
    je @@exit

    utm_Sleep 1
    clear_screen_txt

@@cont:
    jmp @@top

@@exit:
    ret
ENDP TestGetKey

;///////////////////////////// SAVE PALETTE
PROC TestSavePalette
    mov dx, offset _bmp_file
    mov ax, offset _bmp
    grm_LoadBMPImage dx, [_dss], ax, [_dss]

    mov ax, offset _bmp
    mov bx, offset _paletteFile
    grm_SavePalette ax, [_dss], bx

    ret
ENDP TestSavePalette