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
    push bx
    call Beep

    push 1
    call Sleep

    call StopBeep
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

    push 5
    push offset _polygon
    call GR_DrawPolygon
    
    gr_set_color GR_COLOR_YELLOW
    push 50 ; x
    push 50 ; y
    push 100 ; w
    push 100  ; h
    call GR_DrawRect

    gr_set_color GR_COLOR_RED
	push 1
	push 1
	push 100
	push 180
	call GR_DrawLine

    gr_set_color GR_COLOR_BLUE
    push 200 ; x
    push 20 ; y
    push 80 ; w
    push 50  ; h
    call GR_FillRect

    call WaitForKeypress    

    ;call GR_ClearScreen
    clear_screen
    call WaitForKeypress    

    gr_set_color GR_COLOR_BLUE
    push  200
    push  60
    push 50
    call GR_DrawCircle

    gr_set_color GR_COLOR_CYAN
    push  100
    push  90
    push 50
    call GR_FillCircle

    ret    
ENDP TestShapes