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

; in kb.asm
extern checkKey
extern getKey

; in font.asm
extern digits

; in brkout_sprites.asm
extern brickSprite
extern paddleSprite
extern ballSprite
extern borderSprite

; in sb.asm
extern sb_init
extern sb_close
extern play_dma

; in powerup.asm
extern powerup_wav


%include 'common.inc'

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
    call sb_init
    call load_level
    mode13h
    call .loop
    call sb_close
    mode03h
    mov ax, 4c00h
    int 21h

.loop:
    call swapBuffers
    call clearBuffer

    call drawBorder
    ccall wordToDec, score_buf, word[score]
    ccall drawDigitString, 5, score_buf, 16, 16
    mov bx, [current_level]
    add bx, 4
    ccall drawBlocks, word[bx-4], word[bx-2], bx
    mov al, [lost]
    test al, al
    jnz .loop        ; do not draw 
    mov al, [level_brick_count]
    cmp al, 0
    jle .next_level
    xor ah, ah
    ccall drawMaskBin,5, paddleSprite, word[paddleCoords.X], word[paddleCoords.Y]
    ccall drawMaskBin,5, ballSprite,   word[ballCoords.X], word[ballCoords.Y]
    call moveBall
    call handleKeys
    test al, al
    jz .quit
    jmp .loop
.next_level:
    inc byte[level_no]
    call load_level
    jmp .loop
.quit:
    ret

load_level:
    mov si, levels
    xor ax,ax
    mov al, byte[level_no]
    add si, ax
    mov bx, [si]
    mov [current_level], bx
    mov ax, [bx+2]
    xchg al, ah
    aad
    ;mov dl, 10
    ;mul dl
    mov cx, ax      ; count of cells (empty and bricks)
    add bx, 4
    mov si, bx
    xor dl, dl
.loop:
    lodsb
    test al,al
    jz .next_cell
    inc dl
    ;jmp .loop
.next_cell:
    dec cx
    jnz .loop
    mov [level_brick_count], dl
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
    ccall drawMaskBin, 5, brickSprite, bx, dx
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
    ccall drawMaskBin, 50, borderSprite, (MARGIN_X - 8), ax
    pop ax
    push ax
    ccall drawMaskBin, 50, borderSprite, (SCREENW - MARGIN_X), ax
    pop ax
    add ax, 8
    cmp ax, SCREENH - 8
    jle .y_loop

    mov ax, (MARGIN_X - 8)
.x_loop:
    push ax
    ccall drawMaskBin, 50, borderSprite, ax, 0
    pop ax
    add ax, 8
    cmp ax, SCREENW - MARGIN_X - 8
    jle .x_loop
.done:
    ret

moveBall:
    %push moveBall_ctx
    %stacksize small
    %assign %$localsize 0
    %local newX:word, newY:word, row:word, column:word
    enter %$localsize,0
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
    mov [newX], dx

.update_ball_Y:
    mov ax,[ballVel.Y]
    mov dx, [ballCoords.Y]
    add dx, ax    ; dx = newY
    mov [newY], dx
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
    cmp ax, 0               ; if we do simple `neg` ball may stuck on paddle.
    jl .save_ball_vel_Y     ; so, let's make sure the ball moves up after bouncing.
    neg ax
.save_ball_vel_Y:
    mov [ballVel.Y], ax
    jmp .save_ball_Y
.check_ball_bottom:
    cmp dx, BALL_Y_BOTTOM
    jle .save_ball_Y
    xor ax,ax
    mov [ballVel.Y], ax
    mov [ballVel.X], ax
    inc ax
    mov [lost], ax
    jmp .save_ball_Y
.check_block_collisions:
    mov [newY], dx
    push dx
    push ax
    mov ax, [ballVel.Y]
    cmp ax, 0
    jle .compute_row    ; if ball moves down,
    add dx, 8           ; then check lower bound
.compute_row:
    shr dx, 3
    mov ax, dx
    mov [row], ax
    mov bx, [current_level]
    mov dx, [bx]    ; read start row
    inc dx          ; skip border
    cmp al, dl      ; start row
    jl .collisions_handled
    sub ax, dx
    mov dx, [bx+2]  ; add number of rows
    cmp al, dl      ; is below the lowest row?
    jge .collisions_handled ; if yes, skip
.potential_collision:
    add bx, 4
    mov si, bx  ; si = start of level
    mov dl, (SCREENW - 2*MARGIN_X)/16
    mul dl
    add si, ax      ; si = row
    mov ax, [ballCoords.X]
    mov dx, [ballVel.X]
    cmp dx, 0
    jle .compute_column
    add ax, 8
.compute_column:
    sub ax, MARGIN_X
    shr ax, 4       ; / 16
    mov [column], ax
    add si, ax      ; si points to brick
    mov al, [si]
    cmp al, 0
    jle .collisions_handled
    dec al
    mov [si], al
    test al, al
    jne .decide_what_side_collided
    inc word[score]
    dec byte[level_brick_count]
    mov bx, powerup_wav
    mov ax, [bx]
    inc bx
    inc bx
    ccall play_dma, bx, ax
.decide_what_side_collided:
    mov ax, [newY]
    add ax, 4       ; center of ball
    shr ax, 3       ; div 8
    cmp ax, [row]
    jg .change_vel_y
.change_vel_x:
    mov ax, [ballVel.X]
    neg ax
    push ax
    mov [ballVel.X], ax
    jmp .collisions_handled
.change_vel_y:
    pop ax
    neg ax
    push ax
    mov [ballVel.Y], ax
.collisions_handled:
    pop ax
    pop dx
.save_ball_Y:
.apply_changes:
    mov dx, [newX]
    mov [ballCoords.X], dx
    mov dx, [newY]
    mov [ballCoords.Y], dx
    leave
    ret
    %pop

handleKeys:
    call checkKey
    jz .done
    call getKey
.isEsc:
    cmp al, KEY_ESC
    jne .isLeft
    xor al,al
    jmp .done
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

section data data
paddleCoords:
paddleCoords.X: dw 100
paddleCoords.Y: dw 200-8 

ballCoords:
ballCoords.X:   dw 116
ballCoords.Y:   dw 200-16

ballVel:
ballVel.X:  dw 2
ballVel.Y:  dw -3

current_level:
    dw  0
level_brick_count:
    db 0                ;we have 160x192 field with 16x8 bricks; that gives 240 bricks max.
lost:           db 0
level_no:       db 0

score:
    dw 0

score_buf:
    db '0','0','0',00,0,0,0,0,0,0

levels:
    dw level0, level1

level0:
    dw 2, 4
    db 1,1,1,1,1,1,1,1,1,1
    db 1,1,1,1,1,1,1,1,1,1
    db 1,1,1,1,1,1,1,1,1,1
    db 1,1,1,1,1,1,1,1,1,1

level1:
    dw 0, 7
    db 1,0,0,0,0,0,0,0,0,0
    db 1,1,0,0,0,0,0,0,0,0
    db 1,1,1,0,0,0,0,0,0,0
    db 1,1,1,1,0,0,0,0,0,0
    db 1,1,1,1,1,0,0,0,0,0
    db 1,1,1,1,1,1,0,0,0,0
    db 1,1,1,1,1,1,1,0,0,0


section .stack stack
    resb 256
stacktop: