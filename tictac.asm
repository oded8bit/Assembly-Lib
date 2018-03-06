;===================================================================================================
; TicTac game
;
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Package: AsmLib
;
; Description: 
; A simple tictac game to demonstrate the library
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
    ; Include game
    include "Tests/tic/bg.asm"
    include "Tests/tic/game.asm"

start:
	mov ax, @data
	mov ds,ax

    mov ax, FALSE
    ut_init_lib ax

    ; -- DOUBLE BUFFERING
    ; Free redundant memory take by program
    ; to allow using malloc
    ; call AllocateDblBuffer

    gr_set_video_mode_vga
    gr_set_color GR_COLOR_GREEN
  
    call PlayTic
   
exit:
    ; -- DOUBLE BUFFERING   
    ; call ReleaseDblBuffer

    gr_set_video_mode_txt
    return 0

END start
CODSEG ends