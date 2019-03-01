%define io_impl 1
%include 'io.inc'

GET_PSP_SEG equ 62h

PSP.CMD_TAIL      equ 81h
PSP.CMD_TAIL.LEN  equ 80h
PSP.ENV           equ 2ch

section code

io.init:
    cld
    call io.getpsp
    mov word[seg.psp], bx
    mov es, bx
    mov bx, [es:PSP.ENV]
    mov word[seg.env], bx
    ret

; returns BX=seg(PSP)
io.getpsp:
    mov ah, GET_PSP_SEG
    int 21h
    ret

; OUT: ZF=1 if found, ES:DI -> value, CX=length
io.getenv:
KEY.LEN equ 4
KEY     equ 6
    push bp
    mov bp, sp
    push es
    mov ax, word[seg.env]
    mov es, ax
    xor dx, dx
.loop:
    mov di, dx

    mov al, '='
    call string.skip_to_char
    ; ES:DX->&ENTRY[0] ES:DI -> '='
    mov cx, di
    sub cx, dx
    dec cx  ; CX = LEN
    cmp cx, [bp+KEY.LEN]
    jne .skip_value

    push di
    mov di, dx
    mov si, [bp+KEY]
    call string.cmp.n
    pop di
    je .measure_length

.skip_value:
    mov al, 0
    call string.skip_to_char
    ; dx -> start, di -> end
    mov dx, di
    mov al, [es:di]
    test al, al
    jnz .loop
    inc al    ; clear zero flag
    jmp .done

.measure_length:
    mov dx, di
    mov al, 0
    call string.skip_to_char
    mov cx, di
    sub cx, dx
    dec cx
    mov di, dx
    test al, al ; set ZF
    jmp .done
.done:
    pop es
    mov sp, bp
    pop bp
    ret
    
; in: DS:SI -> s1; ES:DI -> s2; CX = LEN
string.cmp.n:
    repe cmpsb
    ret

string.skip_to_char:
.loop:
    scasb
    jne .loop
    ret

file.write:
.HANDLE  equ 10
.BUF_SEG equ 8
.BUF     equ 6
.CNT     equ 4
    push bp
    mov bp, sp
    push bx
    push cx
    push dx

    mov bx, [bp+.HANDLE]
    mov cx, [bp+.CNT]
    mov dx, [bp+.BUF]
    mov ax, [bp+.BUF_SEG]
    push ds
    mov ds, ax
    mov ah, 40h
    int 21h
    pop ds
    
    pop dx
    pop cx
    pop bx

    mov sp, bp
    pop bp
    ret

file.nl:
.HANDLE  equ 4
   push bp
   mov bp, sp
   push word[bp+.HANDLE]
   push cs
   push .newline
   push .newline.size
   call file.write
   mov sp, bp
   pop bp
   ret
static_string .newline, `\r\n`

section data
    seg.psp resw 1
    seg.env resw 1
