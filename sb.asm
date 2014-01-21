global sb_init
global sb_close
global play_dma

%include 'common.inc'

BASE_PORT               EQU 220h
DSP_RESET               EQU BASE_PORT+6
DSP_READ                EQU BASE_PORT+0ah
DSP_WRITE_DATA_OR_CMD   EQU BASE_PORT+0Ch
DSP_WRITE_BUFFER_STATUS EQU BASE_PORT+0Ch   ; bit 7 r/o
DSP_DATAAVAIL           EQU BASE_PORT+0Eh   ; bit 7 r/o

VMEM2 EQU 0b800h


%macro die 1
    push VMEM2
    pop es
    mov byte[es:0], %1
    xor dx, dx
    div dx
%endm

%macro set_int_handler 2
;%push ctx
    push ds
    xor ax,ax
    mov ds, ax
    mov bx, ax
    mov ax, %1
    shl ax, 2       ; * 4
    add bx, ax
    mov ax, %2
    mov [bx], ax
    mov ax, cs
    mov [bx+2], ax
    pop ds
;%pop
%endm


section .code
sb_init:
    call reset_dsp
    test al, al
    jz .done

    ccall write_command, 0d1h       ; turn speaker on

    set_int_handler 0fh, data_played

.done:
    ret

sb_close:
    ccall write_command, 0d3h       ; turn speaker off
    ret

data_played:
    mov dx, 22eh
    in al, dx
    mov al, 20h
    out 20h, al
    iret

play_dma:
    %stacksize large
    %arg buffer:word, size:word
    enter 0,0
    mov al, 4+1
    out 0ah, al  ; disable DMA channel
    out 0ch, al     ; clear byte pointer flip-flop
    mov al, 48h + 1
    out 0bh, al; 'single-cycle playback' mode

    mov ax, ds
    shl ax, 4
    add ax, [buffer]    ; linear address of buffer
    mov bx, ax
    mov al, bl
    out 02h, al
    mov al, bh     
    out 02h, al     ; address of buffer

    mov cx, [size]
    shr cx, 1
    dec cx
    mov al, cl
    out 03h, al     ; low byte of (size-1)
    mov al, ch      
    out 03h, al     ; high byte of (size-1)

    xor al, al
    out 83h, al     ; page 0

    mov al, 1       ; enable DMA
    out 0ah, al
    ccall write_command, 40h        ; timing constant
    ccall write_command, (256 - (1000000/22050))

    ccall write_command, 0c0h       ; 8 bit single-cycle output
    ccall write_command, 0              ; mono, unsigned
    mov ax, [size]
    dec ax
    xor cx, cx
    mov cl, al
    ccall write_command, cx
    mov ax, [size]
    shr ax, 1
    dec ax
    xor cx, cx
    mov cl, ah
    ccall write_command, cx
    leave
    ret

play_direct:
    %stacksize large
    %arg buffer:word, size:word
    enter 0,0
    mov cx, [size]
    mov si, [buffer]
    xor ax,ax
.loop:
    ccall write_command, 010h
    lodsb
    ccall write_command, ax
    push cx
    mov cx, 64
.delay:
    nop
    loop .delay
    pop cx
    loop .loop
    leave
    ret

write_command:
    %stacksize large
    %arg cmd:byte
    enter 0,0
    mov dx, DSP_WRITE_BUFFER_STATUS
.wait_readiness:
    in al, dx
    test al, al
    jns .wait_readiness
    mov al, [cmd]
    out dx, al
    leave
    ret

reset_dsp:
    mov al, 01
    mov dx, DSP_RESET
    out dx, al
    mov cx, 1024
.delay1:
    nop                 ; sleep 3 ms - need to try different delays
    loop .delay1
    xor al, al
    mov dx, DSP_RESET
    out dx, al
.wait_reset:
    mov dx, DSP_DATAAVAIL
    in al, dx
    test al, al
    jns .wait_reset
    mov dx, DSP_READ
.wait_AA:
    in al, dx
    cmp al, 0aah
    jne .wait_AA
    mov al, 1
    ret
.no_dsp:
    xor al,al
    ret
    

section .data

section stack stack 
    resw 256