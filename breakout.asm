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

%macro dbg_num 1
;    ccall fillRect, 0, 16, 16, 100, 16
    ccall wordToDec, score_buf, %1
    ccall drawDigitString, 5, score_buf, 16, 32
    call swapBuffers
    xor dx, dx
    div dx
%endm

section .code
start:
    cld
    mov ax, data
    mov ds, ax
    mov word [current_level], level0
    mode13h


.loop:
    call swapBuffers
    call clearBuffer

    call drawBorder
    mov bx, [current_level]
    add bx, 4
    ccall drawBlocks, word[bx-4], word[bx-2], bx
    ccall drawMaskBin,5, paddleBin, word[paddleCoords.X], word[paddleCoords.Y]
    ccall drawMaskBin,5, ballBin,   word[ballCoords.X], word[ballCoords.Y]
    ccall wordToDec, score_buf, word[score]
    ccall drawDigitString, 5, score_buf, 16, 16
    call moveBall
    call handleKeys
    jmp .loop
    ret

drawBlocks:
    %stacksize large
    %arg startRow:word, height:word, level:word
    enter 0,0
    mov dx, [startRow]
    inc dx              ; skip top border
    shl dx, 3           ; * 8
    mov si, [level]
    mov cx, [height]
.y_loop:
    mov bx, MARGIN_X
.x_loop:
    lodsb
    cmp al, 0
    jle .update_vars   
    push dx
    push si
    push cx
    push bx
    ccall drawMaskBin, 5, brick, bx, dx
    pop bx
    pop cx
    pop si
    pop dx
.update_vars:
    add bx, 16
    cmp bx, BALL_X_MAX
    jl .x_loop
    add dx, 8
    dec cx
    cmp cx, 0
    jg .y_loop
.done:
    leave
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
    jl .check_block_collisions
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
    jle .check_block_collisions
    xor ax,ax
    mov [ballVel.Y], ax
    mov [ballVel.X], ax
    jmp .save_ball_Y
.check_block_collisions:
    push dx
    push ax
    mov ax, dx
    shr ax, 3
    mov bx, [current_level]
    mov dx, [bx]
    inc dx          ; skip border
    cmp al, dl      ; start row
    jl .collisions_handled
    sub ax, dx
    mov dx, [bx+2]  ; add number of rows
    cmp al, dl
    jge .collisions_handled
.potential_collision:
    add bx, 4
    mov si, bx
    mov dl, (SCREENW - 2*MARGIN_X)/16
    mul dl
    add si, ax      ; si = row
    mov ax, [ballCoords.X]
    sub ax, MARGIN_X
    shr ax, 4
    xor ah, ah
    add si, ax      ; si points to brick
    mov al, [si]
    cmp al, 0
    jle .collisions_handled
    dec al
    mov [si], al
    pop ax
    neg ax
    push ax
    mov [ballVel.Y], ax
.collisions_handled:
    pop ax
    pop dx
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
    sub word [paddleCoords.X], 4
.isRight:
    cmp al, KEY_RIGHT
    jne .clampLeft
    add word [paddleCoords.X], 4
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

current_level:
    dw  0

score:
    dw 0

score_buf:
    db '0','0','0',00,0,0,0,0,0,0

%include 'sprites.inc'

level0:
    dw 2, 4
    db 1,1,1,1,1,1,1,1,1,1
    db 1,1,1,1,1,1,1,1,1,1
    db 1,1,1,1,1,1,1,1,1,1
    db 1,1,1,1,1,1,1,1,1,1


section .stack stack
    resb 256
stacktop: