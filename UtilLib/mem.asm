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
    mov	dx,ss		; Stack segment
    mov	bx,256 / 16 + 1 ; stack size in paragraphs
    add	bx,dx		; BX = end
    mov	ax,es		; ES = PSP (start)
    sub	bx,ax		; BX = new size in paragraphs
    mov	ah,4Ah
    int	21h
    ret
ENDP FreeProgramMem

;----------------------------------------------------------
; Allocate memory on the heap
;
; push size             (in paragraphs)    (2000h = 128 KB)
; call HeapAlloc
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
    clc
    mov bx, [word bp+4]
    mov ah, 48h
    int 21h  
    jc  @@error
    jmp @@ok
@@error:  
    mov ax,0
    mov bx,0
@@ok:  
ENDP malloc
;----------------------------------------------------------
; Free memory on the heap
;
; push addr             (address of block)
; call HeapAlloc
;
; Return value: ax register is a pointer to the memory
; or 0 on error
;----------------------------------------------------------
PROC mfree
    push es
    push [word bp+4]
    pop es
    mov ah, 49h
    int 21h
    pop es
ENDP mfree
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

