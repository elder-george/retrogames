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

%include 'common.inc'

MARGIN_X EQU 64
SHIP_W EQU 32
SHIP_H EQU 32
SHIP_X_MIN EQU MARGIN_X
SHIP_X_MAX EQU SCREENW - MARGIN_X - SHIP_W

SHIP_MISSILE_MAX        EQU 5
SHIP_MISSILE_VEL        EQU 2
SHIP_MISSILE_COOLDOWN   EQU 2
UFO_MISSILE_MAX         EQU 5

section .code
start:
    cld
    mov ax, data
    mov ds, ax
    mode13h

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
    mov ax, 4c00h
    int 21h

update:
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
    jmp .next_missile
.move_missile:
    sub ah, SHIP_MISSILE_VEL
    mov [si], ax
    dec cl
.next_missile:
    inc si
    inc si
    ; todo: removed missiles out of screen      
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
    mov cl,[shipMissilesCount]
    mov si,shipMissilesPos
.render_missiles_loop:
    cmp cl, 0
    jle .done
    lodsw
    test ax, ax
    jz .render_missiles_loop    ; skip
    mov bl, ah
    xor ah, ah
    mov bh, ah
    ccall drawMaskBin, 10, missileSprite, ax, bx
    dec cl    
    jmp .render_missiles_loop
.done:
    ret

handleKeys:
    call checkKey
    jz .done
    call getKey
    mov dl, [shipPos.X]
    mov dh, [shipPos.Y]
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
    mov cl, cl
    cmp cl, SHIP_MISSILE_MAX
    jae .done
    mov ah, SHIP_MISSILE_COOLDOWN
    mov [shipMissileCooldown], ah
    ;mov ax, dx
    ;add al, SHIP_W/2
    mov si, shipMissilesPos
.find_free_missile_slot_loop:
    lodsw
    test ax, ax
    jz .make_missile
    dec cl
    jnz .find_free_missile_slot_loop
.make_missile:
    mov ax, dx
    add al, SHIP_W/2
    dec si
    dec si
    mov [si], ax
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
    jne .done
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
    mov [shipPos.X], dl
    ret


section .data
shipPos:
shipPos.X: db SCREENW / 2
shipPos.Y: db SCREENH-SHIP_H

shipMissileCooldown: db 0
shipMissilesCount: db 0
shipMissilesPos:
    dw 0,0,0,0,0,0,0,0,0,0


section stack stack
    resb 256