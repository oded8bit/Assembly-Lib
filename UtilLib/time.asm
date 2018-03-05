;===================================================================================================
; Time Functions
;
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Package: UtilLib
;
; Description: 
; Different methods for managing delays
;===================================================================================================
LOCALS @@

DATASEG    
    MICROSEC_HI         equ     0fh      ; used for calculating time (Sleep)
    MICROSEC_LOW        equ     04240h   ; used for calculating time (Sleep)
    MILLISEC            equ     03eBh    ; 1,000
CODESEG

;----------------------------------------------------------
; Halt program for a given number of seconds
; 
; push num-seconds
; call Sleep
;----------------------------------------------------------
PROC Sleep
  store_sp_bp
  sub sp, 4
  pusha

  ; now the stack is
  ; bp-4 => hi
  ; bp-2 => low
	; bp+0 => old base pointer
	; bp+2 => return address
  ; bp+4 => param1 (seconds)
	; saved registers

  mov ax,MICROSEC_LOW
  mul [word bp+4]
  mov [word bp-4],dx
  mov dx,ax

  mov ax, MICROSEC_HI
  mul [word bp+4]
  add ax,[word bp-4]
  mov cx,ax

  mov     al, 0h
	mov     ah, 86h
	int     15H

  popa
  restore_sp_bp
  ret 2
ENDP Sleep
;------------------------------------------------------------------------
; Creates a short delay 
;
; Uses system ticks (about 18/sec) so a delay of '1' is about 1/18 
; of a sec
;
; Delay (word msec)
;------------------------------------------------------------------------
PROC Delay
    store_sp_bp
    pusha
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => # msecs
    ; saved registers
 
    xor ax,ax
    int 1Ah
    mov bx, dx            ; low order word of tick count
    mov cx, [word bp+4]   ; delay time

@@jmp_delay:
    push cx
    int 1Ah
    sub dx, bx
    ;there are about 18 ticks in a second, 10 ticks are about enough
    pop cx
    cmp dx, cx                                                      
    jl @@jmp_delay        

@@end:
    popa
    restore_sp_bp
    ret 2 
ENDP Delay
;------------------------------------------------------------------------
; PROC Description:
; Delay execution for given number of microseconds
;
; Notes:
;   1. 1,000,000 microseconds = 1 second. For 2 seconds, 
;      set CX=001eH and DX=8480H.   (1E 8480 = 2,000,000)
;   2. 1 msec = 1000*1 = CX=0  DX=03eBh
;   3. CX must be at least 1000 (03e8H)
;
; Input:
;     high order - of number of microseconds
;     low order - of number of microseconds
; 
; Output:
;     None
; 
; DelayMS(high, low)
;------------------------------------------------------------------------
PROC DelayMS
    store_sp_bp
    push ax
    push dx
    push cx
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => low word (DX)
    ; bp+6 => high word (CX)
    ; saved registers
 
    mov cx, [word bp+6]
    mov dx, [word bp+4]
    mov ah, 86h 
    int 15h

@@end:
    pop cx
    pop dx
    pop ax
    restore_sp_bp
    ret 4
ENDP DelayMS

;////////////////////////////////////////////////////////////////////////////
; FUNCTION LIKE MACROS
;////////////////////////////////////////////////////////////////////////////

;------------------------------------------------------------------------
; Halt program for a given number of seconds
;
; grm_Sleep (seconds)
;------------------------------------------------------------------------
MACRO utm_Sleep seconds
    push seconds
    call Sleep
ENDM
;------------------------------------------------------------------------
; Creates a short delay 
;
; Uses system ticks (about 18/sec) so a delay of '1' is about 1/18 
; of a sec
;
; grm_Delay (clicks)
;------------------------------------------------------------------------
MACRO utm_Delay clicks
    push clicks
    call Delay
ENDM
;------------------------------------------------------------------------
; Delay execution for given number of microseconds
;
; Notes:
;   1. 1,000,000 microseconds = 1 second. For 2 seconds, 
;      set CX=001eH and DX=8480H.   (1E 8480 = 2,000,000)
;   2. 1 msec = 1000*1 = CX=0  DX=03eBh
;   3. CX must be at least 1000 (03e8H)
;
; Input:
;     high order - of number of microseconds
;     low order - of number of microseconds
; 
; Output:
;     None
; 
; grm_DelayMS (high, low)
;------------------------------------------------------------------------
MACRO utm_DelayMS highOrder, lowOrder
    push highOrder
    push lowOrder
    call Delay
ENDM

