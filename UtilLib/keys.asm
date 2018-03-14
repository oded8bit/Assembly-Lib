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
    include   "UtilLib\keymap.inc"

    ; used by PrintFifoStatus
    strTail           db  "TAIL=$",0
    strHead           db  "HEAD=$",0

CODESEG
  _OldKeyboardISR 	  dw            0,0			                    ; old keyboard ISR vector address and segment
  ; FIFO buffer implementation
  KEY_BUFFER_SIZE     equ           15                              ; Fifo buffer size
  _ISRKeyBuffer       db            KEY_BUFFER_SIZE dup(0)			; ISR 9 - keyboard buffer
  _ISRKeyHead         dw            0                               ; Head pointer
  _ISRKeyTail         dw            0                               ; Tail pointer

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
    call ConsumeKey
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
; push interrupt segment
; call InstallKeyboardInterrupt
;   
; Note:
;   Old interrupt is stored and should be put restored using
;   RestoreKeyboardInterrupt
;------------------------------------------------------------------
PROC InstallKeyboardInterrupt
    store_sp_bp
    pusha
    push ds es
    cli
    ; save old ISR
    mov al,9h		
    mov ah,35h
    int 21h                 ; get current
    mov [cs:_OldKeyboardISR],bx    ; save it
    mov [cs:_OldKeyboardISR+2],es

    ; Install new ISR
    mov al,9h
    mov ah,25h
    mov dx,[ss:bp+6]           ; ISR address
    push [WORD ss:bp+4]
    pop ds                  ; ISR segment
    int 21h                 ; install new

    sti
    pop es ds
    popa
    restore_sp_bp
    ret 4
ENDP InstallKeyboardInterrupt
;------------------------------------------------------------------
; Restore a previously saved keyboard interrupt
;------------------------------------------------------------------
PROC RestoreKeyboardInterrupt
    pusha
    cli
    push ds			            ;uninstall keyboard int
    mov dx,[cs:_OldKeyboardISR]
    push [cs:_OldKeyboardISR+2]
    pop ds
    mov al,9h
    mov ah,25h
    int 21h
    pop ds
    sti
    popa
    ret
ENDP RestoreKeyboardInterrupt

;--------------============= SAMPLE KEYBOARD ISR ==============-----------------

;------------------------------------------------------------------
; Sample keybaord interrupt - Init FIFO buffer
;------------------------------------------------------------------
PROC InitSampleISR
    push es di
    mov [cs:_ISRKeyHead], 0
    mov [cs:_ISRKeyTail], 0
    ; Make buffer zero
    mov cx, KEY_BUFFER_SIZE
    mov di, offset _ISRKeyBuffer
    push cs
    pop es
    mov al, 0
    rep stosb

    pop di es
    ret
ENDP
;------------------------------------------------------------------
; Sample keybaord interrupt - read key from buffer
; Returns:
;
;   AL = scan code, 0 if buffer empty
;------------------------------------------------------------------
PROC getcISR
    store_sp_bp
    push di si

    ;mov al, [cs:_key]
    ;mov [cs:_key],0
    ;jmp @@end

    mov si, [cs:_ISRKeyHead]
    mov di, [cs:_ISRKeyTail]
    xor ax, ax
    ; if (head == tail) then no_data
    cmp si, di
    je @@noData

    mov si, offset _ISRKeyBuffer
    add si,[cs:_ISRKeyTail] 
    mov al, [BYTE cs:si]                  ; al <= key
    inc [cs:_ISRKeyTail]               ; tail++
    cmp [cs:_ISRKeyTail], KEY_BUFFER_SIZE
    jne @@end

    mov [cs:_ISRKeyTail], 0            ; tail = 0

@@noData:

@@end:
    pop si di
    restore_sp_bp
    ret
ENDP getcISR
;------------------------------------------------------------------
; Sample keybaord interrupt - check if there is a key in buffer
; without taking it out.
;
; Private - for use only by the library
;
; Returns:
;   AL = 0 if no scan code is available, scancode otherwise
;------------------------------------------------------------------
MACRO __fifo_peek
local _noData
    push di si
    mov si, [cs:_ISRKeyHead]
    mov di, [cs:_ISRKeyTail]
    xor ax, ax
    ; if (head == tail) then no_data
    cmp si, di
    je _noData

    mov si, offset _ISRKeyBuffer
    add si, [cs:_ISRKeyTail]
    mov al, [BYTE cs:si]           ; al <= key
_noData:
    pop si di
ENDM
;------------------------------------------------------------------
; Sample keybaord interrupt - check if there is a key in buffer
; without taking it out.
;
; Returns:
;   AL = 0 if no scan code is available, scancode otherwise
;------------------------------------------------------------------
PROC GetKeyboardStatusISR
    __fifo_peek
    ret
ENDP GetKeyboardStatusISR
;------------------------------------------------------------------
; Sample keybaord interrupt - write key to buffer
;
; Private - for use only by the library
;------------------------------------------------------------------
MACRO __fifo_write key
local _bufFull, _end, _insert
    push si di ax
    mov si, [cs:_ISRKeyHead]
    mov di, [cs:_ISRKeyTail]
    xor ah, ah
    inc si                  ; head + 1
   
    ;if( (head + 1 == tail) || ((head + 1 == size) && (tail == 0) ){
        ; buffer is full        
        cmp si, di
        je _bufFull

        cmp si, KEY_BUFFER_SIZE
        jne _insert
        cmp di,0
        jne _insert

        jmp _bufFull

    ;} else {
_insert:
        ; insert key to buffer
        mov si, offset _ISRKeyBuffer
        add si, [cs:_ISRKeyHead]
        mov [cs:si], key          
        inc [cs:_ISRKeyHead]               ; head++
        ; if( head != size ) { 
            ; we are good
            cmp [cs:_ISRKeyHead], KEY_BUFFER_SIZE 
            jne _end
        ; } else {
            mov [cs:_ISRKeyHead], 0            ; head = 0
        ;}

        jmp _end
    ;}
_bufFull:
    ; Make sound if buffer is full
    utm_Beep 0122h
    utm_DelayMS 0, 0c350h
    utm_StopBeep
_end:
    pop ax di si
ENDM
;------------------------------------------------------------------
; A simple keybaord interrupt that manages a FIFO buffer.
; The buffer holds scancodes (and not ASCII characters) and 
; does not handle shoft / ctrl and alt combinations
;------------------------------------------------------------------
PROC KeyboardSampleISR FAR
    cli                     ; disable interrupts
    push ax 
    xor   ax,ax

    in al, 64h              ; Read keyboard status port
    cmp al, 10b
    je @@end                ; not input

    in      al, 060h        ; read scan code 

    cmp al, 80h
    ja @@keyReleased

    ; Handle key presse events
    __fifo_write al         ; save it in buffer

    jmp @@end
@@keyReleased:
    ; Handle key release events

@@end:
    ; Send End-Of-Interrupt signal to the 8259 Interrupt Controller
    push ax
    mov al,20h
    out 20h,al
    pop ax

    pop ax 
    sti                     ; enable interrupts
    iret
ENDP KeyboardSampleISR         
;------------------------------------------------------------------
; For debug only: prints fifo buffer status message
;------------------------------------------------------------------
PROC PrintFifoStatus
    store_sp_bp
    pusha

    mov dx, offset strHead
    call PrintStr
    mov ax, [cs:_ISRKeyHead]
    push ax
    call PrintHexByte
    call PrintNewLine

    mov dx, offset strTail
    call PrintStr
    mov ax,[cs:_ISRKeyTail]
    push ax
    call PrintHexByte
    call PrintNewLine

    mov cx, KEY_BUFFER_SIZE
    mov si, offset _ISRKeyBuffer
@@printBuf:
    mov ax, [WORD cs:si]
    push ax
    call PrintHexByte
    call PrintSpace
    inc si
    loop @@printBuf    
    call PrintNewLine
    call PrintNewLine

    popa
    restore_sp_bp
    ret
ENDP PrintFifoStatus

;--------------============= END OF SAMPLE KEYBOARD ISR ==============-----------------


;--------------============= SIMPLE KEYBOARD ISR ==============------------------------

;------------------------------------------------------------------
; A simple keybaord interrupt uses the original built-in IRQ but
; adds preprocessing to the event
;------------------------------------------------------------------
PROC KeyboardISREvents FAR

    ; handle the event

    ; call original ISR
    push [word ptr cs:_OldKeyboardISR + 2] ; segment
    push [word ptr cs:_OldKeyboardISR]     ; offset
    retf
ENDP KeyboardISREvents       
;--------------============= END OF SIMPLE KEYBOARD ISR ==============-------------------