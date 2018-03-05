;===================================================================================================
; Double Buffering
;
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Package: GrLib
;
; Description: 
; Double buffering implementation
;===================================================================================================
LOCALS @@

DATASEG
    _DblBufferSeg        dw              0
    _IsDblBuffer         db              FALSE
CODESEG
;------------------------------------------------------------------------
; MACRO Description: Sets whether we use double buffering
; 
; Input:
;     state - TRUE or FALSE
;------------------------------------------------------------------------
MACRO SetDoubleBuffering state
    mov [_IsDblBuffer], state
ENDM
;------------------------------------------------------------------------
; MACRO Description: saves double buffering segment
; 
; Input:
;     seg - the segment
;------------------------------------------------------------------------
MACRO SetDoubleBufferSeg seg
    mov [_DblBufferSeg], seg
ENDM
;------------------------------------------------------------------------
; MACRO Description: Gets double buffering segment into a register
; 
; Input:
;     reg - register
;------------------------------------------------------------------------
MACRO GetDblBufferSeg reg
    push [_DblBufferSeg]
    pop reg
ENDM
;------------------------------------------------------------------------
; MACRO Description: Is using double buffering
; 
; Input:
;     jmpIfTrue - label to jump to in case NOT using double buffering
;------------------------------------------------------------------------
MACRO IsDblBuffering jmpIfFalse
    cmp [_IsDblBuffer], FALSE
    je jmpIfFalse
ENDM

;------------------------------------------------------------------------
; PROC Description: Allocate double buffer for VGA mode 320x200x256
; and clears the buffer (black)
;
; Assuming FreeProgramMem was already called
;------------------------------------------------------------------------
PROC AllocateDblBuffer
    store_sp_bp
    push ax bx

    mov bx, VGA_SCREEN_WIDTH * VGA_SCREEN_HEIGHT
    shr bx,4                        ; bx/16
    push bx
    call malloc 
    cmp ax, 0
    jz @@end

    SetDoubleBufferSeg ax
    SetDoubleBuffering TRUE
    call ClearDblBuffer

@@end:
    pop bx ax
    restore_sp_bp
    ret 
ENDP AllocateDblBuffer

;------------------------------------------------------------------------
; PROC Description: Releases the buffer and stops double buffering
;------------------------------------------------------------------------
PROC ReleaseDblBuffer
    store_sp_bp
    push ax es

    IsDblBuffering @@end

    SetDoubleBuffering FALSE
    GetDblBufferSeg ax
    push ax
    call mfree

@@end:
    pop es ax
    restore_sp_bp
    ret 
ENDP ReleaseDblBuffer
;------------------------------------------------------------------------
; PROC Description: clears entire double buffer
;------------------------------------------------------------------------
PROC ClearDblBuffer
    store_sp_bp
    push ax es di cx

    IsDblBuffering @@end

    GetDblBufferSeg es
    xor di,di

    xor   ax,ax
    mov   ax,0
    mov   cx,VGA_SCREEN_WIDTH * VGA_SCREEN_HEIGHT
    rep   stosb                 ; Store AL at address ES:DI
@@end:
    pop cx di es ax
    restore_sp_bp
    ret 
ENDP ClearDblBuffer

;------------------------------------------------------------------------
; PROC Description: Copy double buffer to video memory (VGA)
;------------------------------------------------------------------------
PROC CopyDblBufToVideo    
    store_sp_bp
    push si di cx es ds
 
    IsDblBuffering @@end

    mov cx, [GR_START_ADDR]
    mov es, cx
    GetDblBufferSeg ds
    xor si,si
    xor di,di

    mov cx, VGA_SCREEN_WIDTH * VGA_SCREEN_HEIGHT
    ;DS:SI to address ES:DI
    rep movsb
 
@@end:
    pop ds es cx di si
    restore_sp_bp
    ret 
ENDP CopyDblBufToVideo

