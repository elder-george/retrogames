;entry point
global start

; in vga.asm
extern fillRect
extern drawMask
extern drawMaskBin
extern drawChar
extern drawDigitString
extern swapBuffers
extern clearBuffer


; in font.asm
extern digits


%include 'common.inc'

KEY_LEFT    EQU 75
KEY_RIGHT   EQU 77
KEY_UP      EQU 72
KEY_DOWN    EQU 80

KEY_ESC     EQU 1
KEY_SPACE   EQU 57
KEY_ENTER   EQU 28
KEY_NUM_MIN EQU 2
KEY_NUM_MAX EQU 11

MARGIN EQU 80
PADDLE_X_MIN EQU MARGIN
PADDLE_X_MAX EQU 320-MARGIN-32

section .code
start:
    cld
    mov ax, data
    mov ds, ax

    mode13h

loop:
    call swapBuffers
    call clearBuffer

    ccall drawMaskBin,5, paddleBin, word[paddleCoords.X], word[paddleCoords.Y]
    call checkKey
    jz loop
    call getKey
.isLeft:
    cmp al, KEY_LEFT
    jne .isRight
    sub word [paddleCoords.X], 2
.isRight:
    cmp al, KEY_RIGHT
    jne .clampLeft
    add word [paddleCoords.X], 2
.clampLeft:
    cmp word [paddleCoords.X], PADDLE_X_MIN
    jge .clampRight
    mov word [paddleCoords.X], PADDLE_X_MIN
.clampRight:
    cmp word [paddleCoords.X], PADDLE_X_MAX
    jle .done
    mov word [paddleCoords.X], PADDLE_X_MAX
.done:
    jmp loop

byteToDec:
    mov bp, sp
    mov al, [bp+4]
    mov bx, [bp+2]
    aam
    add al, '0'
    mov [bx+2], al
    mov al, ah
    aam
    add al, '0'
    mov [bx+1], al
    add ah, '0'
    mov [bx], ah
    ret

checkKey:
    mov ah, 1
    int 16h
    ret

getKey:
    in al, 60h
    ret

section data data
paddleCoords:
paddleCoords.X: dw 100
paddleCoords.Y: dw 200-8 

ballCoords:
ballCoords.X:   dw 116
ballCoords.Y:   dw 200-16

score:
    dw 0

buf:
    db '0','0','0',00
magicnumber:
    db "1234567890", 0
ball:
    dw 8,8
    db 0,0,0,1,1,0,0,0
    db 0,1,1,0,1,1,1,0
    db 0,1,0,0,0,1,1,0
    db 1,0,0,0,1,1,1,1
    db 1,1,0,1,1,1,1,1
    db 0,1,1,1,1,1,1,0
    db 0,1,1,1,1,1,1,0
    db 0,0,0,1,1,0,0,0

ballBin:
    db 1,8
    db 00011000b
    db 01101110b
    db 01000110b
    db 10001111b
    db 11011111b
    db 01111110b
    db 01111110b
    db 00011000b

paddle:
    dw 32, 8
    db 0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,0,0,0
    db 0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0
    db 0,1,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,1,0
    db 1,1,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1
    db 1,1,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1
    db 1,1,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,1,1
    db 1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1
    db 0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0

paddleBin:
   db 4,8
   db 00011110b, 00000000b, 00000000b, 01111000b
   db 01111111b, 11111111b, 11111111b, 11111110b
   db 01000111b, 11000000b, 00000011b, 11100010b
   db 11000111b, 11111111b, 11111111b, 11100011b
   db 11000111b, 11111111b, 11111111b, 11100011b
   db 11000111b, 11000000b, 00000011b, 11100011b
   db 11111111b, 11000000b, 00000011b, 11111111b
   db 01111111b, 11111111b, 11111111b, 11111110b


section .stack stack
    resb 256
stacktop: