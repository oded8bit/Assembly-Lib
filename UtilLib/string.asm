;===================================================================================================
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: None
; Package: UtilLib
; Date: 17-03-2018
; File: string.asm
;
; Description: Handles null terminating strings
;===================================================================================================
LOCALS @@

CODESEG

;------------------------------------------------------------------------
; strlen: Calculates length of string ending with NULL
; 
; Input:
;     push  offset of string 
;     call strlen
; 
; Output: 
;     AX - string length 
; 
; Limitations: 
;   1. Assumes string are on DS
;   2. Assumes NULL terminating strings
;------------------------------------------------------------------------
PROC Strlen
    store_sp_bp
    push bx
    push cx

    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => param2 (offset)
	; saved registers

  xor cx,cx                        ; Counter
  mov bx, [WORD PTR bp+04h]        ; String
  @@StrLengthInnerLoop:            ; Inner loop
    mov ax,[WORD PTR bx]           ; Read 16 bits from the string
    test al,al                     ; See if AL is zero
    je  @@StrLengthEP              ; Jump to the EP if yes
    inc cx                         ; Increment the count register
    test ah,ah                     ; See if AH is zero
    je @@StrLengthEP               ; Jump to the EP if yes
    add bx,02h                     ; Navigate to the next two bytes of the string
    inc cx                         ; Increment the count register once again
    jmp @@StrLengthInnerLoop       ; Repeat
  @@StrLengthEP:                   
    mov ax,cx                      ; Move the length of the string to AX
    
    pop cx
    pop bx
    restore_sp_bp
    ret 2
ENDP Strlen
;------------------------------------------------------------------------
; StrlenDollar: Calculates length of string ending with '$'
; 
; Input:
;     push  offset of string 
;     call StrlenDollar
; 
; Output: 
;     AX - string length 
; 
; Limitations: 
;   1. Assumes string are on DS
;------------------------------------------------------------------------
PROC StrlenDollar
    store_sp_bp
    push bx
    push cx

    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => param2 (offset)
	; saved registers

  xor cx,cx                        ; Counter
  mov bx, [WORD PTR bp+04h]        ; String
  @@StrLengthInnerLoop:            ; Inner loop
    mov ax,[WORD PTR bx]           ; Read 16 bits from the string
    cmp al, '$'                    ; See if AL is $
    je  @@StrLengthEP              ; Jump to the EP if yes
    inc cx                         ; Increment the count register
    cmp ah, '$'                    ; See if AH is zero
    je @@StrLengthEP               ; Jump to the EP if yes
    add bx,02h                     ; Navigate to the next two bytes of the string
    inc cx                         ; Increment the count register once again
    jmp @@StrLengthInnerLoop       ; Repeat
  @@StrLengthEP:                   
    mov ax,cx                      ; Move the length of the string to AX
    
    pop cx
    pop bx
    restore_sp_bp
    ret 2
ENDP StrlenDollar
;------------------------------------------------------------------------
; Strcpy: Copies string s2 into string s1.
; 
; Input:
;     push  offset of source string (s2)
;     push  offset of target string (s1)
;     call strcpy
; 
; Output: 
;     AX - TRUE on success, FALSE on failure
; 
; Limitations: 
;   1. Assumes string are on DS
;   2. Assumes NULL terminating strings
;   3. Assumes S1 is long enough
;------------------------------------------------------------------------
PROC Strcpy
    push bp
    mov bp,sp
    push cx si di es
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => offset of source string (s2)
    ; bp+6 => offset of target string (s1)
    ; saved registers
 
    ;{
    parSrc_         equ        [word bp+4]
    parTrg_         equ        [word bp+6]
    ;}
 
    push parSrc_
    call strlen
    cmp ax, 0
    je @@emptyString
    mov cx, ax

    push ds
    pop es
    mov di, parTrg_
    mov si, parSrc_
    ; Move byte at address DS:SI to address ES:DI
    rep movsb

    mov [BYTE di+1],NULL
    mov ax, TRUE

    jmp @@end

@@emptyString:
    mov di, parTrg_
    mov [BYTE di],NULL
    mov ax, TRUE

@@end:
    pop es di si cx
    mov sp,bp
    pop bp
    ret 4
ENDP Strcpy
;------------------------------------------------------------------------
; Strcat: 
; 
; Input:
;     push  offset of source string 
;     push  offset of destination string
;     call Strcat
; 
; Output: 
;     AX - length of destination string
; 
; Affected Registers: 
; Limitations: 
;   1. Assumes string are on DS
;   2. Assumes NULL terminating strings
;   3. Assumes Destination is large enough to contain the concatenated 
;      resulting string
;------------------------------------------------------------------------
PROC Strcat
    push bp
    mov bp,sp
    sub sp, 4
    push cx di si es
 
    ; now the stack is
    ; bp-4 => original dest length
    ; bp-2 => src length
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => source
    ; bp+6 => destination 
    ; saved registers
 
    ;{
    varDestLen_    equ        [word bp-4]
    varSrcLen_     equ        [word bp-2]
    parSrc_        equ        [word bp+4]
    parDest_       equ        [word bp+6]
    ;}
 
    push parSrc_
    call Strlen
    mov varSrcLen_, ax
    mov cx, ax

    push parDest_
    call Strlen
    mov varDestLen_, ax

    push ds
    pop es
    mov di, parDest_
    add di, ax
    mov si, parSrc_
    ; Move byte at address DS:SI to address ES:DI
    rep movsb

    mov [BYTE di+1], NULL

    add ax, varSrcLen_  

@@end:
    pop es si di cx
    mov sp,bp
    pop bp
    ret 4
ENDP Strcat