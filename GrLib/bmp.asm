;===================================================================================================
; Bitmaps
;
; Written By: Oded Cnaan (oded.8bit@gmail.com)
; Site: http://odedc.net 
; Licence: GPLv3 (see LICENSE file)
; Package: GrLib
;
; Description: 
; Managing bitmap files
;===================================================================================================
LOCALS @@

    ;struct Bitmap {                          Bytes     Offset
    ;    byte[54]    Header,                ; 54        0h
    ;    byte[1024]  Pal,                   ; 1024      36h
    ;    int         PalSize,               ; 2         436h 
    ;    int         Height,                ; 2         438h
    ;    int         Width,                 ; 2         43Ah
    ;    int         _fHandle,               ; 2         43Ch
    ;    int         DataStartAddress,      ; 2         43Eh
    ;    int         DataSegment            ; 2         440h
    ;    int         DataSize               ; 2         442h
    ;}
    ;BMP_STRUCT_SIZE         equ         444h
    BMP_HEADER_OFFSET       equ         0
    BMP_HEADER_LEN          equ         36h
    BMP_PALETTE_OFFSET      equ         36h
    BMP_PALETTE_LEN         equ         400h
    BMP_PALETTE_SIZE_OFFSET equ         436h
    BMP_HEIGHT_OFFSET       equ         438h
    BMP_WIDTH_OFFSET        equ         43Ah
    BMP_FHANDLE_OFFSET      equ         43Ch
    BMP_DATA_SEG_OFFSET     equ         43Eh
    BMP_DATA_SIZE_OFFSET    equ         440h   

DATASEG   
    BMPStart        db  'BM'
    msgInvBMP       db  "Not a valid BMP file.",7,0Dh,0Ah,24h
    msgFileErr      db  "Error opening file.",7,0Dh,0Ah,24h

CODESEG

;------------------------------------------------------------------------
; push path address
; push path segment
; push struct address
; push struct segment
; call LoadBMPImage
;------------------------------------------------------------------------
PROC LoadBMPImage
    store_sp_bp
    pusha 
    push ds

    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => struct segment
	; bp+6 => struct address
	; bp+8 => path segment
	; bp+10 => path address
	; saved registers

    ;{
    pathAddress         equ         [word bp+10]
    pathSegment         equ         [word bp+8]
    structAddress       equ         [word bp+6]
    structSegment       equ         [word bp+4]
    ;}

    push pathAddress       ; path address
    push pathSegment        ; path seg
    call fopen              ; Open file pointed to by DS:DX

    push ds
    push structSegment
    pop ds

    ; init ptr to NULL
    mov si,structAddress
    add si, BMP_DATA_SEG_OFFSET
    mov [word ds:si], 0
    mov si,structAddress
    add si, BMP_DATA_SIZE_OFFSET
    mov [word ds:si],0

    pop ds


    cmp [cs:_fErr],0    
    jne @@FileErr           ; Error? Display error message and quit

    mov bx,[cs:_fHandle]     ; Put the file handle in BX
    push structAddress        ; struct addr
    push structSegment        ; struct seg    
    call ReadHeaderToStruct ; Reads the 54-byte header containing file info

    jc @@InvalidBMP         ; Not a valid BMP file? Show error and quit

    push structAddress        ; struct addr
    push structSegment        ; struct seg    
    call ReadPalStruct      ; Read the BMP's palette and put it in a buffer

    push structAddress        ; struct addr
    push structSegment        ; struct seg    
    call SendPalStruct      ; Send the palette to the video registers

    push structAddress        ; struct addr
    push structSegment        ; struct seg    
    call LoadBMPData

    call fclose             ; Close the file

    jmp @@ProcDone

@@FileErr:                  ; error 
    mov ah,9
    mov dx,offset msgFileErr
    int 21h
    jmp @@ProcDone

@@InvalidBMP:               ; invalid bmp
    mov ah,9
    mov dx,offset msgInvBMP
    int 21h

@@ProcDone:
    pop ds
    popa
    restore_sp_bp
    ret 8
ENDP LoadBMPImage
;------------------------------------------------------------------------
; Displays the BMP on the screen
;
; push struct address
; push struct seg
; push Xtop
; push Ytop
; call DisplayBMP
;------------------------------------------------------------------------
PROC DisplayBMP
    store_sp_bp
    sub sp,10
    pusha
    push ds
    push es
 
    ; now the stack is
    ; bp-10 => image line height
    ; bp-8 => image line width
    ; bp-6 => y
    ; bp-4 => height
    ; bp-2 => width
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => ytop
    ; bp+6 => xtop
    ; bp+8 => struct seg
    ; bp+10 => struct address
    ; saved registers

    ;{
    varWidth            equ         [word bp-2]
    varHeight           equ         [word bp-4]
    varY                equ         [word bp-6]
    varY_               equ         bp-6
    varLineWidth        equ         [word bp-8]
    varLineHeight       equ         [word bp-10]

    structAddress       equ         [word bp+10]
    structSegment       equ         [word bp+8]
    xtop                equ         [word bp+6]
    xtop_               equ         bp+6
    ytop                equ         [word bp+4]
    ;}

    push structSegment          ; struct seg
    pop ds
    
    ; check if data was allocated. if not abort
    mov si, structAddress       ; struct add
    add si, BMP_DATA_SEG_OFFSET
    cmp [word ds:si], 0
    je @@err_coord

    push structAddress          ; struct addr
    push structSegment          ; struct seg    
    call SendPalStruct

    push structSegment 
    pop ds                      ; ds = struct seg

    mov di, structAddress       ; ds:di = struct ptr

    mov si, di
    add si, BMP_HEIGHT_OFFSET
    mov cx, [word ds:si]        
    mov varHeight, cx           ; Height
    mov varLineHeight, cx       ; Height
    mov dx, [word ds:si+2]      
    mov varWidth, dx            ; Width
    mov varLineWidth, dx        ; Img Width

    ; check Xtop 
    mov ax, xtop
    cmp ax, VGA_SCREEN_WIDTH
    ja @@err_coord

    cmp ax,0
    jl @@err_coord

@@check_y:
    ; if (Ytop > SCREEN HEIGHT) exit
    mov ax, ytop
    cmp ax, VGA_SCREEN_HEIGHT
    ja @@err_coord

    ; if (yTop < 0) exit
    cmp ax,0
    jl @@err_coord   

@@check_h:
    mov ax,ytop                 ; ytop
    add ax,cx                   ; ytop + h
    cmp ax,VGA_SCREEN_HEIGHT
    jbe @@check_w               ; if (ytop + height < screen height)
                                ; else
    mov ax, VGA_SCREEN_HEIGHT
    sub ax,ytop
    mov varHeight, ax           ; height = VGA_SCREEN_HEIGHT - Ytop
    mov cx,ax

    ; since the image is upside down, we need to move the di addr
    mov ax, varLineHeight
    sub ax, cx                  ; VGA_SCREEN_HEIGHT - height
    mul varLineWidth            ; * img width
    add di, ax

@@check_w:
    mov ax,xtop                 ; xtop
    add ax,dx
    cmp ax,VGA_SCREEN_WIDTH
    jbe @@ok                    ; if (xtop + width < screen width)
                                ; else
    mov ax, VGA_SCREEN_WIDTH
    sub ax,xtop
    mov varWidth, ax            ; width = VGA_SCREEN_WIDTH - Xtop

@@ok:
    mov si, di
    add si, BMP_DATA_SEG_OFFSET

    push [_dss]
    pop ds
    push [word GR_START_ADDR]
    pop es

    push structSegment
    pop ds
    push [word ds:si]
    pop ds                      ; ds:si = data ptr

    mov ax, ytop                ; yTop
    add ax, varHeight           ; height
    mov varY,ax                 ; y=Ytop+Height
    
    xor di,di
    xor si,si

    ; cx = height, ds:si = data, es:di = screen
 @@DrawLoop:
    push cx
    push si
    
    cld                         ; Clear direction flag, for movsb.
    mov cx, varWidth            ; width
    translate_coord_to_vga_addr xtop_, varY_

    ; source DS:SI
    ; dest   ES:DI
    ; len    CX
    rep movsb                   ; Copy line in buffer to screen.
    pop si
    add si, varLineWidth        ; si += img width

    dec varY                    ; y--

    pop cx
    loop @@DrawLoop

    jmp @@end

@@err_coord:

@@end:
    pop es
    pop ds
    popa
    restore_sp_bp
    ret 8
ENDP DisplayBMP
;------------------------------------------------------------------------
; push struct address
; push struct seg
; call TileBmp
;------------------------------------------------------------------------
PROC TileBmp
    store_sp_bp
    sub sp,8
    pusha
    push ds

    ; now the stack is
    ; bp-8 => y
    ; bp-6 => x
    ; bp-4 => height
    ; bp-2 => width
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => struct seg
    ; bp+6 => struct add
    ; saved registers
 
    push [word bp+4] 
    pop ds                      ; ds = struct seg
    mov di, [word bp+6]         ; ds:di = struct ptr

    mov si, di
    add si, BMP_HEIGHT_OFFSET
    mov cx, [word ds:si]        
    mov [word bp-4], cx         ; Height
    mov dx, [word ds:si+2]      
    mov [word bp-2], dx         ; Width

    mov [word bp-8],0           ; y = 0
    mov [word bp-6],0           ; x = 0

@@draw:
    push [word bp+6]
    push [word bp+4]
    push [word bp-6]
    push [word bp-8]
    call DisplayBMP

    add [word bp-6],dx          ; x += width
    cmp [word bp-6],VGA_SCREEN_WIDTH
    jb @@draw

    mov [word bp-6],0           ; x = 0
    add [word bp-8],cx          ; y += height
    cmp [word bp-8], VGA_SCREEN_HEIGHT
    jb @@draw
    
@@end:
    pop ds
    popa
    restore_sp_bp
    ret 4      ; <--- set return value
ENDP TileBmp

;------------------------------------------------------------------------
; Displays the BMP on the screen
;
; DeleteBMP seg, struct
;------------------------------------------------------------------------
;MACRO DeleteBMP bmp_seg, bmp_struct
;    local _end
;    push si
;    push es
;    push ds
;    mov ds, bmp_seg
;    mov si,offset bmp_struct
;    add si, BMP_DATA_SEG_OFFSET
;    cmp [word ds:si],0
;    jz _end                         ; NULL pointer
;    push [word ds:si]
;    pop es
;    HeapFree
;    mov [word ds:si],0              ; mark as NULL
;_end:    
;    pop ds
;    pop es
;    pop si
;ENDM
;------------------------------------------------------------------------
; This procedure checks to make sure the file is a valid BMP,
; and gets some information about the graphic.
;
; push struct addr
; push struct seg
; call ReadHeaderToStruct
;------------------------------------------------------------------------
PROC ReadHeaderToStruct
    store_sp_bp
    pusha

    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => struct segment
	; bp+6 => struct address
	; saved registers

    mov cx,BMP_HEADER_LEN
    mov dx,[word bp+6]
    add dx, BMP_HEADER_OFFSET

    push cx                 ; length
    push dx                 ; header address
    push [word bp+4]        ; segment
    call fread              ; read header

    push [word bp+6]
    push [word bp+4]
    call CheckValidStruct   ; Is it a valid BMP file?

    jc @@RHdone             ; No? Quit.    

    push [word bp+6]
    push [word bp+4]
    call GetBMPInfoStruct   ; Otherwise, process the header.

@@RHdone:
    popa
    restore_sp_bp
    ret 4
ENDP ReadHeaderToStruct

;------------------------------------------------------------------------
; Check the first two bytes of the file. If they do not
; match the standard beginning of a BMP header ("BM"),
; the carry flag is set.
;
; push struct addr
; push struct seg
; call CheckValidStruct
;------------------------------------------------------------------------
PROC CheckValidStruct 
    store_sp_bp
    pusha
    push es
    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => struct segment
	; bp+6 => struct address
	; saved registers

    clc                     ; clear carry flag
    mov si,[word bp+6]
    add si,BMP_HEADER_OFFSET
    
    push [word bp+4]        ; seg
    pop es

    mov di,offset BMPStart
    mov cx,2                ; BMP ID is 2 bytes long.
@@CVloop:
    mov al,[es:si]          ; Get a byte from the header.
    mov dl,[di]
    cmp al,dl               ; Is it what it should be?
    jne @@NotValid          ; If not, set the carry flag.
    inc si
    inc di
    loop @@CVloop

    jmp @@CVdone

@@NotValid:
    stc                     ; set carry flag for error

@@CVdone:
    pop es
    popa
    restore_sp_bp
    ret 4
ENDP CheckValidStruct 
;------------------------------------------------------------------------
; This procedure pulls some important BMP info from the header
; and puts it in the appropriate variables.
; mov ax,header[0Ah] ; AX = Offset of thebeginning of the graphic.
;
; push struct addr
; push struct seg
; call CheckValidStruct
;------------------------------------------------------------------------
PROC GetBMPInfoStruct
    store_sp_bp
    pusha
    push es
    
    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => struct segment
	; bp+6 => struct address
	; saved registers


    mov si, [word bp+6]
    add si, BMP_HEADER_OFFSET       ; si = header address within struct

    push [word bp+4]
    pop es                          ; header seg   (es:si)

    mov ax, [word es:si+0aH]
    sub ax,BMP_HEADER_LEN           ; Subtract the length of the header
    shr ax,2                        ; and divide by 4
    
    mov bx, [word bp+6]
    add bx, BMP_PALETTE_SIZE_OFFSET
    mov [es:bx],ax                  ; to get the number of colors in the BMP
                                    ; (Eachpalette entry is 4 bytes long).
                                    ;mov ax,header[12h] ; AX = Horizontal resolution (width) of BMP.

    mov ax, [word es:si+12h]
    mov bx, [word bp+6]
    add bx, BMP_WIDTH_OFFSET
    mov [es:bx],ax                  ; Store it.
                                    ;mov ax,header[16h] ; AX = Vertical resolution (height) of BMP.
    mov dx, [word es:si+16h]
    mov bx, [word bp+6]
    add bx, BMP_HEIGHT_OFFSET
    mov [es:bx],dx                  ; Store it.

    ; ax = width
    ; dx = height
    shr ax,4                        ; ax / 16 (# of mem paragraphs)
    mul dx                          ; w * h
    mov bx, [word bp+6]
    add bx, BMP_DATA_SIZE_OFFSET
    mov [es:bx],ax                  ; Store it.   

    pop es
    popa
    restore_sp_bp
    ret 4
ENDP GetBMPInfoStruct 
;------------------------------------------------------------------------
; Read the video palette.
;
; push struct addr
; push struct seg
; call ReadPalStruct
;------------------------------------------------------------------------
PROC ReadPalStruct
    store_sp_bp
    pusha
    push es
    
    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => struct segment
	; bp+6 => struct address
	; saved registers
    
    push [word bp+4]
    pop es

    mov si, [word bp+6]
    add si, BMP_PALETTE_SIZE_OFFSET

    mov cx,[es:si]          ; CX = Number of colors in palette.
    shl cx,2                ; CX = Multiply by 4 to get size (in bytes)
                            ; of palette.
    mov dx, [word bp+6]
    add dx, BMP_PALETTE_OFFSET
    
    push cx
    push dx
    push ds
    call fread

    pop es
    popa
    restore_sp_bp
    ret 4
endp ReadPalStruct
;------------------------------------------------------------------------
; This procedure goes through the palette buffer, sending information about
; the palette to the video registers. One byte is sent out
; port 3C8h, containing the number of the first color in the palette that
; will be sent (0=the first color). Then, RGB information about the colors
; (any number of colors) is sent out port 3C9h.
;
; push struct addr
; push struct seg
; call SendPalStruct
;------------------------------------------------------------------------
PROC SendPalStruct
    store_sp_bp
    pusha
    push es
    push ds

    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => struct segment
	; bp+6 => struct address
	; saved registers

    push [word bp+4]
    pop ds

    mov si, [word bp+6]
    add si, BMP_PALETTE_OFFSET  ; Point to buffer containing palette.

    mov di, [word bp+6]
    add di, BMP_PALETTE_SIZE_OFFSET

    mov cx,[ds:di]          ; CX = Number of colors to send.

    mov dx,3c8h
    mov al,0                ; We will start at 0.
    out dx,al
    inc dx                  ; DX = 3C9h.
@@sndLoop:
    ; Note: Colors in a BMP file are saved as BGR values rather than RGB.

    mov al,[ds:si+2]        ; Get red value.
    shr al,2                ; Max. is 255, but video only allows
                            ; values of up to 63. Dividing by 4
                            ; gives a good value.
    out dx,al               ; Send it.
    mov al,[ds:si+1]           ; Get green value.
    shr al,2
    out dx,al               ; Send it.
    mov al,[ds:si]             ; Get blue value.
    shr al,2
    out dx,al               ; Send it.

    add si,4                ; Point to next color.
                            ; (There is a null chr. after every color.)
    loop @@sndLoop

    pop ds
    pop es
    popa
    restore_sp_bp
    ret 4
ENDP SendPalStruct 
;------------------------------------------------------------------------
; BMP graphics are saved upside-down. This procedure reads the graphic
; line by line, displaying the lines from bottom to top. The line at
; which it starts depends on the vertical resolution, so the top-left
; corner of the graphic will always be at the top-left corner of the screen.
;
; The video memory is a two-dimensional array of memory bytes which
; can be addressed and modified individually. Each byte represents
; a pixel on the screen, and each byte contains the color of the
; pixel at that location.
;
; push struct addr
; push struct seg
; call LoadBMPData
;------------------------------------------------------------------------
PROC LoadBMPData 
    store_sp_bp
    sub sp,4
    pusha
    push es
    push ds

    ; now the stack is
    ; bp-4 => height
    ; bp-2 => width
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => struct segment
	; bp+6 => struct address
	; saved registers

    ;{
    varWidth                equ         [word bp-2]
    varHeight               equ         [word bp-4]
    structSegment           equ         [word bp+4]
    structAddress           equ         [word bp+6]
    ;}

    push structSegment
    pop ds

    mov si,structAddress
    add si, BMP_HEIGHT_OFFSET

    mov cx,[word ds:si]          ; height - We're going to display that many lines
    mov varHeight, cx

    mov si,[word bp+6]
    add si, BMP_WIDTH_OFFSET
    mov dx, [ds:si]             ; width
    mov varWidth, dx

    push dx
    ; allocate memory  
    mov ax, dx
    mul cx                      ; width * height
    add ax, 15                  ; make sure it falls into a paragraph
    shr ax, 4                   ; divide by 16 for the number of mem paragraphs
    push ax
    call malloc
    jc @@end

    pop dx

    ; store pointer to data
    mov si,structAddress
    add si, BMP_DATA_SEG_OFFSET
    mov [word ds:si],ax

    push ax
    pop es
    xor si,si               ; es:si - pointer to data start

    mov cx,varHeight        ; height 
@@ShowLoop:
    push dx                 ; width
    push si                 ; addr
    push es                 ; seg
    call fread

    add si, dx               ; si += width
    loop @@ShowLoop

@@end:
    pop ds
    pop es
    popa
    restore_sp_bp
    ret 4
ENDP LoadBMPData
;------------------------------------------------------------------------
; PROC Description:
; Free data segment from BMP struct
; 
; push struct addr
; push struct seg
; call FreeBmp
;------------------------------------------------------------------------
PROC FreeBmp
    store_sp_bp
    push si di ax es

    ; now the stack is
    ; bp-2 => 
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => struct seg
    ; bp+6 => struct addr
    ; saved registers

    ;{
    addr_       equ     [word bp+6]
    seg_        equ     [word bp+4]
    ;}

    mov si, addr_
    add si, BMP_DATA_SEG_OFFSET
    push seg_
    pop es

    mov di, [word es:si]                ; segment of allocated data

    push di
    call mfree
 
@@end:
    pop es ax di si
    restore_sp_bp
    ret 4               
ENDP FreeBmp
