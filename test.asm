;===================================================================================================
; Assembly Library
;
; File Name: test.asm
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
	stack 256

DATASEG



CODESEG

    ; Include library (order is important!)
    include "UtilLib.inc"
    include "GrLib.inc"
    ; Include tests
    include "Tests/tests.asm"

start:
	mov ax, @data
	mov ds,ax

    ; Free redundant memory take by program
    ; to allow using malloc
    call FreeProgramMem

    ut_init_lib
    gr_set_video_mode_vga
    gr_set_color GR_COLOR_GREEN


    ;----- NO PASS
    ;call TestBmp
    call TestShapes
    ;;;;call TestSprite
    ;;;;call TestAnim
    ;;;;call TestMySprite
    ;;;;call TestDblBuffering
    
    ;------ PASS
    ;call TestSound
    ;call TestRandomAndPrint
    ;call TestPrint
   
exit:
    call WaitForKeypress    
    gr_set_video_mode_txt

    return 0

END start
CODSEG ends