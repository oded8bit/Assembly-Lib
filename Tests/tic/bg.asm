;===================================================================================================
; TicTac game
;
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Package: AsmLib
;
; Description: 
; A simple tictac game to demonstrate the library
;===================================================================================================
LOCALS @@

DATASEG
    ; Drawing background
    Bg_Start_x  dw      80
    Bg_Start_y  dw      20
    Bg_End_x    dw      240
    Bg_End_y    dw      180

    Vert_Line_1 dw      133
    Vert_Line_2 dw      186
    Horz_Line_1 dw      73
    Horz_Line_2 dw      126

    Cell_Size  equ      53
    Cell_Size_Half equ  26
    Cell_Margin equ     15

    Line_Color  db      GR_COLOR_YELLOW

    ; Labels
    Lbl_Quit_Txt   db  "Q=Quite",0
    Lbl_Quit_x     dw  1
    Lbl_Quit_y     dw  3
    Lbl_Quit_Color db  GR_COLOR_LIGHTBLUE

    Lbl_Start_Txt   db  "S=Start",0
    Lbl_Start_x     dw  1
    Lbl_Start_y     dw  1
    Lbl_Start_Color db  GR_COLOR_LIGHTBLUE

    ; (1,1), (1,2), (1,3) first column
    ; (2,1), (2,2), (2,3)
    ; (3,1), (3,2), (3,3)
                       ;50,14
    Marks_XY        db  80,20,80,73,80,126,133,20,133,73,133,126,186,20,186,73,186,126
CODESEG

MACRO tic_draw_board 
    ; set color
    xor ax,ax
    mov al, [Line_Color]
    gr_set_color al

    ; Draw vert lines
    push [Vert_Line_1]
    push [Bg_Start_y]
    push [Vert_Line_1]
    push [Bg_End_y]
    call GR_DrawLine

    push [Vert_Line_2]
    push [Bg_Start_y]
    push [Vert_Line_2]
    push [Bg_End_y]
    call GR_DrawLine

    ; Draw horizontal lines
    push [Bg_Start_x]
    push [Horz_Line_1]
    push [Bg_End_x]
    push [Horz_Line_1]
    call GR_DrawLine

    push [Bg_Start_x]
    push [Horz_Line_2]
    push [Bg_End_x]
    push [Horz_Line_2]
    call GR_DrawLine
ENDM

MACRO tic_draw_labels
    ; set color
    xor ax,ax
    mov al, [Lbl_Start_Color]
    gr_set_color al

    push ax
    push offset Lbl_Start_Txt
    push [Lbl_Start_x]
    push [Lbl_Start_y]
    call PrintStrVGA

    ; set color
    xor ax,ax
    mov al, [Lbl_Quit_Color]
    gr_set_color al

    push ax
    push offset Lbl_Quit_Txt
    push [Lbl_Quit_x]
    push [Lbl_Quit_y]
    call PrintStrVGA
ENDM
;--------------------------------------------------------------------
; Draw background
;--------------------------------------------------------------------
PROC DrawBackground
    store_sp_bp
    sub sp, 4
    push ax bx cx dx si di

	; now the stack is
	; bp-4 => 
	; bp-2 => 
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => 
	; bp+6 => 
	; saved registers

    tic_draw_board
    tic_draw_labels


@@end:
    pop di si dx cx bx ax
    restore_sp_bp
    ret
ENDP DrawBackground

