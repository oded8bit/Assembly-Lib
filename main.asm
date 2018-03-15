;===================================================================================================
; Assembly Library
;
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Package: AsmLib
;
; Description: 
; Testing program for the package
;===================================================================================================
LOCALS @@
.486
IDEAL
MODEL small
STACK 256

DATASEG
    _isGraphicsProgram     db          FALSE

CODESEG

    ; Include library (order is important!)
    include "UtilLib.inc"
    include "GrLib.inc"
    ; Include tests
    include "Tests/tests.asm"

start:
	mov ax, @data
	mov ds,ax

    mov ax, FALSE
    ut_init_lib ax

    ; if (_isGraphicsProgram) {
    cmp [_isGraphicsProgram], FALSE
    je notGraphics

        ; -- DOUBLE BUFFERING
        ; Free redundant memory take by program
        ; to allow using malloc
        ; call AllocateDblBuffer

        gr_set_video_mode_vga
        gr_set_color GR_COLOR_GREEN

    ;} else 
notGraphics:
    ;------ Tests
    call TestMe
   
exit:
    call WaitForKeypress 

    ; if (_isGraphicsProgram) {
    cmp [_isGraphicsProgram], FALSE
    je go_out
        ; -- DOUBLE BUFFERING   
        ; call ReleaseDblBuffer
        gr_set_video_mode_txt
    ;} else
go_out:    
    return 0

END start
CODSEG ends