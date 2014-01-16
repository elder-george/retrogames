all: breakout.exe invaders.exe

tools/BuildSprites.exe: tools/BuildSprites.cs
	csc -out:$@ $^

inv_sprites.asm: tools/BuildSprites.exe ship.bmp missile.bmp monster1.bmp
	./tools/BuildSprites.exe $(filter %.bmp, $^) >$@
    
inv_sprites.obj:inv_sprites.asm

invaders.exe: invaders.obj vga.obj font.obj kb.obj inv_sprites.obj
	alink -oEXE -entry start $^

breakout.exe: breakout.obj vga.obj font.obj kb.obj
	alink -oEXE -entry start $^

%.obj: %.asm
	nasm -f obj $^

