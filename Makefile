# for Win-style shell and GNUwin32 make
/:=$(strip \)
# for UNIX-style shell, comment the line above and uncomment the line below - it may work!
#/:=/

all: breakout.exe invaders.exe

tools$/wav2asm.exe: tools$/wav2asm.cs
	csc -nologo -out:$@ $^

tools$/BuildSprites.exe: tools$/BuildSprites.cs
	csc -nologo -out:$@ $^

powerup.asm: tools$/wav2asm.exe assets/powerup.wav
	.$/tools$/wav2asm.exe $(filter %.wav,$^) >$@

explosion.asm: tools$/wav2asm.exe assets/explosion.wav
	.$/tools$/wav2asm.exe $(filter %.wav,$^) >$@

brkout_sprites.asm: tools$/BuildSprites.exe assets/ball.bmp assets/paddle.bmp assets/border.bmp assets/brick.bmp
	.$/tools$/BuildSprites.exe $(filter %.bmp, $^) >$@

inv_sprites.asm: tools$/BuildSprites.exe assets$/ship.bmp assets$/missile.bmp assets$/monster1.bmp
	.$/tools$/BuildSprites.exe $(filter %.bmp, $^) >$@
    
inv_sprites.obj: inv_sprites.asm

invaders.exe: invaders.obj vga.obj font.obj kb.obj sb.obj inv_sprites.obj explosion.obj
	alink -oEXE -entry start $^  >nul

breakout.exe: breakout.obj vga.obj font.obj kb.obj sb.obj brkout_sprites.obj powerup.obj 
	alink -oEXE -entry start $^ >nul

%.obj: %.asm
	nasm -f obj $^

