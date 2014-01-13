%.obj: %.asm
	nasm -f obj $^

breakout: breakout.obj vga.obj font.obj kb.obj
	alink -oEXE -entry start $^