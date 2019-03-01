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


%macro static_string 2
    %1 db %2
    %1%+.size equ $-%1
%endmacro
