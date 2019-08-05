%include 'timer.inc'
%include 'io.inc'

extern waitKey

global start

section code
start:
    mov ax, data
    mov ds, ax

    log_write "installing handler"
    push handler_desc
    call timer.add_handler
    add sp, 2
    log_write "handler installed"
.wait_key:
    call waitKey
    test al, al
    je .wait_key
    log_write "key pressed, removing handler"
.wait_key2:
    push handler_desc
    call timer.remove_handler
    log_write "handler removed"
    call waitKey
    test al, al
    je .wait_key2
    log_write "key pressed, exiting"
.quit:
    mov ax, 4c00h
    int 21h


handler_impl:
    log_write "in handler!"    
    ret

%macro make_timer_handler 2
%%handler_func:
    pushf
    ; call old handler
    call far [%1+T_HANDLER.old_off]
    ; mark interrupt as handled
    mov al, 20h
    out 20h, al
    call %2
    iret

section data
%1:
istruc T_HANDLER
    at T_HANDLER.old_off,   dw 0addeh
    at T_HANDLER.old_seg,   dw 0efbeh
    at T_HANDLER.func,      dw %%handler_func
    at T_HANDLER.ctx,       dw 0
iend

%endm



make_timer_handler handler_desc, handler_impl


section stack stack
    resb 512