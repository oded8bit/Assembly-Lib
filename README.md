# Assembly Library
For more projects, [click here](http://odedc.net)

A 16-bits DOS Assembly library that provides many useful functions for developing programs. It has both VGA grapics functions as well as general purpose utilities. The main purpose of this library was to be able to implement simple DOS games (in Assembly) using VGA (320x200, 256 colors) display.

**Note** The library was developed and tested using [TASM 4.1](https://sourceforge.net/projects/guitasm8086/files/) and [DosBox](https://www.dosbox.com/)

# Graphics 
The library provides the following graphics capabilities:
1. General purpose [graphics utilities](GrLib/graphx.asm)
2. Manipulate color [palettes](GrLib/color.asm)
3. Draw [lines](GrLib/line.asm)
4. Draw [rectangles](GrLib/rect.asm) (outline and filled)
5. Draw closed [polygons](GrLib/poly.asm) (outline only)
6. Draw [circles](GrLib/circle.asm) (outline and filled)
7. Draw [Bitmaps](GrLib/bmp.asm) 
8. Draw images [images](GrLib/image.asm) 
9. Draw animated [sprites](GrLib/anim.asm)
10. Support for [Double buffering](GrLib/dblbuf.asm)

To include the graphics library use the following at the top of your CODESEG
```sh
    include "GrLib.inc"
```

# Utilities
The library contains an utility package with many useful macros and procedures such as:
1. [File](UtilLib/file.asm) management
2. [Keyboard](UtilLib/keys.asm) management, including ISR support
3. [Mouse](UtilLib/mouse.asm) input
4. Several [Math](UtilLib/math.asm) and randomizer functions
5. Memory [management](UtilLib/mem.asm) (allocation and deallocation on the heap)
6. Printing to the [screen](UtilLib/print.asm)
7. Support for playing [sound](UtilLib/sound.asm)
8. [Time](UtilLib/time.asm) functions for delays

To include the graphics library use the following at the top of your CODESEG. Note that this include
**MUST** come before including the graphics library.
```sh
    include "UtilLib.inc"
```

# Using the library
To use the linraries, include the files in your code as follows:
```sh
CODESEG
    include "UtilLib.inc"
    include "GrLib.inc"   
```

Here is a sample program that draws a line and waits for a key press, using double buffering:

```sh
.486
IDEAL
MODEL small
	stack 256
DATASEG	

CODESEG
    include "UtilLib.inc"
    include "GrLib.inc"   
start:
	mov ax, @data
	mov ds,ax

    ; Free redundant memory take by program
    ; to allow using malloc
    call FreeProgramMem
    
    ; Allocate double buffering memory space
    call AllocateDblBuffer

    ; Init library and set display to VGA mode
    ut_init_lib
    gr_set_video_mode_vga

    ; Set initial pen color
    gr_set_color GR_COLOR_GREEN

    ; your code here
    grm_DrawLine  10, 10, 200, 200

exit:
    call WaitForKeypress    
    call ReleaseDblBuffer
    gr_set_video_mode_txt
    return 0
END start    
``` 

Build the program using
```sh
tasm /zi prog.asm
tlink /v prog
```

# PROCs and MACROs
The library provides many Procedures and Macros that you can use directly in your code. To make life easier (and have the code look more like a high level language), a wrapper MACRO was provided to many of the PROCs. Both options yield the same outcome.

For example, you can draw a line using the PROC
```sh
    push x1
    push y1
    push x2
    push y2
    call GR_DrawLine
```
or using a wrapper MACRO

```sh
    grm_DrawLine x1, y1, x2, y2
```

Make sure you pass the arguments in the right order. All procedures preserve register values, unless stated otherwise.
Macros (not including wrapper macros), on the other hand, may alter register values. Check out their documentation for details.

# ---------------------------------------------------------------
# Graphics Library

### Drawing a pixel
The most basic macros handle drawing a single pixel on the screen, using direct memory access (not interrupt).
```sh
gr_set_pixel x, y, color - draws a pixel in the given (x,y) coordinates with the given [color](GrLib/colors.asm)
gr_set_pixel_xy  x,y - draws a pixel in the given (x,y) coordinates with the set [color](GrLib/colors.asm)
```
**Note** that x, y and color cannot use the following registers: ax, bx, di, dx

This macro takes into account double buffering and will draw to the buffer (if set) instead of the video display.

It is **highly recommended** to use this macto whenever you want to draw to the VGA screen.

### Clearing the screen
There are 2 ways to clear the screen, or a portion of the screen
```sh
clear_screen - macro that very efficiently clears the entire screen
GR_ClearRect - procedure that clears a rectangle on the screen
```

# Drawing Shapes

### Drawing Lines
Using a PROC:
```sh
    push  50    ; x1
    push  60    ; y1
    push  120   ; x2
    push 180    ; y2
    call GR_DrawLine
```
or using a MACRO:
```sh
    grm_DrawLine 50, 60, 120, 180
```

### Drawing Rectangles
You can either draw a rectangle outline or a filled one.

Outline using a PROC:
```sh
    push  50    ; x (top)
    push  60    ; y (top)
    push  120   ; width
    push 180    ; height
    call GR_DrawRect
```
or using a MACRO:
```sh
    grm_DrawRect 50, 60, 120, 180
```

Filled using a PROC:
```sh
    push  50    ; x (top)
    push  60    ; y (top)
    push  120   ; width
    push 180    ; height
    call GR_FillRect
```
or using a MACRO:
```sh
    grm_FillRect 50, 60, 120, 180
```

### Drawing Circles
You can either draw a circle outline or a filled one.

Outline using a PROC:
```sh
    push  150    ; X center
    push  100    ; Y center
    push  40   ; Radius
    call GR_DrawCircle
```
or using a MACRO:
```sh
    grm_DrawCircle 150, 100, 40
```

Filled using a PROC:
```sh
    push  150    ; X center
    push  100    ; Y center
    push  40   ; Radius
    call GR_FillCircle
```
or using a MACRO:
```sh
    grm_FillCircle 150, 100, 40
```

### Drawing Polygons
To draw a polygon, you need to define an array and pass its pointer along with the number of points in the array.
The array should contain **points** (x and y) as follows:
```sh
DATASEG	
    _poly    dw     5,30,100,50,200,100
```
This is an array with the following points:
1. _poly[0] = (5,30)
2. _poly[1] = (100,50)
3. _poly[2] = (200,100)


Using a PROC:
```sh
    push 3              ; there are 3 points
    push offset _poly   ; pointer to _poly array
    call GR_DrawPolygon
```
or using a MACRO:
```sh
    mov ax, offset _poly
    grm_DrawPolygon 3, ax
```

# Using Bitmaps
The library support only 8-bit bitmaps in v3. To load a bitmap, you need to define the following variable:
```sh
    BMP_W           equ         30
    BMP_H           equ         44
    bmp_file        db "asset\\my_bmp.bmp",0
    THE_BMP         db BMP_STRUCT_SIZE dup(0)
```
This will allocate the memory for the BMP headers (struct). Memory allocation for the pixels' data will be 
allocated in RAM when loading the data.

**You must** use "call FreeProgramMem" before trying to load images or you will get an out of memory situation and the allocation will fail.

To load a BMP image, call:
```sh
    mov dx, offset bmp_file
    mov cx, offset THE_BMP      
    
    push dx                     ; path offset
    push ds                     ; path segment
    push cx                     ; bitmap struct offset
    push ds                     ; bitmap struct segment
    call LoadBMPImage
```
or using a MACRO
```sh
    grm_LoadBMPImage dx, ds, cx, ds
```
After loading the bitmap, you can draw it on the screen
```sh
    push cx                     ; bitmap struct offset
    push ds                     ; bitmap struct segment
    push 000Ah                  ; xTop = 10
    push 000Bh                  ; yTop = 11
    call DisplayBMP
    
    ; instead, you can tile the image on the screen using
    push cx
    push ds
    call TileBmp
```
or using MACROS:
```sh
    grm_DisplayBMP  cx, ds, 000Ah, 000Bh
    ; or
    grm_TileBmp  cx, ds
```
**You must** free the bitmap memory (when it is not needed anymore) by calling
```sh
    push cx                     ; bitmap struct offset
    push ds                     ; bitmap struct segment
    call FreeBmp
```
or using MACROS:
```sh
    grm_FreeBmp  cx, ds
```

# Sprites




# ---------------------------------------------------------------
# Utilities Library

The library includes other utilities that help developing assembly programs. 
```sh
    store_sp_bp         - macro that stores and sets BP value. Called at the beginning of PROC
    restore_sp_bp       - macro that restores BP, SP values. Called at the end of PROC
    return              - macro for returning control to DOS with a code
    cmpv                - macro that compare two memory variables
    movv                - moves a WORD from one memory to another via the stack
```

# Time and Delays
The library provides 3 different ways to delay your program:

### Sleep
If you want your program to halt for a given number of seconds call the Sleep procedure
```sh
    push 3              ; sleeps for 3 seconds
    call Sleep
```
or using MACROS:
```sh
    utm_Sleep  3
```

### Delay
Delay program execution by X number of milliseconds. Actually, the argument is the number of 
1/18 of a second
```sh
    push 3              ; Delay for 3 * 1/18 of a sec
    call Delay
```
Or:
```sh
    utm_Delay 3
```

### DelayMS
This function delays execution for given number of microseconds which are specified in 2 variables, one for the high order and one for the low order.
For example, a 1 second delay (1 * 1,000,000 msec) is 000F 4240 and therfore the values will be
```sh
    push 000Fh
    push 4240h
    call DelayMS
```
Or
```sh
    utm_DelayMS 000Fh, 4240h
```
Another example, a 2 seconds delay is equal to (2*1,000,000) 001E 8480 and a 1 millisecond is (1*1000) 0000 03EB

# Keyboard
Most keyboard functions are accessible via interrupts and the library focuses on some less trivial parts of handling the keyboard.

### Repeat Rate
Setting keyboard yypematic rate to defalt (repeat delay and rate)
```sh
    call SetKeyboardRateDefault
```

### Wait for keypress
Hold program execution until a key is pressed
```sh
    call WaitForKeypress
```

### Keyboard Status
Getting keyboard status
```sh
    call GetKeyboardStatus
```
Returns:
ZF = 0 if a _Key pressed (even Ctrl-Break)
AX = 0 if no scan code is available
AH = scan code
AL = ASCII character or zero if special function _Key

