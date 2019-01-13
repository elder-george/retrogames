global start

; in vga.asm
extern fillRect
extern drawMask
extern drawMaskBin
extern drawChar
extern drawDigitString
extern swapBuffers
extern clearBuffer

; in kb.asm
extern checkKey
extern getKey
extern clearKey

; in font.asm
extern digits

; in tet_sprites.asm
extern borderSprite
extern ballSprite

%include 'common.inc'

; size of tile
%define TILES.BITS 3
%define TILE.SZ	(1<<TILES.BITS)
; size of screen in tiles
%define TILES.HOR (SCREENW/TILE.SZ) ; 40?
%define TILES.VER (SCREENH/TILE.SZ) ; 25?
; "Glass" dimensions
%define GLASS.W 10
%define GLASS.H	20
%define GLASS.X (TILES.HOR/2 - GLASS.W/2)
%define GLASS.Y ((TILES.VER - GLASS.H) / 2)

%define BORDER.W 1
; sanity check that the "glass" fits the screen
%if (GLASS.W + 2*BORDER.W > TILES.HOR)
%error "Glass is too wide"
%endif
%if (GLASS.H + BORDER.W > TILES.VER)
%error "Glass is too high"
%endif

%define PIECE.SZ 4		; each piece is represented with 4x4 item
%define BORDER.COLOR 50

section code
start:
    cld
    mov ax, data
    mov ds, ax
    mode13h
    call init_clock

    ;call intro			; show some nice intro here
    call play_tetris	; return final score in AX register
	; todo: some kind of "outro"/"continue" screen/halloffame/...
.quit:
    mode03h
    mov ax, 4c00h
    int 21h

intro:
	; nothing here, move along
	ret

play_tetris:
	; mock data
	mov al, 0
	mov [piece.kind], al
	mov al, 0
	mov [piece.rot], al
	mov al, GLASS.X+GLASS.W/2
	mov [piece.x], al
	mov al, GLASS.Y
	mov [piece.y], al

.loop:
    call swapBuffers
    call clearBuffer

	call draw_glass_border
	call draw_glass_contents
	call draw_current_piece
	call update
	jmp .loop
	ret

draw_glass_border:
	;xor di, di
.vertical_borders:
	mov cx, GLASS.H		; Number of tiles to draw
	mov bx, GLASS.X*TILE.SZ ; X
	mov dx, GLASS.Y*TILE.SZ   ; Y
.vert_loop:
	push bx	; we'll need the "left" value twice, so preserving it here	
	; draw left border
	ccall drawMaskBin, BORDER.COLOR, borderSprite, bx, dx

	; ... now draw right border
	add bx, (GLASS.W*TILE.SZ) ; don't need to save, 'cause it's throwaway
	ccall drawMaskBin, BORDER.COLOR, borderSprite, bx, dx
	add dx, TILE.SZ

	pop bx ; restoring bx for the next iteration

	dec cx
	jne .vert_loop	

.bottom_border:
	mov bx, word (GLASS.X*TILE.SZ)
	mov dx, (GLASS.Y+GLASS.H)*TILE.SZ
	mov cx, GLASS.W+1
.hor_loop:
	ccall drawMaskBin, BORDER.COLOR, borderSprite, bx, dx
	add bx, TILE.SZ
	dec cx
	jne .hor_loop	

	ret

draw_glass_contents:
	ret

draw_current_piece:
	push bp
	mov bp, sp

	movzx bx, byte[piece.kind]
	shl bx, TILES.BITS	; each of 4 piece variant is 2bytes, so *8
	movzx si, byte[piece.rot]
	shl si, 1		; and each item is 2 bytes, so *2
	mov ax, [pieces+bx+si]
	; now draw row-by-row, bottom-up
	mov cx, PIECE.SZ      ; for (i = PIECE.SZ; i > 0; i--)
	movzx dx, [piece.y]
	add dx, cx
	shl dx, TILES.BITS	; screenY = (piece.y+i)*TILE.SZ (assuming it's 8)
.rows:
	mov si, PIECE.SZ		; for (j = PIECE.SZ; j > 0; j--)

    movzx bx, [piece.x]
    add bx, si
    shl bx, TILES.BITS 	; screenX = (piece.x+j)*TILE.SZ (assuming it's 8)
.cols:
	test ax, 01h
	jz .next_col		; only draw if a bit is set.
	ccall drawMaskBin, 30, ballSprite, bx, dx
.next_col:
	shr ax, 1
	sub bx, TILE.SZ
	dec si
	jne .cols

.next_row:
	sub dx, TILE.SZ
	dec cx
	jne .rows
	
	leave
	ret

init_clock:
	mov si, last_update
	xor ah, ah
	int 1ah
	mov [si], dx
	inc si
	inc si
	mov [si], cx
	ret

%define TICKS_BETWEEN_UPDATES 3
should_update:
	push cx
	push dx
	push si
	xor ax, ax
	int 1ah
	; save timestamp, in case we need to store it
	push cx            
	push dx
	;jmp .it_is_time
	; read lower part of previous timestamp
	mov si, last_update
	mov ax, [si]
	sub dx, ax

	; Using only lower part of timestamp is risky (see infamous Borland's bug).
	; still will do that for simplicity sake.
	;;mov ax, [si]
	;;sbb cx, dx
	;;jc .wait_more	; should never happen

	jnc .no_borrow
	neg dx
.no_borrow:
	cmp dx, TICKS_BETWEEN_UPDATES
	jl .wait_more

.it_is_time:
	pop dx
	pop cx
	mov [si], dx
	inc si
	inc si
	mov [si], cx
	xor ax, ax
	not ax
	or ax, ax
	jmp .quit
.wait_more:
	add sp, 4	; discard stored dx and cx
	xor ax, ax
.quit:
	pop si
	pop dx
	pop cx
	ret

%define CMD_NONE   0
%define CMD_LEFT   1
%define CMD_RIGHT  2
%define CMD_ROTATE 3
%define CMD_DROP   4

handleKeys:
	mov si, cmd
	call checkKey
	jz .done
	call getKey
	cmp al, KEY_LEFT
	jne .notLeft
	mov byte[si], CMD_LEFT
	ret
.notLeft:
	cmp al, KEY_RIGHT
	jne .notRight
	mov byte[si], CMD_RIGHT
	ret
.notRight:
	cmp al, KEY_UP
	jne .notRotate
	mov byte[si], CMD_ROTATE
	ret
.notRotate:
	cmp al, KEY_DOWN
	jne .done
	mov byte [si], CMD_DROP
.done:
	ret

movePiece:
	ret

update:
	call handleKeys
	call clearKey
.check_timer:
	call should_update
	jz .quit
	mov al, byte [cmd]
	cmp al, CMD_LEFT
	je .moveLeft
	cmp al, CMD_RIGHT
	je .moveRight
	cmp al, CMD_ROTATE
	je .rotate
	cmp al, CMD_DROP
	je .rotate		;; TODO: implement drop logic
	jmp .doUpdate
.moveLeft:
	ccall movePiece, -1, 0
.moveRight:
	ccall movePiece, -1, 0
.rotate:
	mov al, [piece.rot]
	inc al
	and al, 011b	; there're only 4 rotations
	mov [piece.rot], al
	jmp .doUpdate
.changePiece:
	mov al, [piece.kind]
	inc al
	cmp al, 6	; there're only 6 tetraminos
	jle .set_piece
	xor al, al
.set_piece:
	mov [piece.kind], al
.doUpdate:
	ccall movePiece, 0, 1
	xor al, al
	mov [cmd], al
.quit:
	ret
;
; Rotation is one of hardest parts.
; If rotating a single tile(X,Y), where X,Y in [-N,..-1,1,..N] clock-wise:
; e.g. 
;	(-2,-2)  becomes (-2,2)
;   	....     x...
; 		....  -> ....
;		....     ....
;		x...     ....
;	(-1,1) becomes (1,-1)
;		....    ....
;		.x.. -> ....
;		....    ..x.
;		....    ....
;   (2, 1) becomes (1,-2)
;   	....    ....
;   	...x -> ....
;   	....    ....
;   	....    ..x.
; In other words, if we imagine that a tile is a vector v=(X,Y) = (l*cos(a), l*sin(a)),
; then a rotation is adding 90 deg angle to a, i.e. 
; 	v'=(X',Y')=(l*cos(90+a), l*sin(90+a))=(l*(-sin(a)), l*cos(a))=(-Y, X)
; Now, this uses "right" Descartes coordinates (Y axis pointed up), rather the computer one.
; So, we'll need to negate the Y when drawing.

section data
; the tetramino "pieces" 
%define aPiece(nib0, nib1, nib2, nib3) dw nib0 %+ nib1 %+ nib2 %+ nib3 %+ b
; Then again, we do represent each tetramino with just two bytes, 
; so maybe let's just hardcode each state?
pieces:
	; #0 - "I"
	aPiece (0000,\
       		1111,\
       		0000,\
       		0000)
    aPiece (0010,\
   			0010,\
   			0010,\
   			0010)
	aPiece (0000,\
       		1111,\
       		0000,\
       		0000)
    aPiece (0010,\
   			0010,\
   			0010,\
   			0010)

   	; #1 - "r"
	aPiece (0000,\
   			1110,\
   			0010,\
   			0000)
	aPiece (0010,\
   			0010,\
   			0110,\
   			0000)
	aPiece (0000,\
   			1000,\
   			1110,\
   			0000)
	aPiece (0110,\
   			0100,\
   			0100,\
   			0000)

   	; #2 - "L"
	aPiece (0000,\
   			0111,\
   			0100,\
   			0000)
    aPiece (0110,\
   			0010,\
   			0010,\
   			0000)
	aPiece (0000,\
   			0010,\
   			1110,\
   			0000)
	aPiece (0100,\
   			0100,\
   			0110,\
   			0000)
   	; #3 - "square"
	aPiece (0000,\
   			0110,\
   			0110,\
   			0000)
    aPiece (0000,\
 			0110,\
 			0110,\
 			0000)
    aPiece (0000,\
 			0110,\
 			0110,\
 			0000)
    aPiece (0000,\
 			0110,\
 			0110,\
 			0000)
	; #4 - "T"
	aPiece (0000,\
   			0111,\
   			0010,\
 			0000)
	aPiece (0010,\
   			0110,\
   			0010,\
 			0000)
	aPiece (0010,\
   			0111,\
   			0000,\
 			0000)
	aPiece (0010,\
   			0011,\
   			0010,\
 			0000)
	; #5 - "z"
	aPiece (0000,\
   			0110,\
   			0011,\
   			0000)
	aPiece (0001,\
   			0011,\
   			0010,\
   			0000)
	aPiece (0000,\
   			0110,\
   			0011,\
   			0000)
	aPiece (0001,\
   			0011,\
   			0010,\
   			0000)
	; #6 - "s"
	aPiece (0000,\
   			0011,\
   			0110,\
   			0000)
	aPiece (0100,\
   			0110,\
   			0010,\
   			0000)
	aPiece (0000,\
   			0011,\
   			0110,\
   			0000)
	aPiece (0100,\
   			0110,\
   			0010,\
   			0000)



score resw 1

piece:
	.x 		resb 1
	.y 		resb 1
	.kind 	resb 1 ; 0..6
	.rot	resb 1 ; 0..4

last_update:
	dw 0, 0

cmd db 0

section stack stack
	resb 256