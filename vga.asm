global fillRect
global drawMask
global drawMaskBin
global drawChar
global drawDigitString
global swapBuffers
global clearBuffer

extern digits

%include 'common.inc'

section .code

fillRect:
    %stacksize large
    %arg COLOR:word, X:word, Y:word, W:word, H:word
    push bp
    mov bp, sp
    ;mov ax, VMEM
    ;mov es, ax
    coord [X], [Y]
    mov bx, ax
    mov dx, [H]
fillRect_line:
    mov di, ax
    mov cx, [W]
    mov al, [COLOR]
    rep stosb
    dec dx
    test dx, dx
    jz fillRect_end
    mov ax, bx
    add ax, SCREENW
    mov bx, ax
    jmp fillRect_line
fillRect_end:
    mov sp, bp
    pop bp
    ret

drawMask:
    %stacksize large
    %arg COLOR:word, pmask:word,X:word, Y:word

    push bp
    mov bp, sp
    ;mov ax, VMEM
    ;mov es, ax
    coord [X], [Y]
    push ax             ;
    mov si, [pmask]
    mov bx, [si]       ; W
    mov dx, [si+2]     ; H
    add si, 4          ; si = mask_data
.drawMask_line:
    mov di, ax
    mov cx, bx
.next_point:
    lodsb
    test al, al
    jz .skip_point
    mov al, [COLOR]
    ;stosb
    mov [es:di], al
    ;inc di
    ;jmp .dec_x
.skip_point:
    inc di
.dec_x:            
    dec cx
    test cx,cx
    jnz .next_point
.dec_y:
    dec dx
    test dx, dx
    jz .drawMask_end
    pop ax
    add ax, SCREENW
    push ax
    jmp .drawMask_line
.drawMask_end:
    mov sp, bp
    pop bp
    ret

drawDigitString:
    %stacksize large
    %arg COLOR:word, ptr_str:word, X:word, Y:word
    push bp
    mov bp, sp
    mov si, [ptr_str]
    mov bx, [X]
.loop:
    push bx
    xor ax,ax
    lodsb
    test al, al
    jz .done
    sub al, '0'
    shl ax, 3       ; * 8
    add ax, digits

    push si
    mov si, ax
    mov dx, [Y]
    mov ax, [COLOR]
    ccall drawChar, ax, si, bx, dx
    pop si
    pop bx
    add bx, 8
    jmp .loop
.done:
    mov sp, bp
    pop bp
    ret

drawChar:
    %stacksize large
    %arg COLOR:word, pchar:word, X:word, Y:word
    push bp
    mov bp, sp
    ;mov ax, VMEM
    ;mov es, ax
    mov dh, 8
    mov dl, 1
    mov si, [pchar]
    jmp drawMaskBin.compute_LT_coord

drawMaskBin:
    %stacksize large
    %arg COLOR:word, pmask:word,X:word, Y:word

    push bp
    mov bp, sp
    ;mov ax, VMEM
    ;mov es, ax
    mov si, [pmask]
    mov dx, [si]        ; W, H
    add si, 2           ; si = mask_data
.compute_LT_coord:
    coord [X],[Y]
    push ax             ; store for reuse
.drawMask_line:
    mov ch, dl          ; byte number in a row
    mov di, ax
.next_byte:
    mov cl, 8           ; bit number in a byte
    lodsb               
.next_point:
    shl al, 1           ; shift a bit out of byte
    jnc .skip_point     ; if it's 0, skip the point
    push ax             ; if it's 1, let's draw a point
    mov al, [COLOR]
    mov [es:di], al
    pop ax
.skip_point:
    inc di
.dec_x:
    dec cl
    test cl,cl          ; are all bits in a byte checked?
    jnz .next_point     ; if no, continue shifting
    dec ch              ; if yes, let's check if there're bytes in a row
    test ch,ch          ;   is it 0?
    jnz .next_byte      ; if no, load next byte
.dec_y:
    dec dh              ; else go to next row
    test dh, dh         ; is last row?
    jz .drawMask_end    ; if yes, end
    pop ax              ; restore the old pointer
    add ax, SCREENW     ; advance to the next line
    push ax             ; save for next iteration
    jmp .drawMask_line
.drawMask_end:
    pop ax
    mov sp, bp
    pop bp
    ret

swapBuffers:
    push es
    push ds
    mov ax, VBUF
    mov ds, AX
    mov ax, VMEM
    mov es, ax
    xor ax,ax
    mov cx, SCREENW*SCREENH/4
    mov di, ax
    mov si, ax
    rep movsd
    pop ds
    pop es
    ret

clearBuffer:
    mov ax, VBUF
    mov es, ax
    xor ax,ax
    mov di, ax
    mov cx, SCREENW*SCREENH/4
    rep stosd
    ret

section VBUF
    resb SCREENW*SCREENH