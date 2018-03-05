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
    _bmp_file    db      "asset\\bat.bmp",0
    _bmp         db      BMP_STRUCT_SIZE dup(0)

    _polygon    dw     5,30,100,50,200,100,120,80,20,50

CODESEG

;///////////////////////////// BMP
PROC TestBmp

    push offset _bmp_file
    push [_dss]
    push offset _bmp
    push [_dss]
    call LoadBMPImage

    push offset _bmp
    push [_dss]
    push 10
    push 10
    call DisplayBMP

    call WaitForKeypress  

    push offset _bmp
    push [_dss]
    call FreeBmp

    ret
ENDP TestBmp

;///////////////////////////// SOUND
PROC TestSound

    mov cx,3
    mov bx, 0122h
@@ss:
    grm_Beep bx
    grm_Sleep 1
    grm_StopBeep
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
    
    clear_screen
    call WaitForKeypress    

    gr_set_color GR_COLOR_BLUE
    grm_DrawCircle 200,60,50

    gr_set_color GR_COLOR_CYAN
    grm_FillCircle 100,90,50

    call CopyDblBufToVideo
@@exit:
    ret    
ENDP TestShapes