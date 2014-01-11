%.obj: %.asm
	nasm -f obj $^

breakout: breakout.obj vga.obj font.obj
	alink -oEXE -entry start $^