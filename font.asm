global digits
global zero
global one
global two
global three
global four
global five
global six
global seven
global eight
global nine


section data data
digits:
zero:   db 00111100b
        db 01000010b
        db 01000110b
        db 01001010b
        db 01010010b
        db 01100010b
        db 01000010b
        db 00111100b
    
one:    db 00001000b
        db 00011000b
        db 00101000b
        db 00001000b
        db 00001000b
        db 00001000b
        db 00001000b
        db 00011100b

two:    db 00111100b
        db 01000010b
        db 00000010b
        db 00001100b
        db 00010000b
        db 00100000b
        db 01000000b
        db 01111110b

three:  db 00111100b
        db 01000010b
        db 00000100b
        db 00001000b
        db 00000100b
        db 00000010b
        db 01000010b
        db 00111100b

four:   db 00000100b
        db 00001100b
        db 00010100b
        db 00100100b
        db 01000100b
        db 01111110b
        db 00000100b
        db 00001110b

five:   db 01111110b
        db 01000000b
        db 01000000b
        db 01111100b
        db 00000010b
        db 00000010b
        db 01000010b
        db 00111100b

six :   db 00011100b
        db 00100000b
        db 01000000b
        db 01111100b
        db 01000010b
        db 01000010b
        db 01000010b
        db 00111100b

seven:  db 01111110b
        db 01000010b
        db 00000010b
        db 00000100b
        db 00001000b
        db 00111100b
        db 00010000b
        db 00010000b

eight:  db 00111100b
        db 01000010b
        db 01000010b
        db 00111100b
        db 01000010b
        db 01000010b
        db 01000010b
        db 00111100b


nine:   db 00111100b
        db 01000010b
        db 01000010b
        db 01000010b
        db 00111110b
        db 00000010b
        db 00000100b
        db 00111000b
