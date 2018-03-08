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

DATASEG
    SEEK_SET        equ         0
    SEEK_CUR        equ         1 
    SEEK_END        equ         2

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
	mov ax,3F00h
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
; Write to a file
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
; Write a byte to a file
;
; push value (byte)
; call Fwrite
;
; Output:
;   _fHandle, _fErr
;   ax - number of bytes written
;------------------------------------------------------------------
PROC fwriteByte
    store_sp_bp
    pusha	
    push ds
    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => value
	; saved registers        
    mov dx, bp      	        ; value offset
    add dx, 4                   ; this is the bp+4 offset
    push ss                     ; on ss segment
    pop ds                      ; value seg
    mov cx, 1                   ; length
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
	ret 2
ENDP fwriteByte
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
;------------------------------------------------------------------------
; Seek in file
; 
; Input:
;     whence - SEEK_SET, SEEK_CUR, SEEK_END
;     offset_high - high order of offset
;     offset_low - low order of offset
;
;------------------------------------------------------------------------
PROC fseek
    store_sp_bp
    pusha
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => offset low
    ; bp+6 => offset high
    ; bp+8 => whence
    ; saved registers
 
    ;{
    whence        equ        [word bp+8]
    offsetHi      equ        [word bp+6]
    offsetLow     equ        [word bp+4]
    ;}

    cmp [cs:_fHandle], 0
    je @@end                ; file not open

    mov ax, whence

    cmp whence, SEEK_END
    je @@s_end

    mov cx, offsetHi
    mov dx, offsetLow
    jmp @@do_seek

@@s_end:
    xor cx, cx
    xor dx, dx

@@do_seek:
    mov bx, [cs:_fHandle]
    mov ah, 42h
    int 21h

@@end:
    popa
    restore_sp_bp
    ret 6
ENDP fseek
;------------------------------------------------------------------------
; Gets the size of a file
; 
; Input:
;     push file path address 
;     push file path segment
;     call ffilesize
; 
; Output:
;     DS:AX - file size, -1 on error
; 
; fsize( path, seg )
;------------------------------------------------------------------------
PROC fsize
    store_sp_bp
    push bx cx
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => file path seg
    ; bp+6 => file path address
    ; saved registers
 
    ;{
    pathSegment_        equ        [word bp+4]
    pathAddress_        equ        [word bp+6]
    ;}
 
    push pathAddress_ 
    push pathSegment_
    call fopen

    cmp [cs:_fErr], 0
    jne @@error                     ; cannot open file

    ; seek to end
    mov ah, 42h
    mov al, 2                       ; end of file plus offset  (SEEK_END)
    mov bx, [cs:_fHandle]
    xor cx, cx
    xor dx, dx
    int 21h                         ; will set dx:ax

    jnc @@close                     ; no error
    jmp @@error                     ; error

@@close:
    call fclose
    jmp @@end
@@error:
    call fclose
    mov ax,0ffffh
    mov dx,0ffffh
@@end:
    pop cx bx 
    restore_sp_bp
    ret 4
ENDP fsize
;------------------------------------------------------------------------
; Create folder
; 
; Input:
;     push folder path address 
;     push folder path segment
;     call mkdir
; 
; Output:
;   CF = 0 if successful
;	   = 1 if error
;	AX = error code
; 
; mkdir( path, seg )
;------------------------------------------------------------------------
PROC mkdir
    store_sp_bp
    push ds
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => folder path seg
    ; bp+6 => folder path address
    ; saved registers
 
    ;{
    pathSegment_        equ        [word bp+4]
    pathAddress_        equ        [word bp+6]
    ;}
    
    mov ah, 39h
    push pathSegment_
    pop ds
    mov dx, pathAddress_
    int 21h

@@end:
    pop ds 
    restore_sp_bp
    ret 4
ENDP mkdir
;------------------------------------------------------------------------
; Delete folder
; 
; Input:
;     push folder path address 
;     push folder path segment
;     call rmdir
; 
; Output:
;   CF = 0 if successful
;	   = 1 if error
;	AX = error code
; 
; rmdir( path, seg )
;------------------------------------------------------------------------
PROC rmdir
    store_sp_bp
    push ds
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => folder path seg
    ; bp+6 => folder path address
    ; saved registers
 
    ;{
    pathSegment_        equ        [word bp+4]
    pathAddress_        equ        [word bp+6]
    ;}
    
    mov ah, 3Ah
    push pathSegment_
    pop ds
    mov dx, pathAddress_
    int 21h

@@end:
    pop ds 
    restore_sp_bp
    ret 4
ENDP rmdir
;------------------------------------------------------------------------
; Delete folder
; 
; Input:
;     push folder path address 
;     push folder path segment
;     call rmdir
; 
; Output:
;   CF = 0 if successful
;	   = 1 if error
;	AX = error code
; 
; chdir( path, seg )
;------------------------------------------------------------------------
PROC chdir
    store_sp_bp
    push ds
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => folder path seg
    ; bp+6 => folder path address
    ; saved registers
 
    ;{
    pathSegment_        equ        [word bp+4]
    pathAddress_        equ        [word bp+6]
    ;}
    
    mov ah, 3Bh
    push pathSegment_
    pop ds
    mov dx, pathAddress_
    int 21h

@@end:
    pop ds 
    restore_sp_bp
    ret 4
ENDP chdir

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
; Gets file size
;
; utm_fsize (pathOffset, pathSegment)
;----------------------------------------------------------------------
MACRO utm_fsize pathOffset, pathSegment
    push pathOffset
    push pathSegment
    call fsize
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
MACRO utm_fwrite length, bufOffset, bufSegment
    push length
    push bufOffset
    push bufSegment
    call fwrite
ENDM
;----------------------------------------------------------------------
; Read from a file
;
; utm_fread (length, bufOffset, bufSegment)
;----------------------------------------------------------------------
MACRO utm_fread length, bufOffset, bufSegment
    push length
    push bufOffset
    push bufSegment
    call fread
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
;----------------------------------------------------------------------
; Write a single byte to file
;
; utm_fwriteByte (valueB)
;----------------------------------------------------------------------
MACRO utm_fwriteByte valueB
    push valueB
    call fwriteByte
ENDM
;----------------------------------------------------------------------
; Seek file
;
; grm_fseek (whence, offset_high, offset_low)
;----------------------------------------------------------------------
MACRO grm_fseek whence, offset_high, offset_low
    push whence
    push offset_high
    push offset_low
    call fseek
ENDM
;----------------------------------------------------------------------
; Create folder
;
; utm_mkdir (pathOffset, pathSegment)
;----------------------------------------------------------------------
MACRO utm_mkdir pathOffset, pathSegment
    push pathOffset
    push pathSegment
    call mkdir
ENDM
;----------------------------------------------------------------------
; Remove folder
;
; utm_rmdir (pathOffset, pathSegment)
;----------------------------------------------------------------------
MACRO utm_rmdir pathOffset, pathSegment
    push pathOffset
    push pathSegment
    call rmdir
ENDM
;----------------------------------------------------------------------
; Change folder
;
; utm_chdir (pathOffset, pathSegment)
;----------------------------------------------------------------------
MACRO utm_chdir pathOffset, pathSegment
    push pathOffset
    push pathSegment
    call chdir
ENDM
