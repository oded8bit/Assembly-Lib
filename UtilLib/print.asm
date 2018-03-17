;===================================================================================================
; Print to screen
;
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Package: UtilLib
;
; Description: 
; Manage printing test to the screen
;===================================================================================================
LOCALS @@

DATASEG
    _Hex    db  '0123456789ABCDEF'
CODESEG
;----------------------------------------------------------
; Prints a char to the screen
; Input: DL
;----------------------------------------------------------
PROC PrintChar
    push ax
    mov ah, 02h
    int 21h
    pop ax
    ret
ENDP PrintChar
;----------------------------------------------------------
; Prints a char to the screen + New line
; Input: DL
;----------------------------------------------------------
MACRO PrintCharNewLine
    call PrintChar
    call PrintNewLine
ENDM
;----------------------------------------------------------
; Prints a char to the screen
; Input: DL (number between 0 and 15)
;----------------------------------------------------------
PROC PrintByte
    push ax
    push bx
    cmp dl, 09h
    jbe @@lessthan10
    ; greater than 9

    cmp dl, 0fh
    ja @@more_f
    ; A..F
    sub dl, 0ah
    add dl, 'A'
    call PrintChar
    jmp @@end
    
@@more_f:
    mov bl, dl
    shr dl, 4
    call PrintByte
    mov dl, bl
    and dl, 0Fh
    call PrintByte
    jmp @@end

@@lessthan10:    
    add dl, '0'
    call PrintChar
@@end:    
    pop bx
    pop ax
    ret
ENDP PrintByte
;----------------------------------------------------------
; Prints a char to the screen + new line
; Input: DL
;----------------------------------------------------------
MACRO PrintByteNewLine
    call PrintByte
    call PrintNewLine
ENDM
;----------------------------------------------------------
; Prints a new line char to the screen
;----------------------------------------------------------
PROC PrintNewLine
    push dx
    mov dx, 0Ah
    call PrintChar
    pop dx
    ret
ENDP PrintNewLine
;----------------------------------------------------------
; Prints a space char to the screen
;----------------------------------------------------------
PROC PrintSpace
    push dx
    xor dx, dx
    mov dl, ' '
    call PrintChar
    pop dx
    ret
ENDP PrintSpace

;----------------------------------------------------------
; Prints a string to the screen
; Input: DS:DX pointer to string ending in "$"
;----------------------------------------------------------
PROC PrintStr 
    push ax
    mov ah, 09h
    int 21h
    pop ax
    ret
ENDP PrintStr
;----------------------------------------------------------
; Prints a NULL terminated string to the screen
; Input: DS:DX pointer to string ending in NULL
;----------------------------------------------------------
PROC PrintCStr
    push si bx ax
    push dx
    call Strlen
    mov bx, ax                  ; store length
    mov si, dx
    add si, bx
    mov [BYTE si], '$'
    mov ah, 09h
    int 21h

    mov [BYTE si], Null
    pop ax bx si
    ret
ENDP PrintCStr
;----------------------------------------------------------
; Prints a string to the screen + New line
; Input: DS:DX pointer to string ending in "$"
;----------------------------------------------------------
MACRO PrintStrNewLine
    call PrintStr
    call PrintNewLine
ENDM
;----------------------------------------------------------
; Prints a character on VGA display
; DL: char
; BL, color
;----------------------------------------------------------
PROC PrintCharVGA
    push ax
    push bx
    mov ah, 0Eh
    mov al, dl
    mov bh, 0
    ;mov bl, [gr_pen_color]
    int 10h
    pop bx
    pop ax
    ret
ENDP PrintCharVGA

;----------------------------------------------------------
; Prints a string to the VGA screen
;
; push color
; push offset string
; push x
; push y
; call PrintStrVGA
;----------------------------------------------------------
PROC PrintStrVGA
    store_sp_bp
    push ax
    push bx
    push cx

    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => y
	; bp+6 => x
	; bp+8 => offset
    ; bp+10 => color
	; saved registers

    push [word bp+8]
    call Strlen
    mov cx, ax              ; length

    mov al, 1               ; move cursor
    mov ah, 13h
    mov bh, 0               ; page
    mov bl, [BYTE bp+10]    ; attrib
    mov dh, [BYTE bp+4]     ; y
    mov dl, [BYTE bp+6]     ; x
    push bp
    push es

    push ds
    pop es
    mov bp, [word bp+8]     ; string es:bp
    int 10h                 ; write string

    pop es
    pop bp

@@loopend:
    pop cx
    pop bx
    pop ax
    restore_sp_bp
    ret 6
ENDP PrintStrVGA


;----------------------------------------------------------
; Set cursor position
;
; push x
; push y
; call SetCursorPosition
;----------------------------------------------------------
PROC SetCursorPosition
    store_sp_bp
    pusha

    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => y
    ; bp+6 => x
	; saved registers

    mov ah, 02
    mov bh, 0
    mov dh, [byte bp+4]
    mov dl, [byte bp+6]
    int 10h

    popa
    restore_sp_bp
    ret 4
ENDP SetCursorPosition
;================================================
; Description - Write on screen the value of ax (decimal)
;               the practice :  
;				Divide AX by 10 and put the Mod on stack 
;               Repeat Until AX smaller than 10 then print AX (MSB) 
;           	then pop from the stack all what we kept there and show it. 
; INPUT: AX
; OUTPUT: Screen 
; Register Usage: AX  
;================================================
proc PrintDecimal
       push ax
	   push bx
	   push cx
	   push dx
	   
	   ; check if negative
	   test ax,08000h
	   jz PositiveAx
			
	   ;  put '-' on the screen
	   push ax
	   mov dl,'-'
	   mov ah,2
	   int 21h
	   pop ax

	   neg ax ; make it positive
PositiveAx:
       mov cx,0   ; will count how many time we did push 
       mov bx,10  ; the divider
   
put_mode_to_stack:
       xor dx,dx
       div bx
       add dl,30h
	   ; dl is the current LSB digit 
	   ; we cant push only dl so we push all dx
       push dx    
       inc cx
       cmp ax,9   ; check if it is the last time to div
       jg put_mode_to_stack

	   cmp ax,0
	   jz pop_next  ; jump if ax was totally 0
       add al,30h  
	   mov dl, al    
  	   mov ah, 2h
	   int 21h        ; show first digit MSB
	       
pop_next: 
       pop ax    ; remove all rest LIFO (reverse) (MSB to LSB)
	   mov dl, al
       mov ah, 2h
	   int 21h        ; show all rest digits
       loop pop_next
		
	   pop dx
	   pop cx
	   pop bx
	   pop ax
	   
	   ret
endp PrintDecimal


PROC _Print4LSBHex
    store_sp_bp
    push ax bx dx
    mov ax, [word bp+4]         ; value
    xor ah,ah
	; mask received value without changing ax
	; leaving only 4 LSB
    mov dx, ax
	and dx, 000fh
	; get index into 'hex' array
	mov bx, offset _Hex
	add bx, dx
	
	; print char to STDOUT
	mov ah, 02h
	mov dl, [bx]
	int 21h

    pop dx bx ax
    restore_sp_bp
    ret 2
ENDP _Print4LSBHex

;----------------------------------------------------------
; Print byte as HEX
;
; push value
; call SetCursorPosition
;----------------------------------------------------------
PROC PrintHexByte
    store_sp_bp
    push ax

    mov ax, [word bp+4]
    push ax                 ; save for next char
	shr ax, 4
    push ax
	call _Print4LSBHex
	
    pop ax                  ; restore it
    push ax
	call _Print4LSBHex
	
    pop ax
    restore_sp_bp
    ret 2
ENDP PrintHexByte
;----------------------------------------------------------
; Print word as HEX
;
; push value
; call SetCursorPosition
;----------------------------------------------------------
PROC PrintHexWord
    store_sp_bp
    push ax

    mov ax, [word bp+4]
    push ax                 ; save for next char
	shr ax, 8
    push ax
	call PrintHexByte
	
    pop ax                  ; restore it
    push ax
	call PrintHexByte
	
    pop ax
    restore_sp_bp
    ret 2
ENDP PrintHexWord

;////////////////////////////////////////////////////////////////////////////
; FUNCTION LIKE MACROS
;////////////////////////////////////////////////////////////////////////////
 
;----------------------------------------------------------------------
; Set cursor position
;
; grm_SetCursorPosition (x,y)
;----------------------------------------------------------------------
MACRO utm_SetCursorPosition x, y
    push x
    push y
    call SetCursorPosition
ENDM
;----------------------------------------------------------------------
; Calculates length of string ending with NULL
;
; grm_Strlen (strOffset)
;----------------------------------------------------------------------
MACRO utm_Strlen strOffset
    push strOffset
    call Strlen
ENDM
;----------------------------------------------------------------------
; Prints a string to the VGA screen
;
; grm_PrintStrVGA (XX, XX)
;----------------------------------------------------------------------
MACRO utm_PrintStrVGA color, strOffset, x, y
    push color
    push strOffset
    push x
    push y
    call PrintStrVGA
ENDM
;----------------------------------------------------------------------
; Prints the LSB BYTE of a WORD in HEX
;
; grm_PrintHexByte (word value)
;----------------------------------------------------------------------
MACRO utm_PrintHexByte value
    push value
    call PrintHexByte
ENDM
;----------------------------------------------------------------------
; Prints a WORD in HEX
;
; utm_PrintHexWord (word value)
;----------------------------------------------------------------------
MACRO utm_PrintHexWord value
    push value
    call PrintHexWord
ENDM
