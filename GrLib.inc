;===================================================================================================
; Assembly Graphics Library
;
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Package: GrLib
;
; Description: 
; Include this file to get access to the graphics library
;===================================================================================================

; Common definitions
BMP_STRUCT_SIZE         equ         444h

; Includes
include "GrLib\dblbuf.asm"
include "GrLib\colors.asm"
include "GrLib\graphx.asm"
include "GrLib\line.asm"
include "GrLib\rect.asm"
include "GrLib\poly.asm"
include "GrLib\circle.asm"
include "GrLib\bmp.asm"
include "GrLib\image.asm"
include "GrLib\anim.asm"
