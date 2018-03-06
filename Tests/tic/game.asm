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
    ; Sound frequency to play beep on click
    Click_Sound_Freq      equ     122h
    ; Possible values of Matrix cells
    MARK_O          equ     0
    MARK_X          equ     1
    NO_MARK         equ     2
    ; Coordinates of screen message
    MSG_X           equ     15
    MSG_Y           equ     10
    ; Matrix - the value of each cell
    ; (MARK_O, MARK_X or NO_MARK)
    Matrix         db      9 dup(NO_MARK)    
    ;Matrix          db       0,1,2,  1,1,0,   0,0,1
    ; Marked_Line - if a lcomplete line is found, holds 
    ; the indices of these cells
    Marked_Line     db      NO_MARK,NO_MARK,NO_MARK     
    ; Repaint flag
    Repaint         dw      TRUE
    ; Who's turn is it, starting with X
    The_Turn        dw      MARK_X
    ; Flag for fame over
    Game_Over       dw      FALSE
    Game_No_Moves   dw      FALSE
    ; Game over message
    Str_Game_OVer   db      "Game Over",0
    Str_No_Moves    db      "No More Moves",0
CODESEG

;=========================================================
; Matrix cells indexing:
;          
;      0    |       3      |      6
;    --------------------------------
;      1    |       4      |      7
;    --------------------------------
;      2    |       5      |      8
;    --------------------------------
;
;=========================================================


;---------------------------------------------------------
; Mark repaint flag - if TRUE, will cause the screen
; to be repained
;---------------------------------------------------------
MACRO set_repaint value
    mov [Repaint], value
ENDM
;---------------------------------------------------------
; Reset all variables for a new game
;---------------------------------------------------------
PROC ResetAll
    ; Clear Matrix
    push 9
    push ds
    push offset Matrix
    push NO_MARK
    call ZeroMemByte

    ; Clear marked lines
    push 3
    push ds
    push offset Marked_Line
    push NO_MARK
    call ZeroMemByte

    ; set first turn
    mov [The_Turn], MARK_X
    
    ; force repaint and clear screen
    set_repaint TRUE    
    clear_screen_mouse

    ; set flags
    mov [Game_Over], FALSE
    mov [Game_No_Moves], FALSE
    ShowMouse
    ret
ENDP ResetAll
;---------------------------------------------------------
; Checks if the mouse click is within the board area
; Input:
;   x = cx
;   y = dx
; Output:
;   If TRUE, ax = TRUE, else ax = FALSE
;---------------------------------------------------------
MACRO is_hit_board 
    local _nohit, _endhit
    ; Check if outside board
    cmp cx, [Bg_Start_x]
    jb _nohit
    cmp cx, [Bg_End_x]
    ja _nohit
    cmp dx, [Bg_Start_y]
    jb _nohit
    cmp dx, [Bg_End_y]
    ja _nohit
    ; inside
    mov ax, TRUE
    jmp _endhit
_nohit:    
    ; outside
    mov ax,FALSE
_endhit:    
ENDM
;---------------------------------------------------------
; Finds which of the 9 matrix cells the mouse click hit.
; We already know that there is a hit in the board area.
; 
; push x
; push y
; call FindWhichCell
;
; Output:
; AX contains the cell number (0..8)
; 0 = row 1, col 1
; 1 = row 2, col 1
; 2 = row 3, col 1
; 3 = row 1, col 2
; etc.
; 8 = row 3, col 3
;---------------------------------------------------------
PROC FindWhichCell
    store_sp_bp
    sub sp,4
    push bx cx dx si di

    ; now the stack is
    ; bp-4 => row
    ; bp-2 => col
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => y
	; bp+6 => x
	; saved registers

    mov ax, [WORD bp+6]         ; x
    mov bx, [WORD bp+4]         ; y

    cmp ax, [Vert_Line_1]
    ja @@notfirstcol

    ; First column
    mov [WORD bp-2], 0
    jmp @@findrow

@@notfirstcol:
    cmp ax, [Vert_Line_2]
    ja @@lastcol

    ; second column
    mov [WORD bp-2], 1
    jmp @@findrow

@@lastcol:
    ; last column
    mov [WORD bp-2], 2

@@findrow:
    ; find the row
    cmp bx, [Horz_Line_1]
    ja @@notfirstrow

    ; first row
    mov [WORD bp-4], 0
    jmp @@endfind
@@notfirstrow:

    cmp bx, [Horz_Line_2]
    ja @@lastrow

    ; second row
    mov [WORD bp-4], 1
    jmp @@endfind

@@lastrow:
    mov [WORD bp-4], 2

@@endfind:

    mov ax, [WORD bp-2]         ; col
    mov bx,3
    mul bl                      ; col * 3
    add ax, [WORD bp-4]         ; row

    pop di si dx cx bx
    restore_sp_bp
    ret 4    
ENDP FindWhichCell
;---------------------------------------------------------
; Draw a mark in the given cell
; For index values, see 'FindWhichCell'
; 
; push index
; push type (o or x)
; call DrawSingleMark
;---------------------------------------------------------
PROC DrawSingleMark
    store_sp_bp
    push ax bx cx dx si di

    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => type
	; bp+6 => index
	; saved registers

    xor ax,ax
    xor bx,bx
    xor cx,cx
    xor dx,dx

    mov di, offset Marks_XY
    mov si, [WORD bp+6]
    shl si,1                    ; index * 2 (2 bytes for each point in array)
    add di,si
    mov al, [BYTE di]           ; ax = x
    inc di
    mov bl, [BYTE di]           ; bx = y
    
    mov dx, bx                  ; y
    add dx, Cell_Size           ; dx = bottom y
    sub dx, Cell_Margin
    mov cx, ax                  ; x
    add cx, Cell_Size           ; cx = bottom x
    sub cx, Cell_Margin

    add ax, Cell_Margin         ; margins
    add bx, Cell_Margin

    ; now   (ax,bx) = top left
    ;       (cx,dx) = bottom right

    ; X or O ?
    mov si, [WORD bp+4]
    cmp si, MARK_O
    je @@docircle

    ; Draw X
    gr_set_color GR_COLOR_MAGENTA
    push ax
    push bx
    sub cx,ax
    sub dx,bx
    push cx
    push dx
    call GR_FillRect
    jmp @@endmark

@@docircle:    
    
    ; Draw O
    gr_set_color GR_COLOR_GREEN
    mov di, cx      ; xend
    sub di, ax      ; xstart
    shr di,1        ; radius = (xend-xstart)/2

    add ax, di      ; Xcenter = x + radius
    add bx, di      ; Ycenter = x + radius

    push ax
    push bx
    push di
    call GR_FillCircle

@@endmark:  
    pop di si dx cx bx ax
    restore_sp_bp
    ret 4
ENDP DrawSingleMark
;---------------------------------------------------------
; DrawAllMarks
;
; Loops over the 9 cells and draws the marks
;---------------------------------------------------------
PROC DrawAllMarks
    store_sp_bp
    push ax bx cx dx si di

    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; saved registers

    xor ax,ax
    mov si, -1
@@loop1:    
    inc si
    cmp si, 9
    je @@end                    ; while (si<9)

    mov di,offset Matrix
    add di,si                   ; index to matrix
    mov al,[byte di]            ; matrix value at index si
    cmp al, NO_MARK
    je @@loop1                  ; al=2 => not set

    cmp al, 1
    jne @@omark                 

    ; al=1 => x mark set
    push si
    push MARK_X
    call DrawSingleMark         ; si: 0 = (1,1), 1 = (1,2)...
    jmp @@loop1                 ; continue loop

@@omark:
    ; al=0 => o mark set
    push si
    push MARK_O
    call DrawSingleMark         ; si: 0 = (1,1), 1 = (1,2)...
    jmp @@loop1                 ; continue loop

@@end:
    pop di si dx cx bx ax
    restore_sp_bp
    ret
ENDP DrawAllMarks
;---------------------------------------------------------
; Draws a line over the won cells
;---------------------------------------------------------
PROC DrawWinLine
    store_sp_bp
    sub sp, 8
    push ax bx cx dx si di

    ; now the stack is
	; bp-8 => y2
	; bp-6 => x2
	; bp-4 => y1
	; bp-2 => x1
	; bp+0 => old base pointer
	; bp+2 => return address
	; saved registers

    mov di, offset Marked_Line
    mov bl, [BYTE di]               ; first cell
    mov cl, [BYTE di+2]             ; second cell

    gr_set_color GR_COLOR_WHITE

    cmp bl, 1       
    jne @@is3

    ; if bl=1 then this is the second row 
    ; 1 - 4 - 7
    movv Bg_Start_x, bp-2           ; x1
    movv Bg_End_x, bp-6             ; x2
    mov ax, [Horz_Line_1]           
    add ax, Cell_Size_Half  
    mov [WORD bp-4], ax             ; y1
    mov [WORD bp-8], ax             ; y2

    jmp @@draw
@@is3:
    cmp bl,3
    jne @@is6
    ; if bl=3 then this is the second col
    ; 3 - 4 - 5
    movv Bg_Start_y, bp-4           ; y1
    movv Bg_End_y, bp-8             ; y2
    mov ax, [Vert_Line_1]           
    add ax, Cell_Size_Half  
    mov [WORD bp-2], ax             ; x1
    mov [WORD bp-6], ax             ; x2

    jmp @@draw

@@is6:
    cmp bl,6
    jne @@is0
    ; if bl=6 then this is the third col
    ; 6 - 7 - 8
    movv Bg_Start_y, bp-4           ; y1
    movv Bg_End_y, bp-8             ; y2
    mov ax, [Vert_Line_2]           
    add ax, Cell_Size_Half  
    mov [WORD bp-2], ax             ; x1
    mov [WORD bp-6], ax             ; x2

    jmp @@draw

@@is0:
    cmp bl,0
    jne @@is2

    ; if bl=0 there are 3 options:
    ; 0 - 3 - 6
    ; 0 - 1 - 2
    ; 0 - 4 - 8
    cmp cl, 6
    je @@do036

    cmp cl, 2
    je @@do012

    ; it's 0 - 4 - 8
    movv Bg_Start_x, bp-2           ; x1
    movv Bg_End_x, bp-6             ; x2
    movv Bg_Start_y, bp-4           ; y1
    movv Bg_End_y, bp-8             ; y2

    jmp @@draw
@@is2:
    ; bl = 2

    ; if bl=2 there are 2 options:
    ; 2 - 4 - 6
    ; 2 - 5 - 8
    cmp cl, 6
    je @@do246

    ; it's 2 - 5 - 8
    movv Bg_Start_x, bp-2           ; x1
    movv Bg_End_x, bp-6             ; x2
    mov ax, [Horz_Line_2]           
    add ax, Cell_Size_Half  
    mov [WORD bp-4], ax             ; y1
    mov [WORD bp-8], ax             ; y2

    jmp @@draw
@@do246:
    ; it's 2 - 4 - 6
    movv Bg_Start_x, bp-2           ; x1
    movv Bg_End_x, bp-6             ; x2
    movv Bg_End_y, bp-4             ; y1
    movv Bg_Start_y, bp-8           ; y2

    jmp @@draw
@@do036:
    ; It's 0 - 3 - 6
    movv Bg_Start_x, bp-2           ; x1
    movv Bg_End_x, bp-6             ; x2
    mov ax, [Bg_Start_y]           
    add ax, Cell_Size_Half  
    mov [WORD bp-4], ax             ; y1
    mov [WORD bp-8], ax             ; y2

    jmp @@draw
@@do012:
    ; It's 0 - 1 - 2
    movv Bg_Start_y, bp-4           ; y1
    movv Bg_End_y, bp-8             ; y2
    mov ax, [Bg_Start_x]           
    add ax, Cell_Size_Half  
    mov [WORD bp-2], ax             ; x1
    mov [WORD bp-6], ax             ; x2

    jmp @@draw

@@draw:
    ; Draw the line
    push [WORD bp-2]
    push [WORD bp-4]
    push [WORD bp-6]
    push [WORD bp-8]
    call GR_DrawLine

@@done:
    pop di si dx cx bx ax
    restore_sp_bp
    ret
ENDP DrawWinLine
;---------------------------------------------------------
; Check if a line in the matrix contains 3 same marks
; 
; push delta
; push expected mark
; push current index
; call CheckLine
;
; Output:
;   if TRUE, ax = 1, else ax = 0
;---------------------------------------------------------
PROC CheckLine
    store_sp_bp
    push bx cx dx si di

    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => index
	; bp+6 => mark
	; bp+8 => delta
	; saved registers

    xor ax,ax               ; count = 0
    xor bx,bx
    mov si, [WORD bp+4]
    mov cx, [WORD bp+6]

    add di,[WORD bp+8]
    mov bl, [BYTE di]
    cmp bl, cl
    jne @@_notfound         ; not found

    inc al                  ; count = 1
@@_next1:
    add di,[WORD bp+8]
    mov bl, [BYTE di]
    cmp bl, cl
    jne @@_notfound         ; not found

    inc al                  ; count = 2
@@_found:
    cmp al,2
    jne @@_notfound

    ; found
    mov bx, si
    mov di, offset Marked_Line
    mov [BYTE di],bl
    inc di
    add bx,[WORD bp+8]
    mov [BYTE di],bl
    inc di
    add bx,[WORD bp+8]
    mov [BYTE di],bl
    mov ax, TRUE
    jmp @@_endcheck

@@_notfound:
    mov ax, FALSE

@@_endcheck:
    pop di si dx cx bx 
    restore_sp_bp
    ret 2
ENDP CheckLine
;---------------------------------------------------------
; Macro - calls CheckLine for horizontal lines
; Input: 
;   cl = MARK_O or MARK_X
;   si = row index
; Output:
;   ax = 0 if not found, else > 0
;   Sets values in Marked_Line
; Registers' state on call:
;   di = address of first cell in matrix
;---------------------------------------------------------
MACRO check_horiz_line 
    push 3
    push cx
    push si
    call CheckLine
ENDM
;---------------------------------------------------------
; Macro - calls CheckLine for vertical lines
; Input: 
;   cx = MARK_O or MARK_X
;   si = row index
; Output:
;   ax = 0 if not found, else 1
;   Sets values in Marked_Line
; Registers' state on call:
;   di = address of first cell in matrix
;---------------------------------------------------------
MACRO check_vert_line
    push 1
    push cx
    push si
    call CheckLine
ENDM
;---------------------------------------------------------
; Macro - calls CheckLine for diagonal lines
; Input: 
;   cx = MARK_O or MARK_X
;   si = row index
; Output:
;   ax = 0 if not found, else 1
;   Sets values in Marked_Line
;---------------------------------------------------------
MACRO check_diagonal_line 
local _firstrow,_end
    cmp si,0
    je _firstrow
    push 2
    push cx
    push si
    call CheckLine
    jmp _end
_firstrow:
    push 4
    push cx
    push si
    call CheckLine
_end:    
ENDM
;---------------------------------------------------------
; Check if there is a complete line in the matrix
;
; Output:
;   AX = TRUE or FALSE
;---------------------------------------------------------
PROC CheckWinOrEnd
    store_sp_bp
    push bx cx dx si di

    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; saved registers

    mov si,-1                   ; row number
    xor cx,cx
    xor ax,ax

@@check_h:
    inc si                      ; si++
    cmp si, 2
    ja @@check_v                ; while (si < 3 rows)

    mov di, offset Matrix
    add di,si
    mov cl, [BYTE di]
    cmp cl, NO_MARK
    je @@check_h                ; not marked

    ; marked
    check_horiz_line

    cmp ax, 0
    jne @@endcheck              ; found match, go out

    cmp si, 0
    jne @@cont                  ; not first row

    check_diagonal_line         ; check diagonal
    cmp ax, 0
    jne @@endcheck              ; found match, go out
    jmp @@check_h               ; next row

@@cont:
    ; not first row
    check_horiz_line 

    cmp ax, 0
    jne @@endcheck              ; found match, go out

    cmp si,2
    jne @@check_h
    check_diagonal_line         ; check diagonal
    cmp ax, 0
    jne @@endcheck              ; found match, go out

@@check_v:
    xor ax,ax
    mov si, -3

@@check_v_loop:
    add si,3                    ; si++
    cmp si, 6
    ja @@endcheck               ; while (si < 3 cols)

    mov di, offset Matrix
    add di,si
    mov cl, [BYTE di]
    cmp cl, NO_MARK
    je @@check_v_loop           ; not marked,   ; marked
    check_vert_line 
    
    cmp ax, 0
    jne @@endcheck              ; found matc,go out
    jmp @@check_v_loop          ; next col

@@endcheck:
    ; if not found, check if board full
    cmp ax,0
    je @@checkforcomplete

    ; found 
    mov [Game_Over], TRUE
    jmp @@done

@@checkforcomplete:
    ; Did not find lines, check if 
    ; all board is full
    mov di, offset Matrix
    dec di
    mov si, -1
    xor cx,cx       ; counter

@@allloop:
    inc si
    cmp si, 8
    ja @@anymoves

    inc di
    mov bl, [BYTE di]
    cmp bl,NO_MARK
    je @@done
    inc cx          ; counter++
    jmp @@allloop

@@anymoves:
    cmp cx,9
    jne @@done
    mov [Game_No_Moves], TRUE
    mov [Game_Over], TRUE
@@done:
    pop di si dx cx bx 
    restore_sp_bp
    ret 0
ENDP CheckWinOrEnd
;---------------------------------------------------------
; Handles mouse clicks. 
; 
; push x
; push y
; call HandleMouseHit
;---------------------------------------------------------
PROC HandleMouseHit
    store_sp_bp
    push ax bx cx dx si di

    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => y
	; bp+6 => x
	; saved registers

    push [WORD bp+6]                 ; x
    push [WORD bp+4]                 ; y
    call FindWhichCell          ; result in ax

    ; check if this cell is already set
    mov di, offset Matrix
    add di,ax
    mov bx, [The_Turn]

    cmp [BYTE di], NO_MARK
    jne @@nothing
    mov [BYTE di], bl

    toggle_bool_var The_Turn

@@nothing:    
    pop di si dx cx bx ax
    restore_sp_bp
    ret 4
ENDP HandleMouseHit
;---------------------------------------------------------
; DrawComplete
;
; Draws the game over / complete status
;---------------------------------------------------------
PROC DrawComplete
    store_sp_bp
    push ax bx cx dx si di

    ; not done
    cmp [Game_Over], FALSE
    je @@nothing

    cmp [Game_No_Moves], FALSE
    jne @@nomoves

    ; Draw a line over the won cells
    call DrawWinLine

    ; Draw game over message
    gr_set_color GR_COLOR_RED
    push offset Str_Game_Over
    push MSG_X
    push MSG_Y
    call PrintStrVGA
    jmp @@cont

@@nomoves:
    ; Draw game over message
    gr_set_color GR_COLOR_RED
    push offset Str_No_Moves
    push MSG_X
    push MSG_Y
    call PrintStrVGA


@@cont:
    xor cx,cx

    mov di, offset Matrix
    cmp [BYTE di], NO_MARK
    je @@nothing

    mov cl, [BYTE di]           ; the mark

@@nothing:
    pop di si dx cx bx ax
    restore_sp_bp
    ret
ENDP DrawComplete
;---------------------------------------------------------
; PlyTic - the main game function
;
;---------------------------------------------------------
PROC PlayTic
    store_sp_bp
    push ax bx cx dx si di

    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; saved registers

    ShowMouse
    call ResetAll
@@mainloop:
    call GetKeyboardStatus      ; Get key
    jz @@checkmouse             ; No key, check mouse
    ; check for special keys
    cmp ax, SC_Q                ; Q to quit    
    je  @@endloop
    cmp ax, SC_S                ; S to restart
    je @@startgame
    call ConsumeKey
    jmp @@draw                  ; No special key, continue

@@checkmouse:
    cmp [Game_Over],TRUE
    je @@mainloop

    GetMouseStatus              ; check mouse click
    and bx, 0001h
    cmp bx,1
    jne @@draw                  ; no click
    ; mouse was clicked
    push Click_Sound_Freq             
    call Beep                   ; beep
    TranslateMouseCoords        ; Coords
    ; cx = x , dx = y
    is_hit_board cx, dx
    cmp ax, TRUE
    jne @@draw
    
    push cx                     ; mouse x
    push dx                     ; mouse y
    call HandleMouseHit         

    call CheckWinOrEnd          ; check if game won or ended
    set_repaint TRUE
    cmp ax, 1
    jne @@draw
    mov [Game_Over], TRUE

    jmp @@draw                  ; Now draw
@@startgame:
    ; Special key S typed
    call ConsumeKey
    call ResetAll
    set_repaint TRUE
@@draw:    
    ; Draw background and marks
    ; only if Repaint is set
    cmp [Repaint], FALSE
    je @@next
    
    ; Draw
    HideMouse
    call DrawBackground
    call DrawAllMarks
    call DrawComplete
    ShowMouse
    
    set_repaint FALSE
@@next:    
    call StopBeep
    jmp @@mainloop              ; continue loop
@@endloop:
    HideMouse

    pop di si dx cx bx ax
    restore_sp_bp
    ret
ENDP PlayTic
