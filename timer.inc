%ifndef timer_impl
    %define function extern
%else
    %define function global
%endif

struc T_HANDLER
    .old_off resw 1
    .old_seg resw 1
    .func    resw 1
    .ctx     resw 1
endstruc

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


; IN: addr of T_HANDLER struc with `func` set
; OUT: populates `old_seg` and `old_off` fields
function timer.add_handler

; IN: addr of T_HANDLER struc with `old_seg` and `old_off` set.
function timer.remove_handler

