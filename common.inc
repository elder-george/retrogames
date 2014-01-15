VMEM        EQU 0a000h
SCREENW     EQU 320
SCREENH     EQU 200

%macro ccall 2-*                        
%define _j %1
%assign __params %0-1
%rep %0-1
    %rotate -1
    push %1
%endrep
    call _j
    %assign __params __params * 2
    add sp, __params
%endmacro

%macro mode13h 0
    mov ax, 13h
    int 10h
%endm

%macro coord 2
%define X %1
%define Y %2
    mov ax, Y
    shl ax, 2           ; 320 = 256 + 64 = (4 + 1) * 64
    add ax, Y
    shl ax, 6
    add ax, %1
%endm

KEY_LEFT    EQU 75
KEY_RIGHT   EQU 77
KEY_UP      EQU 72
KEY_DOWN    EQU 80

KEY_ESC     EQU 1
KEY_SPACE   EQU 57
KEY_ENTER   EQU 28
KEY_NUM_MIN EQU 2
KEY_NUM_MAX EQU 11

