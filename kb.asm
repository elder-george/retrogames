global checkKey
global getKey
global clearKey

section .code

checkKey:
    mov ah, 1
    int 16h
    ret

getKey:
    in al, 60h   
    test al, 80h
    ret

clearKey:   ;Clears keystroke buffer directly ( $0040:$001A := $0040:$001C )
push ds
push es
 mov ax,40h
 mov es,ax
 mov ds,ax
 mov di,1ah
 mov si,1ch
 movsw
pop es
pop ds
ret
