;===================================================================================================
; Math Functions
;
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Package: UtilLib
;
; Description: 
; Several math related procedures
;
; For Linear congruential generator see
; https://en.wikipedia.org/wiki/Linear_congruential_generator#c.E2.89.A00
;
;===================================================================================================
LOCALS @@

DATASEG	
    _SeedVal  dw     (0)
CODESEG
;----------------------------------------------------------
; Creates a seed for calculating rand numbers
;----------------------------------------------------------
PROC RandomSeed
    push ax
    push dx
    mov     ah, 00h             ; interrupt to get system timer in CX:DX 
    int     1AH
    mov     [_SeedVal], dx
    pop dx
    pop ax
    ret
ENDP RandomSeed
;----------------------------------------------------------
; Gets a WORD random number
; Return result in ax
;----------------------------------------------------------
PROC RandomWord
    push dx
    mov     ax, 25173           ; LCG Multiplier
    mul     [WORD PTR _SeedVal] ; DX:AX = LCG multiplier * seed
    add     ax, 13849           ; Add LCG increment value
    ; Modulo 65536, AX = (multiplier*seed+increment) mod 65536
    mov     [_SeedVal], ax           ; Update seed = return value
    pop dx
    ret
ENDP RandomWord    
;----------------------------------------------------------
; Gets a BYTE random number
; Return result in al
;----------------------------------------------------------
PROC RandomByte
    call RandomWord
    and  ax,00ffh
    ret
ENDP RandomByte

;=========================================================================
; Other math functions
;=========================================================================

;----------------------------------------------------------
; Calculates the abs value of a register
;
; gr_absolute cx
;----------------------------------------------------------
MACRO gr_absolute a
	local absolute_l1
	cmp a, 0
	jge absolute_l1
	neg a
absolute_l1:
ENDM
