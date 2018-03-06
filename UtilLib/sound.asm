;===================================================================================================
; Sound
;
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Package: UtilLib
;
; Description: 
; Allows playing sounds
;===================================================================================================
LOCALS @@

;----------------------------------------------------------------------
; Plays a beep sound based on the given frequency
; Credit: http://www.edaboard.com/thread182595.html
;
; push FREQUENCY IN HERTZ
; call Beep
;----------------------------------------------------------------------
PROC Beep	
    store_sp_bp
    push ax
    push dx
    push cx

    mov cx,[bp+4]
    cmp cx, 014H
    jb @@STARTSOUND_DONE
    ;CALL STOPSOUND
    in al, 061H
    ;AND AL, 0FEH
    ;OR AL, 002H
    or al, 003H
    dec ax
    out 061H, al	;TURN AND GATE ON; TURN TIMER OFF
    mov dx, 00012H	;HIGH WORD OF 1193180
    mov ax, 034DCH	;LOW WORD OF 1193180
    div cx
    mov dx,ax
    mov al, 0B6H
    pushf
    cli	;!!!
    out 043H, al
    mov al, dl
    out 042H, al
    mov al, DH
    out 042H, al
    popf
    in al, 061H
    or al, 003H
    out 061H, AL
@@STARTSOUND_DONE:
    pop cx
    pop dx
    pop ax
    restore_sp_bp
    ret 2
ENDP Beep    

;----------------------------------------------------------------------
; Stop beep by destroying AL
;----------------------------------------------------------------------
PROC StopBeep
    push ax
    in al, 061H
    and al, 0FCH
    out 061H, al
    pop ax
    ret
ENDP StopBeep

;////////////////////////////////////////////////////////////////////////////
; FUNCTION LIKE MACROS
;////////////////////////////////////////////////////////////////////////////

;----------------------------------------------------------------------
; Plays a beep sound based on the given frequency
;
; grm_Beep (freq)
;----------------------------------------------------------------------
MACRO utm_Beep freq
    push freq
    call Beep
ENDM    
;----------------------------------------------------------------------
; Stop beep by destroying AL
;
; grm_StopBeep()
;----------------------------------------------------------------------
MACRO utm_StopBeep
    call StopBeep
ENDM
