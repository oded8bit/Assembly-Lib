;===================================================================================================
; General Utilities
;
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Package: UtilLib
;
; Description: 
; General common utilities 
;===================================================================================================
LOCALS @@

DATASEG
  TRUE        equ    1
  FALSE       equ    0

CODESEG
;----------------------------------------------------------
; called at the beginnig of each PROC to store
; and set BP value
;----------------------------------------------------------
MACRO store_sp_bp
    push bp
	mov bp,sp
ENDM
;----------------------------------------------------------
; called at the end of each PROC to restore 
; SP and BP
;----------------------------------------------------------
MACRO restore_sp_bp
    mov sp,bp
    pop bp
ENDM
;----------------------------------------------------------
; Create 'num' local variables
;----------------------------------------------------------
MACRO define_local_vars num
  sub sp, num*2
ENDM
;----------------------------------------------------------
; Toogles a boolean memory variable
;----------------------------------------------------------
MACRO toggle_bool_var mem
  local _setone, _endtog
  push ax
  mov ax, [mem]
  cmp ax, 0
  je _setone
  mov [mem], 0
  jmp _endtog
_setone:
  mov [mem],1
_endtog:  
  pop ax
ENDM
;----------------------------------------------------------
; Compare two memory variables
;----------------------------------------------------------
MACRO movv from, to
  push [WORD from]
  pop [WORD to]
ENDM
;----------------------------------------------------------
; Compare two memory variables
;----------------------------------------------------------
MACRO cmpv var1, var2, register
  mov register, var1
  cmp register, var2
ENDM
;----------------------------------------------------------
; Return control to DOS
; code = 0 is a normal exit
;----------------------------------------------------------
MACRO return code
  mov ah, 4ch
  mov al, code
  int 21h
ENDM