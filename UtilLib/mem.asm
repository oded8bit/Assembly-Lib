;===================================================================================================
; Memory Allocations
;
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Package: XXX
;
; Description: 
; Allows allocating and freeing memory on RAM
;===================================================================================================
LOCALS @@

DATASEG
    MAX_MALLOC_SEGS         equ         50
    _programMemFreed        db          FALSE
    _allocatedSegments      dw          MAX_MALLOC_SEGS dup(0)
    _allocatedSegmentsIndex dw          0
CODESEG

;+-+-+-+-+-+-+-+-+ HEAP MNGM. +-+-+-+-+-+-+-+-++-+-+-+-+-+
; Before allocating new memory on the heap, 
; call HeapFreeUnused 
;
; since When DOS executes a program, 
; it gives all of the available memory, from the start of that
; program to the end of RAM, to the executing process. 
; Any attempt to allocate memory without first giving unused 
; memory back to the system will produce an “insufficient
; memory” error. 
; 
; This PROC should be called before allocating memory
;
; call HeapReset 
;----------------------------------------------------------
PROC FreeProgramMem
    store_sp_bp
    mov	dx,ss		; Stack segment
    mov	bx,256 / 16 + 1 ; stack size in paragraphs
    add	bx,dx		; BX = end
    mov	ax,es		; ES = PSP (start)
    sub	bx,ax		; BX = new size in paragraphs
    mov	ah,4Ah
    int	21h
    mov [_programMemFreed], TRUE
    restore_sp_bp
    ret
ENDP FreeProgramMem

;----------------------------------------------------------
; Allocate memory on the heap
;
; push size             (in paragraphs)    (2000h = 128 KB)
; call malloc
;
; Parag = bytes / 16
;
; Return value: 
; AX = segment address of allocated memory block (MCB + 1para)
;	     0 on error 
; BX = size in paras of the largest block of memory available
;	     0 on error
; CF = 0 if successful
;	   = 1 if error
; Allocated memory is at AX:0000
;----------------------------------------------------------
PROC malloc
    store_sp_bp
    push cx di
    cmp [_programMemFreed], TRUE
    jne @@error
    
    clc
    mov bx, [word bp+4]
    mov ah, 48h
    int 21h  
    jc  @@error
    mov cx, [_allocatedSegmentsIndex]               ; cx = index    
    shl cx, 1                                       ; index * 2 (counts words)
    mov di, offset _allocatedSegments
    add di, cx
    mov [di], ax                                    ; save allocated segment
    inc [_allocatedSegmentsIndex]                   ; increment index
    jmp @@ok
@@error:  
    mov ax,0
    mov bx,0
@@ok:  
    pop di cx
    restore_sp_bp
    ret 2
ENDP malloc
;----------------------------------------------------------
; Free memory on the heap
;
; push addr             (address of block)
; call mfree
;
; Return value: ax register is a pointer to the memory
; or 0 on error
;----------------------------------------------------------
PROC mfree
    store_sp_bp
    push es

    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => addr
    ; saved registers    

    ;{
     addr_      equ         [word bp+4]   
    ;}

    push addr_
    pop es
    mov ah, 49h
    int 21h
    
    pop es
    restore_sp_bp
    ret 2
ENDP mfree
;----------------------------------------------------------
; Free all allocated segments on the heap
;
; call mfreeAll
;
; Return value: ax register is a pointer to the memory
; or 0 on error
;----------------------------------------------------------
PROC mfreeAll
    store_sp_bp
    sub sp,2
    push es cx bx

    ; now the stack is
    ; bp-2=> index
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; saved registers    

    ;{
    index_      equ     [word bp-2]
    ;}
    
    mov index_, 0
    mov cx, [_allocatedSegmentsIndex]
    cmp cx, 0
    je @@ok                     ; nothing to release
    
@@fr:    
    mov bx, index_
    shr bx,1                    ; index * 2 (counts in words)
    add bx, offset _allocatedSegments

    push [word bx]
    pop es                      ; es = segment

    mov ah, 49h
    int 21h                     ; free

    inc index_                  ; index++
    loop @@fr
@@ok:    
    pop bx cx es
    restore_sp_bp
    ret
ENDP mfreeAll
;----------------------------------------------------------
; Copies memory from one address to another
;
; push from address
; push from seg
; push to address
; push to seg
; push length in bytes
; call MemCpy
;----------------------------------------------------------
PROC MemCpy
    store_sp_bp
    push ax
    push cx
    push di
    push si
    push ds
    push es

    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => length
	; bp+6 => to seg
	; bp+8 => to addr
	; bp+10 => from seg
	; bp+12 => from addr
	; saved registers

    mov si, [WORD bp+12]       ; from
    mov ds, [WORD bp+10]       ; from seg
    mov di, [WORD bp+8]        ; to
    mov es, [WORD bp+6]        ; to seg

    ; ds:si => es:di
    mov cx, [WORD bp+4]        ; length
    cld
    rep movsb

    pop es
    pop ds
    pop si
    pop di
    pop cx
    pop ax
    restore_sp_bp
    ret 10
ENDP MemCpy
;----------------------------------------------------------
;
;----------------------------------------------------------
MACRO translate_coord_to_addr reg, mem_w, x, y
    push ax
    push bx
    push cx
    mov ax, [WORD y]
    mov bx, [WORD mem_w]
    mul bx
    mov cx, ax
    add cx, [WORD x]
    mov reg, cx
    pop cx
    pop bx
    pop ax
ENDM
;----------------------------------------------------------
; Copies memscreen area from screen address (seg es) to 
; another memory 
;
; push video segment
; push x1
; push y1
; push x2
; push y2
; push to address
; push to seg
; push mem width
; call ScreenCpy
;----------------------------------------------------------
PROC ScreenCpyFrom
    store_sp_bp
    sub sp,4
    push ax
    push cx
    push di
    push si
    push ds
    push es

    ; now the stack is
    ; bp-4 => x
    ; bp-2 => y
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => mem w
    ; bp+6 => to seg
    ; bp+8 => to addr
    ; bp+10 => y2
    ; bp+12 => x2
    ; bp+14 => y1
    ; bp+16 => x1
    ; bp+18 => video seg
    ; saved registers

    mov ds, [WORD bp+6]       ; target seg
    mov es, [WORD bp+18]      ; source video seg

@@rect__rect:
    push [word bp+14]         ; y1
    pop [word bp-2]           ; y = y1
@@rect__v:
    push [word bp+16]         ; x1
    pop [word bp-4]           ; x = x1
@@rect__h:
    translate_coord_to_addr di, 320, bp-4, bp-2   ; source addr
    translate_coord_to_addr si, bp+4, bp+18, bp+16 ; target addr
    push [WORD es:di]
    pop [WORD ds:si]
    ;gr_set_pixel [bp-4], [bp-2], [gr_pen_color] ; draw pixel at (x1,y1)
    inc [word bp-4]               ; x1++
    cmpv [bp-4], [bp+12], ax       
    jl @@rect__h          ; if (x1 < x2) goto GR_draw_rect__h
    inc [word bp-2]                    ; y++
    cmpv [bp-2], [bp+10], ax
    jl @@rect__v          ; if (y1 < y2) goto GR_draw_rect__v

    pop es
    pop ds
    pop si
    pop di
    pop cx
    pop ax
    restore_sp_bp
    ret 16
ENDP ScreenCpyFrom
;----------------------------------------------------------
; Copies memscreen area from screen address (seg es) to 
; another memory 
;
; push video segment
; push x1
; push y1
; push x2
; push y2
; push from address
; push from seg
; push mem width
; call ScreenCpy
;----------------------------------------------------------
PROC ScreenCpyTo
    store_sp_bp
    sub sp,4
    push ax
    push cx
    push di
    push si
    push ds
    push es

    ; now the stack is
    ; bp-4 => x
    ; bp-2 => y
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => mem w
    ; bp+6 => to seg
    ; bp+8 => to addr
    ; bp+10 => y2
    ; bp+12 => x2
    ; bp+14 => y1
    ; bp+16 => x1
    ; bp+18 => video seg
    ; saved registers

    mov ds, [WORD bp+6]       ; target seg
    mov es, [WORD bp+18]      ; source video seg
    xor ax,ax
  
@@rect__rect:
    push [word bp+14]         ; y1
    pop [word bp-2]           ; y = y1
@@rect__v:
    push [word bp+16]         ; x1
    pop [word bp-4]           ; x = x1
@@rect__h:
    translate_coord_to_addr di, 320, bp-4, bp-2   ; target addr
    translate_coord_to_addr si, bp+4, bp-4, bp-2 ; source addr
    mov al, [BYTE ds:si]
    mov [byte es:di],al
    ;gr_set_pixel [bp-4], [bp-2], [gr_pen_color] ; draw pixel at (x1,y1)
    inc [word bp-4]               ; x1++
    cmpv [bp-4], [bp+12], ax       
    jl @@rect__h          ; if (x1 < x2) goto GR_draw_rect__h
    inc [word bp-2]                    ; y++
    cmpv [bp-2], [bp+10], ax
    jl @@rect__v          ; if (y1 < y2) goto GR_draw_rect__v

    pop es
    pop ds
    pop si
    pop di
    pop cx
    pop ax
    restore_sp_bp
    ret 16
ENDP ScreenCpyTo
;----------------------------------------------------------
; Sets the content of the memory addressed by 
; Param1:Param2 for N bytes to the given value
;
; push 10         ; length in bytes
; push ds         ; segment
; push offset mem ; offset
; push value
; call SetMemByte
;----------------------------------------------------------
PROC SetMemByte
  store_sp_bp
  push ax                          
  push bx                  
  push cx        
  push es                          

  ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => param4 (value)
	; bp+6 => param3 (offset)
	; bp+8 => param2 (seg)
	; bp+10 => param1 (length)
	; saved registers

  mov cx, [WORD bp+4]              ; value
  mov ax, [WORD bp+10]             ; length
  test ax,ax                       ; See if the requested length is zero
  js   @@ZeroMemBEP                ; Jump to the end of the procedure if yes
  mov bx,[WORD PTR BP+6]           ; BX is now equal to the requested offset
  mov es,[WORD PTR BP+8]           ; ES is now equal to the requested segment
  @@ZeroMemBLoop:                  
    mov     [BYTE PTR ES:BX] , cl  ; Move one byte to ES:[BX]
    inc bx                         
    dec ax                         ; Decrement the counter
    jne  @@ZeroMemBLoop            
  pop es      
  pop cx
  pop bx                           
  pop ax                           
  @@ZeroMemBEP:                    
  restore_sp_bp
  ret 8
ENDP SetMemByte
;----------------------------------------------------------
; Sets the content of the memory addressed by 
; Param1:Param2 for N words to the given value
;
; push 10         ; length in words
; push ds         ; segment
; push offset mem ; offset
; push value
; call SetMemWord
;----------------------------------------------------------
PROC SetMemWord
  store_sp_bp
  push ax                          
  push bx      
  push cx                    
  push es                          

  ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => param4 (value)
	; bp+6 => param3 (offset)
	; bp+8 => param2 (seg)
	; bp+10 => param1 (length)
	; saved registers

  mov cx, [WORD bp+4]              ; value
  mov ax, [word bp+10]             ; length
  test ax,ax                       ; See if the requested length is zero
  js   @@ZeroMemWEP                ; Jump to the end of the procedure if yes
  mov bx,[WORD PTR BP+6]           ; BX is now equal to the requested offset
  mov es,[WORD PTR BP+8]           ; ES is now equal to the requested segment
  @@ZeroMemWLoop:                  
    mov     [WORD PTR ES:BX] , cx  ; Move one word to ES:[BX]
    add bx,2                         
    dec ax                         ; Decrement the counter
    jne  @@ZeroMemWLoop            
  pop es   
  pop cx
  pop bx                           
  pop ax                           
  @@ZeroMemWEP:                    
  restore_sp_bp
  ret 8
ENDP SetMemWord
