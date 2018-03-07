;===================================================================================================
; Keyboard Management
;
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Package: UtilLib
;
; Description: 
; A set of procedures for managing keyboard input
;===================================================================================================
LOCALS @@

DATASEG
  _Key	            db 0,0,0			;keyscan (word),_Key code(call keys)

  include   "UtilLib\keymap.inc"

CODESEG
  _OldKeyboardISR 	    dw 0,0			;old keyboard ISR vector adress

;------------------------------------------------------------------
; Set Keyboard Typematic Rate to defalt (repeat delay and rate)
;------------------------------------------------------------------
PROC SetKeyboardRateDefault
    push ax
    mov ax,3				
    int 16
    pop ax
    ret
ENDP SetKeyboardRateDefault
;------------------------------------------------------------------
; Checks for a keypress; Sets ZF if no keypress is available
; Otherwise returns it's scan code into AH and it's ASCII into al
; Removes the charecter from the Type Ahead Buffer 
; return: AX  = _Key
;------------------------------------------------------------------
PROC WaitForKeypress
    store_sp_bp

@@check_keypress:
    mov ah, 1     ; Checks if there is a character in the type ahead buffer
    int 16h       ; MS-DOS BIOS Keyboard Services Interrupt
    jz @@check_keypress_empty
    mov ah, 0
    int 16h
    jmp @@exit
@@check_keypress_empty:
    cmp ax, ax    ; Explicitly sets the ZF
    jz   @@check_keypress

@@exit:
    restore_sp_bp
    ret
ENDP WaitForKeypress

;------------------------------------------------------------------
; Read keyboard _Key if pressed - non blocking
;
; returns:
; ZF = 0 if a _Key pressed (even Ctrl-Break)
;	AX = 0 if no scan code is available
;	AH = scan code
;	AL = ASCII character or zero if special function _Key
;------------------------------------------------------------------
PROC GetKeyboardStatus
    mov ah, 01h
    int 16h  
    ret
ENDP GetKeyboardStatus
;------------------------------------------------------------------
; Consume the keyboard char
;------------------------------------------------------------------
PROC ConsumeKey
    mov ah,0
    int 16h
    ret
ENDP ConsumeKey
;------------------------------------------------------------------
; Get keyboard key if available
;------------------------------------------------------------------
PROC GetKeyboardKey
    mov ax,0
    call GetKeyboardStatus
    jnz @@exit
    ;call ConsumeKey
@@exit:    
    ret
ENDP GetKeyboardKey
;------------------------------------------------------------------
; Get keyboard flags
; Output: AL
;|7|6|5|4|3|2|1|0|  AL or BIOS Data Area 40:17
;		 | | | | | | | `---- right shift key depressed
;		 | | | | | | `----- left shift key depressed
;		 | | | | | `------ CTRL key depressed
;		 | | | | `------- ALT key depressed
;		 | | | `-------- scroll-lock is active
;		 | | `--------- num-lock is active
;		 | `---------- caps-lock is active
;		 `----------- insert is active
;------------------------------------------------------------------
PROC GetKeyboardFlags
    xor ax,ax
    mov ah,2
    int 16h
    ret
ENDP GetKeyboardFlags
;------------------------------------------------------------------
; Install a keyboard interrupt
;
; push address of new interrupt in ds (lea dx,[interr])
; call InstallKeyboardInterrupt
;   
; Note:
;   Old interrupt is stored and should be put restored using
;   RestoreKeyboardInterrupt
;------------------------------------------------------------------
PROC InstallKeyboardInterrupt
    pusha
    cli
    mov al,9h		
    mov ah,35h
    int 21h                 ; get current
    mov [_OldKeyboardISR],bx    ; save it
    mov [_OldKeyboardISR+2],es
    mov al,9h
    mov ah,25h
    mov dx,[bp+4]           ; arg
    int 21h                 ; install new
    sti
    popa
    ret 2
ENDP InstallKeyboardInterrupt
;------------------------------------------------------------------
; Restore a previously saved keyboard interrupt
;------------------------------------------------------------------
PROC RestoreKeyboardInterrupt
    pusha
    cli
    push ds			            ;uninstall keyboard int
    mov dx,[_OldKeyboardISR]
    mov ax,[_OldKeyboardISR+2]
    mov ds,ax
    mov al,9h
    mov ah,25h
    int 21h
    pop ds
    sti
    popa
    ret
ENDP RestoreKeyboardInterrupt
;------------------------------------------------------------------
; Sample keybaord interrupt
;------------------------------------------------------------------
PROC KeyboardSampleISR 
    push ax bx
    xor   ax,ax
    in    al, 060h       ; read scan code 
    mov [_Key],al

    ; send EOI to XT keyboard
    in      al, 061h
    mov     ah, al
    or      al, 080h
    out     061h, al
    mov     al, ah
    out     061h, al

    ; send EOI to master PIC
    mov   al, 020h       ; reset PIC 
    out   020h, al

    pop bx ax 
    iret
ENDP KeyboardSampleISR         

