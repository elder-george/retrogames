global checkKey
global getKey

section .code

checkKey:
    mov ah, 1
    int 16h
    ret

getKey:
    in al, 60h   
    ret

