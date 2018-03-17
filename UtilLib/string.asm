;===================================================================================================
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: None
; Package: UtilLib
; Date: 17-03-2018
; File: string.asm
;
; Description: Handles null terminating strings. All strings are BYTE ARRAYS with ASCII chars
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
;     push  offset of target string (s1)
;     push  offset of source string (s2)
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

    mov [BYTE di],NULL
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
; Strncpy: Copies given number of chars from string s2 into string s1.
; 
; Input:
;     push  offset of target string (s1)
;     push  offset of source string (s2)
;     push  number of chars
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
PROC Strncpy
    push bp
    mov bp,sp
    push cx si di es
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => number of chars to copy
    ; bp+6 => offset of source string (s2)
    ; bp+8 => offset of target string (s1)
    ; saved registers
 
    ;{
    parNumChars_    equ        [word bp+4]
    parSrc_         equ        [word bp+6]
    parTrg_         equ        [word bp+8]
    ;}
 
    mov ax, parNumChars_
    cmp ax, 0
    je @@emptyString
    mov cx, ax

    push ds
    pop es
    mov di, parTrg_
    mov si, parSrc_
    ; Move byte at address DS:SI to address ES:DI
    rep movsb

    mov [BYTE di],NULL
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
ENDP Strncpy
;------------------------------------------------------------------------
; Strcat: concatenate 2 strings
; 
; Input:
;     push  offset of destination string
;     push  offset of source string 
;     call Strcat
; 
; Output: 
;     AX - length of destination string
; 
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

    mov [BYTE di], NULL

    add ax, varSrcLen_  

@@end:
    pop es si di cx
    mov sp,bp
    pop bp
    ret 4
ENDP Strcat
;------------------------------------------------------------------------
; Strchr: Searches for the first occurrence of the character in the 
; given string
; 
; Input:
;     push  string address
;     push the char
;     call Strchr
; 
; Output: 
;     AX - index of char or -1 if not found
; 
; Limitations: 
;   1. Assumes string are on DS
;   2. Assumes NULL terminating strings
;------------------------------------------------------------------------
PROC Strchr
    push bp
    mov bp,sp
    push bx cx dx si
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => char
    ; bp+6 => string address
    ; saved registers
 
    ;{
    parChar_        equ        [word bp+4]
    parStr_         equ        [word bp+6]
    ;}
 
    xor cx, cx                  ; counter
    mov si, parStr_
    mov bx, parChar_
@@check:   
    mov dl,[BYTE si]
    cmp dl, NULL
    je @@notfound               ; reached end of string - not found

    cmp dl, bl                  ; if string[counter] == char
    je @@found
    inc cx                      ; counter++
    inc si
    jmp @@check

@@notfound:
    mov ax,-1
    jmp @@end
@@found:
    mov ax, cx
@@end:
    pop si dx cx bx
    mov sp,bp
    pop bp
    ret 4
ENDP Strchr
;------------------------------------------------------------------------
; Strcmp: Compares the string pointed to, by str1 to the string pointed 
; to by str2.
; 
; Input:
;     push  str1 offset 
;     push  str2 offset 
;     call Strcmp
; 
; Output: 
;     AX - 0 if the same, -1 if different
; 
; Limitations: 
;   1. Assumes string are on DS
;   2. Assumes NULL terminating strings
;------------------------------------------------------------------------
PROC Strcmp
    push bp
    mov bp,sp
    push cx
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => str2 offset
    ; bp+6 => str1 offset
    ; saved registers
 
    ;{
    parstr2_        equ        [word bp+4]
    parStr1_        equ        [word bp+6]
    ;}
 
    mov si, parStr1_
    mov di, parStr2_
@@check:
    cmp [BYTE si], NULL
    je @@endof1

    ; if we got to the end of S2 but not of S1 then
    ; there is a miss match
    cmp [BYTE di], NULL
    je @@notmatch

    ; if (s1[index] == s2[index])
    mov cl, [BYTE si]
    cmp cl, [BYTE di]
    jne @@notmatch

    ; mov to next char
    inc si
    inc di

    jmp @@check

@@endof1:
    ; check if this is the end of s2 as well
    cmp [BYTE di],NULL
    jne @@notmatch

    ; match
    mov ax, 0

    jmp @@end
@@notmatch:
    mov ax, -1    
@@end:
    pop cx
    mov sp,bp
    pop bp
    ret 4
ENDP Strcmp
;------------------------------------------------------------------------
; Strstr: finds the first occurrence of the substring needle in the string 
; haystack
; 
; Input:
;     push  offset of haystack string
;     push  offset of needle string (what we are looking for)
;     call Strstr
; 
; Output: 
;     AX - index of subsctring or -1 if not found
; 
; Limitations: 
;   1. Assumes string are on DS
;   2. Assumes NULL terminating strings
;------------------------------------------------------------------------
PROC Strstr
    push bp
    mov bp,sp
    push bx cx dx si di
 
    ; now the stack is
    ; bp-2 => 
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => needle
    ; bp+6 => haystack
    ; saved registers
 
    ;{
    parHaystack_    equ        [word bp+6]
    parNeedle_      equ        [word bp+4]
    ;}

    xor cx, cx                  ; counter
    mov si, parHaystack_
    mov bx, parNeedle_
@@check:   
    mov dl,[BYTE si]
    cmp dl, NULL
    je @@notfound               ; reached end of string - not found

    cmp dl,[BYTE bx]            ; if haystack[counter] == needle[0]
    je @@foundFirst
@@next:
    inc cx                      ; counter++
    inc si
    jmp @@check

@@foundFirst:
    push cx si bx di dx

@@checknext:
    ; we already know the first char matches
    inc si                      ; index to haystack string. h++
    inc bx                      ; index to needle string n = 1

    mov dl,[BYTE si]            ; haystack[h]
    mov dh,[BYTE bx]            ; needle[n]

    ; if (haystack[h] == NULL && needle[n] == NULL) then this is a match else break
    cmp dl, NULL
    jne @@cont

    cmp dh, NULL
    je @@found

    ; hay is null but not neddle
    pop dx di bx si cx
    jmp @@next
@@cont:
    ; if (needle[n] == NULL) then we found a match
    cmp dh, NULL
    je @@found

    ; if (haystack[h] == needle[n])
    cmp dl,dh
    je @@checknext            ; the same, check next char

    ; else (no match) break
    pop dx di bx si cx
    jmp @@next
    

@@notfound:
    mov ax,-1
    jmp @@end
@@found:
    pop dx di bx si cx
    mov ax, cx
@@end:
    pop di si dx cx bx
    mov sp,bp
    pop bp
    ret 4
ENDP Strstr