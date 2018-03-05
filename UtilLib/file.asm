;===================================================================================================
; File Handling
;
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Package: UtilLib
;
; Description: 
; Set of procedures for reading, writing and manipulating files
; This library allows managing a single file at a time, using the glabl variables _fHandle and _fErr
;===================================================================================================
LOCALS @@

CODESEG
    ; These vars are defined in CODESEG
    _fHandle     dw      0		; Handler
    _fErr    	db      0		; DOS error code

;------------------------------------------------------------------
; Open a file
;
; push address of file name
; push segment of file name
; call Fopen
;
; Output:
;   _fHandle, _fErr
;------------------------------------------------------------------
PROC fopen
    store_sp_bp
    pusha	
    push ds
    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => seg
	; bp+6 => addr
	; saved registers    
    mov dx, [WORD bp+6]    	    ; address
    push [WORD bp+4]            ; seg
    pop ds
	mov ax,3D02h
	int 21h
	mov bl,0
	jnc @@fopen0
	mov bl,al
	sub ax,ax
@@fopen0: 
    mov [cs:_fHandle],ax
	mov [cs:_fErr],bl
    pop ds
	popa
    restore_sp_bp
	ret 4
ENDP fopen
;------------------------------------------------------------------
; Creates a file
;
; push segment of file name
; push address of file name
; call Fnew
;
; Output:
;   _fHandle, _fErr
;------------------------------------------------------------------
PROC fnew
    store_sp_bp
    pusha	
    push ds
    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => seg
	; bp+6 => addr
	; saved registers    
    mov dx, [WORD bp+6]    	    ; address
    push [WORD bp+4]            ; seg
    pop ds
	mov ah,3ch
	mov cx,0	                ; attr
	int 21h
	mov bl,0
	jnc @@fnew0
	mov bl,al
	sub ax,ax
@@fnew0:	
    mov [cs:_fHandle],ax
	mov [cs:_fErr],bl
    pop ds
	popa
    restore_sp_bp
	ret 4
ENDP fnew
;------------------------------------------------------------------
; Close a file
;
; call Fclose
;
; Output:
;   _fHandle, _fErr
;------------------------------------------------------------------
PROC fclose
    store_sp_bp
    pusha	
	mov bx,[cs:_fHandle]
	mov ah,3eh
	int 21h
	mov bl,0
	jnc @@fclose0
	mov bl,al
	sub ax,ax
@@fclose0:
    mov [cs:_fErr],bl
	mov [cs:_fHandle],ax
	popa
    restore_sp_bp
	ret
ENDP fclose
;------------------------------------------------------------------
; Reads from a file
;
; push length
; push address of buffer
; push seg of buffer
; call Fread
;
; Output:
;   _fHandle, _fErr
;   ax - number of bytes read
;------------------------------------------------------------------
PROC fread
    store_sp_bp
    pusha	
    push ds
    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => seg
	; bp+6 => addr
    ; bp+8 => length
	; saved registers        
    mov dx, [WORD bp+6]    	    ; address
    push [WORD bp+4]            ; seg
    pop ds
    mov cx, [WORD bp+8]         ; length
	mov bx,[cs:_fHandle]
	mov ah,3Fh
	int 21h
	mov bl,0
	jnc @@fread0
	mov bl,al
	sub ax,ax
@@fread0:	
    mov [cs:_fErr],bl
    pop ds
	popa
    restore_sp_bp
	ret 6
ENDP fread
;------------------------------------------------------------------
; Reads from a file
;
; push length
; push segment of buffer
; push address of buffer
; call Fwrite
;
; Output:
;   _fHandle, _fErr
;   ax - number of bytes written
;------------------------------------------------------------------
PROC fwrite
    store_sp_bp
    pusha	
    push ds
    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => seg
	; bp+6 => addr
    ; bp+8 => length
	; saved registers        
    mov dx, [WORD bp+6]    	    ; address
    push [WORD bp+4]            ; seg
    pop ds
    mov cx, [WORD bp+8]         ; length
    mov bx,[cs:_fHandle]
	mov ah,40h
	int 21h
	mov bl,0
	jnc @@fwrite0
	mov bl,al
	sub ax,ax
@@fwrite0:
    mov [cs:_fErr],bl
    pop ds
	popa
    restore_sp_bp
	ret 6
ENDP fwrite
;------------------------------------------------------------------
; Delete a file
;
; push segment of file name
; push address of file name
; call Fdelete
;
; Output:
;   _fHandle, _fErr
;------------------------------------------------------------------
PROC fdelete
    store_sp_bp
    pusha	
    push ds
    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => seg
	; bp+6 => addr
	; saved registers    
    mov dx, [WORD bp+6]    	    ; address
    push [WORD bp+4]            ; seg
    pop ds
	mov ah,41h
	int 21h
	mov bl,0
	jnc @@fdel0
	mov bl,al
@@fdel0:	
    mov [cs:_fErr],bl
    pop ds
	popa
    restore_sp_bp
	ret 4
ENDP fdelete
;------------------------------------------------------------------
; Change attribute of a file
;
; push attribute
; push segment of file name
; push address of file name
; call FchangeAttr
;
; Output:
;   _fHandle, _fErr
;------------------------------------------------------------------
PROC fchangeAttr
    store_sp_bp
    pusha	
    push ds
    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => seg
	; bp+6 => addr
    ; bp+8 => attr
	; saved registers    
    mov dx, [WORD bp+6]    	    ; address
    push [WORD bp+4]            ; seg
    pop ds
    mov cx, [WORD bp+8]         ; attr
	mov ax,4301h	            ;4300 pre attr read => cx ... uprav push/pop
	int 21h		                ;		7 6 5 4 3 2 1 0
	mov bl,0	                ;cx = attr: 	0 0 A 0 0 S H R
	jnc @@fattr0
	mov bl,al
@@fattr0:	
    mov [cs:_fErr],bl
    pop ds
	popa
    restore_sp_bp
	ret 6
ENDP fchangeAttr

;////////////////////////////////////////////////////////////////////////////
; FUNCTION LIKE MACROS
;////////////////////////////////////////////////////////////////////////////

;----------------------------------------------------------------------
; Open a file
;
; utm_fopen (pathOffset, pathSegment)
;----------------------------------------------------------------------
MACRO utm_fopen pathOffset, pathSegment
    push pathOffset
    push pathSegment
    call fopen
ENDM
;----------------------------------------------------------------------
; Creates a new file
;
; utm_fnew (pathOffset, pathSegment)
;----------------------------------------------------------------------
MACRO utm_fnew pathOffset, pathSegment
    push pathOffset
    push pathSegment
    call fnew
ENDM
;----------------------------------------------------------------------
; Close a file
;
; utm_fclose
;----------------------------------------------------------------------
MACRO utm_fclose
    call fclose
ENDM
;----------------------------------------------------------------------
; Write to a file
;
; utm_fwrite (length, bufOffset, bufSegment)
;----------------------------------------------------------------------
MACRO utm_fqrite length, bufOffset, bufSegment
    push length
    push bufOffset
    push bufSegment
    call fwrite
ENDM
;----------------------------------------------------------------------
; Deletes a file
;
; utm_fdelete (pathOffset, pathSegment)
;----------------------------------------------------------------------
MACRO utm_fdelete pathOffset, pathSegment
    push pathOffset
    push pathSegment
    call fdelete
ENDM
;----------------------------------------------------------------------
; Change attribute of a file
;
; utm_fdelete (pathOffset, pathSegment)
;----------------------------------------------------------------------
MACRO utm_fchangeAttr attrib, pathOffset, pathSegment
    push attrib
    push pathOffset
    push pathSegment
    call fchangeAttr
ENDM