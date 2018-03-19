# Assembly Library
For more projects, [click here](http://odedc.net)

A 16-bits x86 DOS Assembly library that provides many useful functions for developing programs. It has both VGA grapics functions as well as general purpose utilities. The main purpose of this library was to be able to implement simple DOS games (in Assembly) using VGA (320x200, 256 colors) display.

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
8. [Images & screen](GrLib/image.asm) manipulations
9. Draw [sprites](GrLib/anim.asm) and animation
10. Support for [Double buffering](GrLib/dblbuf.asm)

# Utilities
The library contains an utility package with many useful macros and procedures such as:
1. [File](UtilLib/file.asm) management
2. [Keyboard](UtilLib/keys.asm) management, including ISR support
3. [Mouse](UtilLib/mouse.asm) input
4. Several [Math](UtilLib/math.asm) and randomizer functions
5. Memory [management](UtilLib/mem.asm) (allocation and deallocation on the heap)
6. [String](UtilLib/string.asm) operations
7. Printing to the [screen](UtilLib/print.asm)
8. Support for playing [sound](UtilLib/sound.asm)
9. [Time](UtilLib/time.asm) functions for delays


# Using the library
To use the libraries, include the files in your code as follows:
```sh
CODESEG
    include "UtilLib.inc"
    include "GrLib.inc"   
```
Note that UtilLib.inc **MUST** come before GrLib.inc

Here is a sample program that draws a line and waits for a key press, using double buffering:

```sh
.486
IDEAL
MODEL small
STACK 256
DATASEG	

CODESEG
    include "UtilLib.inc"
    include "GrLib.inc"   
start:
    mov ax, @data
    mov ds,ax

    ; Init library with double buffering flag on
    mov ax, TRUE
    ut_init_lib ax
  
    ; Allocate double buffering memory space
    call AllocateDblBuffer

    ; set display to VGA mode
    gr_set_video_mode_vga

    ; Set initial pen color
    gr_set_color GR_COLOR_GREEN

    ; your code here - we will draw a line...
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
tasm /zi main.asm
tlink /v main
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

# Initializing the library
At the beginning of your code, you need to initialize the library by calling:
```sh
CODESEG
    ; Init library
    mov ax, FALSE
    ut_init_lib ax
```

The flag shoule be set to TRUE if you intend to dynamically allocate memory in your program. See  [memory management](UtilLib/mem.asm)

**Note** that TRUE and FALSE are defined by the library as 1 and 0.

# Testing the library and code samples
The [Tests](Tests/tests.asm) folder includes a testing file that demonstrates the use of various parts of the library. the test program itself 
can be found at the root and is called [main.asm](main.asm)

# TicTac Game
A simple TicTac game that uses many of the library's features, was added to the library. You can compile and run the game using:
```sh
tasm /zi tictac.asm
tlink /v tictac
```
The game itself can be found under [Tests/tic](Tests/tic) folder and the main file is [tictac.asm](tictac.asm)

# ---------------------------------------------------------------
# Graphics Library

### Drawing a pixel
The most basic macros handle drawing a single pixel on the screen, using direct memory access (not interrupt).
```sh
gr_set_pixel    x, y, color - draws a pixel in the given (x,y) coordinates with the given color
gr_set_pixel_xy x,y         - draws a pixel in the given (x,y) coordinates with the set color
```
**Note** that x, y and color cannot use the following registers: ax, bx, di, dx

This macro takes into account double buffering and will draw to the buffer (if set) instead of the video display. See
[Double Buffering](GrLib/dblbuf.asm) for details.

It is **highly recommended** to use this macro whenever you want to draw to the VGA screen.

### Clearing the screen
There are 3 ways to clear the screen, or a portion of the screen
```sh
clear_screen_vga    - macro that very efficiently clears the entire screen (VGA mode)
GR_ClearRect        - procedure that clears a rectangle on the screen (VGA mode)
clear_screen_txt    - macro that very efficiently clears the entire screen (TXT mode)
```

# Drawing Shapes

### Drawing Lines
Drawing a line using a PROC:
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
_bmp_file               db      "asset\\b.bmp",0
_bmp                    db      BMP_STRUCT_SIZE dup(0)
```
This will allocate the memory for the BMP headers (struct). Memory allocation for the pixels' data will be 
allocated in RAM when loading the data.

**You must** use "call FreeProgramMem" before trying to load images or you will get an out of memory situation and the allocation will fail.
Note that you can implicitly call it by passing TRUE to ut_init_lib:
```sh
mov ax, TRUE
ut_init_lib TRUE
```

To load a BMP image, call:
```sh
mov dx, offset _bmp_file
mov cx, offset _bmp      

push dx                     ; path offset
push ds                     ; path segment
push cx                     ; bitmap struct offset
push ds                     ; bitmap struct segment
call LoadBMPImage
```
or using a MACRO
```sh
mov dx, offset _bmp_file
mov cx, offset _bmp      

grm_LoadBMPImage dx, ds, cx, ds
```
After loading the bitmap, you can draw it on the screen
```sh
mov cx, offset _bmp      

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
mov cx, offset _bmp      

grm_DisplayBMP  cx, ds, 000Ah, 000Bh
; or
grm_TileBmp  cx, ds
```
**You must** free the bitmap memory (when it is not needed anymore) by calling
```sh
mov cx, offset _bmp      

push cx                     ; bitmap struct offset
push ds                     ; bitmap struct segment
call FreeBmp
```
or using MACROS:
```sh
grm_FreeBmp  cx, ds
```

### Saving and Loading Palettes
The library provides methods for extracting color palettes of BMP files and storing them in a new file (binary) as well as load a palette file into 
a buffer (possibly the palette of a BMP structure).

Here is an example of saving a palette to a file:
```sh
mov dx, offset _bmp_file
mov ax, offset _bmp
grm_LoadBMPImage dx, [_dss], ax, [_dss]

mov ax, offset _bmp
mov bx, offset _paletteFile
grm_SavePalette ax, [_dss], bx
```

and loading it to a buffer:
```sh
push offset _paletteFile
push ds
push offset _palette
push ds
call LoadPalette
```


# Sprites
The library supports sprites, which is an image with multiple frames. Sprites are a great way to create animation or to hold multiple variants of an image.
See an [example](asset/sprite1.bmp).

Since sprites are standard BMP files, you load them normally and then can display any frame you select.

```sh
DATASEG
    _sprite_w       equ         30
    _sprite_frames  equ         6
    _sprite_file db      "asset\\sprite1.bmp",0
    _sprite      db      BMP_STRUCT_SIZE dup(0)

CODESEG    
    mov dx, offset _sprite_file         
    mov ax, offset _sprite          

    push dx                         ; path address
    push ds                         ; path segment
    push ax                         ; struct address
    push ds                         ; struct segment
    call LoadBMPImage

    push 0                  ; frame index
    push ax                 ; BMP struct address
    push ds                 ; BMP struct segment
    push 0064h              ; x coordinate
    push 0064h              ; y coordinate
    push _sprite_w          ; width of a single frame
    push _sprite_frames     ; number of frames in BMP
    call PlaySpriteInPlace    
```
or using macros:
```sh
CODESEG    
    mov dx, offset _sprite_file         
    mov ax, offset _sprite          

    grm_LoadBMPImage dx, ds, ax, ds
    grm_PlaySpriteInPlace 0, ax, ds, 0064h, 0064h, _sprite_w, _sprite_frames
```

Take a look at [TestMySprite](Tests/tests.asm) function as an example for playing animation using sprites.

Here is an example of a [sprite image](asset/sprite1.bmp)

### Copy screen to buffer and visa versa
The library provide functions for copying a portion of the screen to a buffer and visa versa (from a buffer to the screen).

```sh
grm_SaveScreen memAddress, memSeg, x, y, w, h
```

```sh
grm_WriteScreen memAddress, memSeg, x, y, w, h
```

# ---------------------------------------------------------------
# Utility Library

The library includes other utilities that help developing assembly programs. 
```sh
store_sp_bp         - macro that stores and sets BP value. Called at the beginning of PROC
restore_sp_bp       - macro that restores BP, SP values. Called at the end of PROC
return              - macro for returning control to DOS with a code
cmpv                - macro that compare two memory variables
movv                - moves a WORD from one memory to another via the stack
```
### Data Segment 
The library stores the original data segment (DS register) using a global variable **_dss** that you can access at any time if you need to restore its value.
```sh
push [_dss]
pop ds
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
A list of keyboard [scan codes](http://stanislavs.org/helppc/scan_codes.html) can be found at [keymap.asm](UtilLib/keymap.inc)

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

### Consume Key
Taking the pressed key out of the keyboard buffer
```sh
call ConsumeKey
```

### Get keyboard flags
```sh
call GetKeyboardFlags
```
Returns AL:
|7|6|5|4|3|2|1|0|  AL or BIOS Data Area 40:17
		 | | | | | | | `---- right shift key depressed
		 | | | | | | `----- left shift key depressed
		 | | | | | `------ CTRL key depressed
		 | | | | `------- ALT key depressed
		 | | | `-------- scroll-lock is active
		 | | `--------- num-lock is active
		 | `---------- caps-lock is active
		 `----------- insert is active

### Install & Restore a Keyboard ISR
You can replace the default keyboard interrupt with your own by calling this procedure 
```sh
push isr_address 
call InstallKeyboardInterrupt
```
For example:
```sh
lea dx,[my_interr]
push dx
call InstallKeyboardInterrupt
```
You **must** restore the interrupt at the end of the program by calling
```sh
call RestoreKeyboardInterrupt
```

#### Sample Keyboard Interrupts
The library contains 2 sample implementations of a keyboard ISR. 
1. KeyboardSampleISR - implements a FIFO buffer and allows retrieving keys using getcISR. Note that this is **not**
a complete implementation but merely an example. For instance, it does not convert the scancode to ASCII and does not
treat SHIFT, CTRL and ALT combinations.
2. KeyboardISREvents - a simple implementation that illustrates how to call the default keyboard handler

See [TestKeyboardISR and TestSimpleISR](Tests/tests.asm)

# Mouse 
Most mouse functions are accessible via interrupts and the library focuses on some less trivial parts of handling the mouse.

### Show and Hide the mouse
Use these macros to show / hide the mouse
```sh
ShowMouse

HideMouse
```
### Get Mouse Status
Mouse position and button status can be retrieved by
```sh
GetMouseStatus
```
On return:
	CX = horizontal (X) position  (0..639)
	DX = vertical (Y) position  (0..199)
	BX = button status:

		|F-8|7|6|5|4|3|2|1|0|  Button Status
		  |  | | | | | | | `---- left button (1 = pressed)
		  |  | | | | | | `----- right button (1 = pressed)
		  `------------------- unused

### Translate Mouse Coordinates
After getting mouse coordinates from **GetMouseStatus**, you can translate them to VGA coordinates by calling
```sh
TranslateMouseCoords
```

### Set Mouse Cursor Position
```sh
mov cx, 3       ; horizontal
mov dx, 5       ; vertical
SetMousePosition
```

### Installing and Restoring Mouse ISR
You can replace the default mouse interrupt with your own by calling this procedure 
```sh
push ISR address
push ISR segment
push mask
call InstallMouseInterrupt
```
You **must** restore the interrupt at the end of the program by calling
```sh
call UninstallMouseInterrupt
```

# File System
The library provide a set of functions to access and manipulate files. The library was designed to handle a single file at any time using the global variables
```sh
_fHandle    - stores the handle of the openned file
_fErr       - stores the error value
```

### Open a File
```sh
push address_of_file_name
push segment_of_file_name
call fopen
```
or using MACROS:
```sh
utm_fopen address_of_file_name, segment_of_file_name
```

### Create a New File
```sh
push address_of_file_name
push segment_of_file_name
call fnew
```
or using MACROS:
```sh
utm_fnew address_of_file_name, segment_of_file_name
```
### Close a File
```sh
call fclose
```
or using MACROS:
```sh
utm_fclose
```

### Get File Size
```sh
push address_of_file_name
push segment_of_file_name
call fsize
```
or using MACROS:
```sh
utm_fsize address_of_file_name, segment_of_file_name
```

### Read from a File
```sh
push length
push address_of_buffer
push segment_of_buffer
call fread
```
or using MACROS:
```sh
utm_fread address_of_buffer, segment_of_buffer
```
### Write to a File
```sh
push length
push address_of_buffer
push segment_of_buffer
call fwrite
```
or using MACROS:
```sh
utm_fwrite address_of_buffer, segment_of_buffer
```
### Delete a File
```sh
push address_of_file_name
push segment_of_file_name
call fdelete
```
or using MACROS:
```sh
utm_fdelete address_of_file_name, segment_of_file_name
```
### Change File Attributes
```sh
push attribute
push address_of_file_name
push segment_of_file_name
call fchangeAttr
```
or using MACROS:
```sh
utm_fchangeAttr attribute, address_of_file_name, segment_of_file_name
```
### File Seek
You can do a fseek in a file very similar to the C function
```sh
grm_fseek SEEK_SET, 0, 40
```
Or:
```sh
push SEEK_SET
push 0
push 40
call fseek
```
The first parameter can be SEEK_CUR, SEEK_SET or SEEK_END. 
The second parameter is the high order of the offset and the third is the low order.

# Directory Services
The library provides a few directory services, including:
```sh
mkdir OR utm_mkdir   - create a directory
rmdir OR utm_rmdir   - delete a directory
chdir OR utm_chdir   - change a directory
```

# Math 
The library provide some basic math related functions and macros

### Random Numbers
Before generating a random number, you need to initialize the number generator by calling
```sh
call RandomSeed
```
and then you can use 
```sh
call RandomWord
or
call RandomByte    
```
to get a random number in AX or AL

### Abs(x)
You can get the absoilute value of a number 
```sh
gr_absolute number
```

# Memory Management
The library allows managing (allocating, releasing) RAM memory. If you need to allocate dynamic memory, you **must** free unused memory at the
beginning of your program by calling:
```sh
call FreeProgramMem
```
If you forget to call it, all memory allocations will fail on "out of memory".

Note that you can implicitly call it by passing TRUE to ut_init_lib:
```sh
mov ax, TRUE
ut_init_lib TRUE
```

### Allocating a block
Allocating a memory block is done by calling:
```sh
push size
call malloc
```
Note that the size is measured in Paragraphs and therefore need to be divided by 16 (bytes)

Return value: 
AX = segment address of allocated memory block (MCB + 1para)
     0 on error 
BX = size in paras of the largest block of memory available
     0 on error
CF = 0 if successful
   = 1 if error
Allocated memory is at AX:0000

### Release an allocated memory block
Pass the segment address of the allocated memory block to release it
```sh
push segment
call mfree
```

### Releasing all allocated blocks
The library maintains an internal list of up to 50 allocated blocks that can be freed by calling
```sh
call mfreeAll
```

### Memory Copy
Copies memory from one address to another
```sh
push from_address
push from_seg
push to_address
push to_seg
push length_in_bytes
call MemCpy
```

### Initialize memory block
You can set a byte or word value to an entire memory block
```sh
mov ax, offset _blcok

push 10             ; length_in_bytes
push ds             ; block_segment
push ax             ; block_offset
push 0              ; value
call SetMemByte
```
and
```sh
mov ax, offset _blcok

push 5              ; length_in_words
push ds             ; block_segment
push ax             ; block_offset
push 0              ; value
call SetMemWord
```

# Sound
You can make a beep with the following procedure. Note that the sound will continue until you stop it
```sh
push frequency
call Beep

utm_Sleep  2        ; wait 2 seconds

call StopBeep
```
Or with macros:
```sh
utm_Beep freq
utm_Sleep 2
utm_StopBeep
```

# Print
This part of the library supports writting text to the screen

### Printing to the screeb
```sh
call PrintDecimal   - prints a value as a decimal number

call PrintChar      - prints DL as a char
PrintCharNewLine    - macro to print a char with new line

call PrintByte      - prints DL (number between 0 and 15)
PrintByteNewLine    - macro to print a byte with a new line

call PrintStr       - prints a string. DS:DX pointer to string ending in "$"
PrintStrNewLine     - macro to print a string with a new line

call PrintNewLine   - prints a new line
call PrintSpace     - prints a space char

call PrintHexByte   - prints the LSB BYTE in HEX
call PrintHexByte   - prints the WORD in HEX
```

### Printing in VGA
```sh
call PrintCharVGA   - prints a character on VGA display (DL: char, BL: color)
call PrintStrVGA    - prints a string to the VGA screen    
```

## Setting cursor position
```sh
push x
push y
call SetCursorPosition
```


# String Manipulations
The library contains several basic string manipulations functions that accept null terminating string

```sh
Strlen       - Calculates length of string ending with NULL
StrlenDollar - Calculates length of string ending with '$'
Strcpy       - Copies string s2 into string s1
Strncpy      - Copies given number of chars from string s2 into string s1.
Strcat       - concatenate 2 strings
Strchr       - Searches for the first occurrence of the character in the given string
Strcmp       - Compares the string pointed to, by str1 to the string pointed to by str2.
```

# License
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty
of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

-------------------------------------------------------------------------
# Credits
1. Some ideas were taken from https://github.com/itay-grudev/assembly-dos-gx
2. README file created using [Dillinger](https://dillinger.io/)
