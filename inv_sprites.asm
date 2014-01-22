global shipSprite
global missileSprite
global monster1Sprite
section .data
shipSprite:
db 4, 32
    db 00000000b, 00000001b, 10000000b, 00000000b
    db 00000000b, 00000011b, 11000000b, 00000000b
    db 00000000b, 00000011b, 11000000b, 00000000b
    db 00000000b, 00000111b, 11100000b, 00000000b
    db 00000000b, 00000111b, 11100000b, 00000000b
    db 00000000b, 00000111b, 11100000b, 00000000b
    db 00000000b, 00000110b, 01100000b, 00000000b
    db 00000000b, 00001100b, 00110000b, 00000000b
    db 00000000b, 00001111b, 11110000b, 00000000b
    db 00000000b, 00001100b, 00110000b, 00000000b
    db 00000000b, 00001100b, 00110000b, 00000000b
    db 00000000b, 00011010b, 01011000b, 00000000b
    db 00000000b, 00011010b, 01011000b, 00000000b
    db 00000000b, 00011101b, 10111000b, 00000000b
    db 00000000b, 00011101b, 10111000b, 00000000b
    db 00000000b, 00011110b, 01111000b, 00000000b
    db 00000100b, 00011111b, 11111000b, 00100000b
    db 00001010b, 00011111b, 11111000b, 01010000b
    db 00001110b, 01111111b, 11111110b, 01110000b
    db 00001110b, 11111111b, 11111111b, 01110000b
    db 00001111b, 11111111b, 11111111b, 11110000b
    db 00001110b, 11111111b, 11111111b, 01110000b
    db 00010101b, 11111111b, 11111111b, 10101000b
    db 00110101b, 11111111b, 11111111b, 10101100b
    db 01111011b, 11101111b, 11110111b, 11011110b
    db 11111111b, 11101111b, 11110111b, 11111111b
    db 11111111b, 11101111b, 11110111b, 11111111b
    db 11111111b, 11101111b, 11110111b, 11111111b
    db 11111111b, 11001111b, 11110011b, 11111111b
    db 11111111b, 10110111b, 11101101b, 11111111b
    db 11111111b, 10110111b, 11101101b, 11111111b
    db 00000000b, 01111001b, 10011110b, 00000000b
missileSprite:
db 1, 16
    db 00011000b
    db 00011000b
    db 00111100b
    db 01000010b
    db 00111100b
    db 00110100b
    db 00110100b
    db 00110100b
    db 01111110b
    db 10111101b
    db 10111101b
    db 11111111b
    db 10100101b
    db 00101100b
    db 00010000b
    db 00001000b
monster1Sprite:
db 2, 16
    db 00011000b, 00011000b
    db 00010000b, 00001000b
    db 00111100b, 00111100b
    db 00111111b, 11111100b
    db 01100111b, 11100110b
    db 01100111b, 11100110b
    db 01111110b, 01111110b
    db 00111101b, 10111100b
    db 00111111b, 11111100b
    db 00000111b, 11100000b
    db 00011111b, 11111000b
    db 00010101b, 00101000b
    db 00010101b, 00101000b
    db 00010110b, 10101000b
    db 00010010b, 10101000b
    db 00100010b, 01010000b
