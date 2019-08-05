%ifndef io_impl
    %define function extern
%else
    %define function global
%endif


function io.init
function io.getenv

function file.write
function file.nl

function string.cmp.n
function string.skip_to_char


%macro log_write 1
    push 0
    push ds
    push %%msg
    push %%msg.len
    call file.write
    add sp, 8
section data
%%msg db %1, 0dh, 0ah
%%msg.len equ $-%%msg
section code
%endm

%macro static_string 2
    %1 db %2
    %1%+.size equ $-%1
%endmacro

%undef function
