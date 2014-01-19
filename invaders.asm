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

; in inv_sprites.asm
extern shipSprite
extern missileSprite
extern monster1Sprite

%include 'common.inc'

MARGIN_X EQU 64
SHIP_W EQU 32
SHIP_H EQU 32
SHIP_X_MIN EQU MARGIN_X
SHIP_X_MAX EQU SCREENW - MARGIN_X - SHIP_W

SHIP_MISSILE_MAX        EQU 5
SHIP_MISSILE_VEL        EQU 2
SHIP_MISSILE_COOLDOWN   EQU 50
UFO_MISSILE_MAX         EQU 5

MONSTER_H               EQU 16
MONSTER_W               EQU 16
MONSTER_ROWS_MAX        EQU 8
MONSTER_MAX             EQU MONSTER_ROWS_MAX * 8

section .code
start:
    cld
    mov ax, data
    mov ds, ax
    mode13h
    ccall place_monsters, level0monsters

.loop:
    call swapBuffers
    call clearBuffer

    call render
    call update
    call handleKeys
    test al,al
    jz .quit
    

    jmp .loop    
.quit:
    mode03h
    mov ax, 4c00h
    int 21h

place_monsters:
    %stacksize large
    %arg level:word
    enter 0,0
    push es
    push ds
    pop es  ; to use stosw instruction we need [es:di} pair correct.
    mov di, monsterPos  ; preparing to write
    mov si, [level]
    lodsb       ; get number of rows
    mov cl, al
    xor bl, bl  ; count
.rows_loop:
    cmp cl, 0
    jle .done
    dec cl
    lodsb       ; al = Y
    xchg al, ah ; ah = Y
    lodsb       ; al = bitmask
    mov dl, al
    ;xor al, al
    mov al, MARGIN_X
    mov ch, 8
.columns_loop:
    cmp ch, 0
    jle .rows_loop
    dec ch
    add al, 16
    shr dl, 1       ; is left-most bit set?
    jnc .no_monster ; if no, store zero (will be ignored)
    stosw
    inc bl
    jmp .columns_loop
.no_monster:
    push ax
    xor ax,ax
    stosw
    pop ax
    jmp .columns_loop
.done:
    mov [monsterCount], bl
    leave
    ret

update:
    call update_missiles
    call update_monsters
    ret

; instead of moving monsters left and down,
; let's make snake-like movement
update_monsters:
    push ds
    pop es
    mov si, monsterPos
    mov bx, monster_row_direction-1
    mov cl, MONSTER_ROWS_MAX
.rows_loop:
    cmp cl, 0
    jle .done
    dec cl
    inc bx
    mov ch, 8
    xor dl, dl              ; should move row down?
.columns_loop:
    cmp ch, 0
    jle .check_if_need_move_row_down
    dec ch
    mov di,si
    lodsw
    test ax,ax
    jz .columns_loop
    test byte[bx], 11111110b  ; is row odd?
    jz .move_right
.move_left:
    dec al
    cmp al, MARGIN_X
    jae .update_pos
    not byte[bx]
    inc dl
    jmp .update_pos
.move_right:
    inc al
    cmp al, SCREENW - MARGIN_X - MONSTER_W
    jbe .update_pos
    not byte[bx]
    inc dl    
.update_pos:
    mov [di], ax
    jmp .columns_loop
.check_if_need_move_row_down:   ; at this point SI points *after* last item
    test dl, dl                 ; if item in a row hit margin
    jz .rows_loop
    push si
    mov ch, 8                   ; 8 items in a row
    sub si, 8*2                 ; 8 2-byte words in a row
.move_row_down_loop:    ; ideally we should have better data structure.
                        ; but it's easier to just update all items in a row.
    cmp ch, 0
    jle .row_moved_down
    dec ch
    mov di, si
    lodsw
    test ax, ax
    jz .move_row_down_loop
    add ah, 8
    sub al, 4
    stosw
    jmp .move_row_down_loop
.row_moved_down:
    pop si
    jmp .rows_loop
.done:
    mov al, 1
    ret

update_missiles:
    mov cl,[shipMissilesCount]
    mov ch, cl
    mov si,shipMissilesPos
.move_missiles_loop:
    cmp cl, 0
    jle .cool_down
    mov ax, [si]
    test ax, ax
    jz .next_missile
    cmp ah, SCREENH
    jae .destroy_missile
    cmp ah, SHIP_MISSILE_VEL
    jae .move_missile
.destroy_missile:
    xor ax, ax
    mov [si], ax
    dec ch
    dec cl
    jmp .next_missile
.move_missile:
    sub ah, SHIP_MISSILE_VEL
    mov [si], ax
    dec cl
.next_missile:
    inc si
    inc si
    jmp .move_missiles_loop
.cool_down:
    mov [shipMissilesCount], ch
    mov ch,[shipMissileCooldown]
    test ch, ch
    jz .done
    dec ch
    mov [shipMissileCooldown], ch
.done:
    ret

render:
    mov ax, [shipPos]
    mov bl, ah
    xor ah,ah
    xor bh, bh
    ccall drawMaskBin, 10, shipSprite, ax, bx
    ccall render_sprites, word[shipMissilesCount], shipMissilesPos, missileSprite
    ccall render_sprites, word[monsterCount], monsterPos, monster1Sprite
.done:
    ret

render_sprites:
    %stacksize large
    %arg count:byte, positions:word, sprite:word
    enter 0,0
    mov cl, [count]
    mov si, [positions]
.render_loop:
    cmp cl, 0
    jle .done
    lodsw
    test ax, ax
    jz .render_loop    ; skip
    mov bl, ah
    xor ah, ah
    mov bh, ah
    dec cl
    push cx
    push si    
    ccall drawMaskBin, 50, word[sprite], ax, bx
    pop si
    pop cx
    jmp .render_loop
.done:
    leave
    ret

handleKeys:
    mov dx, [shipPos]
.readKey:
    call checkKey
    jz .done
    call getKey
.isEsc:
    cmp al, KEY_ESC
    jne .isSpace
    xor al,al
    jmp .done
.isSpace:
    cmp al, KEY_SPACE
    jne .isLeft
    mov ah, [shipMissileCooldown]
    test ah,ah
    jnz .done
    mov ch, [shipMissilesCount]
    mov cl, SHIP_MISSILE_MAX
    cmp ch, cl    
    jae .done
    mov ah, SHIP_MISSILE_COOLDOWN
    mov [shipMissileCooldown], ah
    mov si, shipMissilesPos
.find_free_missile_slot_loop:
    cmp cl, 0
    jle .done
    lodsw
    test ax, ax
    jz .make_missile
    dec cl
    jmp .find_free_missile_slot_loop
.make_missile:
    mov ax, dx          ; ship (X,Y)
    add al, SHIP_W/2-4  ; missile should go from ship middle)
    dec si              ; moving SI back to the empty slot
    dec si
    mov [si], ax        ; storing missile info
    inc si
    inc si
    inc ch
    mov [shipMissilesCount], ch
    jmp .done
.isLeft:
    cmp al, KEY_LEFT
    jne .isRight
    sub dl, 4
    jmp .clampLeft
.isRight:
    cmp al, KEY_RIGHT
    jne .clampLeft
    add dl, 4
    jmp .clampRight
.clampLeft:
    cmp dl, SHIP_X_MIN
    jae .done
    mov dl, SHIP_X_MIN
    jmp .done
.clampRight:
    cmp dl, SHIP_X_MAX
    jbe .done
    mov dl, SHIP_X_MAX
.done:
    mov [shipPos], dl
    ret


section .data

level0monsters:
    db 2
    db 20, 01010101b
    db 40, 10101010b

shipPos:
shipPos.X: db SCREENW / 2 + 10
shipPos.Y: db SCREENH-SHIP_H

shipMissileCooldown: db 0
shipMissilesCount: db 0
shipMissilesPos: 
    resw SHIP_MISSILE_MAX
monsterCount: db 0
monsterPos: 
    resw MONSTER_ROWS_MAX * 8
monster_row_direction:
    db 0,1,0,1,0,1,0,1

section stack stack
    resb 256