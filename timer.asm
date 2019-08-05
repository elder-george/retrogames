%define timer_impl
%include 'timer.inc'

section code

%define GET_VECT 35h
%define SET_VECT 25h

%define TIMER_INT 08h

timer.add_handler:
    %define .HANDLER 4
    cli
    push bp
    mov bp, sp
    ; get old handler
    mov ah, GET_VECT
    mov al, TIMER_INT
    int 21h
    ; ES:BX -> old handler;
    mov ax, bx
    mov di, [bp+.HANDLER]
    mov [di+T_HANDLER.old_off], ax
    mov ax, es
    mov [di+T_HANDLER.old_seg], ax

    ; DS:DX -> new handler
    mov dx, [di+T_HANDLER.func]
    push ds
    mov ax, cs
    mov ds, ax
    mov ah, SET_VECT
    mov al, TIMER_INT
    int 21h
    pop ds

.exit:
    sti
    mov sp, bp
    pop bp
    ret

timer.remove_handler:
    %define .HANDLER 4
    cli
    push bp
    mov bp, sp
    mov di, [bp+.HANDLER]

    push ds
    lds dx, [di]
    mov ah, SET_VECT
    mov al, TIMER_INT
    int 21h
    pop ds

.exit:
    sti
    mov sp, bp
    pop bp
    ret

section data
