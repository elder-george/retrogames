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

MARGIN_X    EQU 80
MARGIN_TOP  EQU 10
MARGIN_BTM  EQU 0

PADDLE_X_MIN EQU MARGIN_X
PADDLE_X_MAX EQU SCREENW-MARGIN_X-32

BALL_X_MIN  EQU MARGIN_X
BALL_X_MAX  EQU SCREENW-MARGIN_X-8
BALL_Y_MIN  EQU MARGIN_TOP
BALL_Y_PADDLE   EQU SCREENH-MARGIN_BTM-16
BALL_Y_BOTTOM   EQU SCREENH-MARGIN_BTM-8

section .code
start:
    cld
    mov ax, data
    mov ds, ax

    mode13h

.loop:
    call swapBuffers
    call clearBuffer

    call drawBorder
    ccall drawMaskBin,5, paddleBin, word[paddleCoords.X], word[paddleCoords.Y]
    ccall drawMaskBin,5, ballBin,   word[ballCoords.X], word[ballCoords.Y]
    ccall wordToDec, buf, word[score]
    ccall drawDigitString, 5, buf, 16, 16
    call moveBall
    call handleKeys
    jmp .loop
    ret

drawBorder:
    xor ax,ax
.y_loop:
    push ax
    ccall drawMaskBin, 50, borderVert, (MARGIN_X - 8), ax
    pop ax
    push ax
    ccall drawMaskBin, 50, borderVert, (SCREENW - MARGIN_X), ax
    pop ax
    add ax, 8
    cmp ax, SCREENH - 8
    jle .y_loop

    mov ax, (MARGIN_X - 8)
.x_loop:
    push ax
    ccall drawMaskBin, 50, borderVert, ax, 0
    pop ax
    add ax, 8
    cmp ax, SCREENW - MARGIN_X - 8
    jle .x_loop
.done:
    ret

moveBall:
.change_ball_X:
;    xor ax,ax 
    mov ax,[ballVel.X]
    mov dx, [ballCoords.X]
    add dx, ax
.check_ball_left:
    cmp dx, BALL_X_MIN
    jge .check_ball_right
    mov dx, BALL_X_MIN
    neg ax
    mov [ballVel.X], ax
.check_ball_right:
    cmp dx, BALL_X_MAX
    jle .save_ball_X
    mov dx, BALL_X_MAX
    neg ax
    mov [ballVel.X], ax
.save_ball_X:
    mov [ballCoords.X], dx

.update_ball_Y:
;    xor ax, ax
    mov ax,[ballVel.Y]
    mov dx, [ballCoords.Y]
    add dx, ax
.check_ball_top:
    cmp dx, BALL_Y_MIN
    jge .check_ball_paddle
    mov dx, BALL_Y_MIN
    neg ax
    mov [ballVel.Y], ax
    jmp .save_ball_Y
.check_ball_paddle:
    cmp dx, BALL_Y_PADDLE
    jl .save_ball_Y
    mov bx, [ballCoords.X]
    sub bx, [paddleCoords.X]
    cmp bx, -8
    jle .check_ball_bottom
    cmp bx, 32
    jge .check_ball_bottom
.hit_paddle:
    mov dx, BALL_Y_PADDLE
    neg ax
    mov [ballVel.Y], ax
    jmp .save_ball_Y
.check_ball_bottom:
    cmp dx, BALL_Y_BOTTOM
    jge .save_ball_Y
    xor ax,ax
    mov [ballVel.Y], ax
    mov [ballVel.X], ax
    ret
.save_ball_Y:
    mov [ballCoords.Y], dx
    ret

handleKeys:
    call checkKey
    jz .done
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
    ret

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

wordToDec:
    mov bp, sp
    mov ax, [bp+4]  
    mov bx, [bp+2]
    mov cx, 10
    mov di, 5
.loop:
    xor dx,dx
    div cx
    xchg ax,dx
    add al, '0'
    mov [bx+di], al
    xchg ax,dx
    dec di
    jnz .loop
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

            dw 0

ballVel:
ballVel.X:  dw 2
ballVel.Y:  dw -3

            dw 0

score:
    dw 0

buf:
    db '0','0','0',00,0,0,0,0,0,0

; sprites
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

borderVert:
    db 1, 8
    db 11111111b
    db 11111111b
    db 01111110b
    db 01111110b
    db 01111110b
    db 01111110b
    db 11111111b
    db 11111111b


section .stack stack
    resb 256
stacktop: