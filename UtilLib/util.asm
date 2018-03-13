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
  _dss         dw    0        ; Saved DS segment
CODESEG
;------------------------------------------------------------------------
; Initialization - call at the beginning of your program
;------------------------------------------------------------------------
MACRO ut_init_lib freeMem
  local _out
  mov [_dss], ds
  cmp freeMem, FALSE
  je _out
  ; Free redundant memory take by program
  ; to allow using malloc
  call FreeProgramMem
_out:  
ENDM
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
;----------------------------------------------------------
; Gets the memory address of the specific (row,col) element
; in the 2d array of BYTES
;
; array2D[4][2] where 4 is the number of rows and 2 the 
; number of columns.
;
; Equivalent to a C# 2d array:
; byte[,] array2D = new byte[,] = {{1,2}, {3,4}, {5,6}, {7,8}}
;
; Input:
;   reg     - the register that will hold the result. Cannot be DX
;   address - offset of the 2d array (assuming ds segment)
;   row,col - of the required cell
;   rows_size - in the array
;
; Input cannot use AX or DX registers
;----------------------------------------------------------
MACRO getCellAddress2dArrayBytes reg, address, row, col, num_cols
  push dx
  mov ax, num_cols
  mov dx, row
  mul dx
  add ax, col
  add ax, address
  mov reg, ax
  pop dx
ENDM
;----------------------------------------------------------
; Gets the memory address of the specific (row,col) element
; in the 2d array of WORDS
;----------------------------------------------------------
MACRO getCellAddress2dArrayWords reg, address, row, col, num_cols
  mov ax, num_cols
  mov dx, row
  mul dx
  shl ax, 1       ; x2 for words
  add ax, col*2
  add ax, address
  mov reg, ax
ENDM
;----------------------------------------------------------
; Sets a byte value in the specific (row,col) element in the 
; 2d array
;----------------------------------------------------------
MACRO setByteValue2dArray value, address, row, col, num_cols
  push si
  getCellAddress2dArrayBytes si, address, row, col, num_cols
  mov [byte si], value
  pop si
ENDM
;----------------------------------------------------------
; Sets a word value in the specific (row,col) element in the 
; 2d array
;----------------------------------------------------------
MACRO setWordValue2dArray value, address, row, col, num_cols
  push si
  getCellAddress2dArrayWords si, address, row, col, num_cols
  mov [word si], value
  pop si
ENDM
;----------------------------------------------------------
; Gets a byte value in the specific (row,col) element in the 
; 2d array
;----------------------------------------------------------
MACRO getByteValue2dArray address, row, col, num_cols
  push si
  getCellAddress2dArrayBytes si, address, row, col, num_cols
  mov ax, [byte si]
  pop si
ENDM
;----------------------------------------------------------
; Gets a word value in the specific (row,col) element in the 
; 2d array
;----------------------------------------------------------
MACRO getWordValue2dArray address, row, col, num_cols
  push si
  getCellAddress2dArrayWords si, address, row, col, num_cols
  mov ax, [word si]
  pop si
ENDM