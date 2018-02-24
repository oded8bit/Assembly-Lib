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

start:
	mov ax, @data
	mov ds,ax

    call FreeProgramMem
   
exit:
    return 0

END start
CODSEG ends