DOS games
=========

This is an experiment on programming small DOS games.

Breakout
--------

Bounce ball with paddle, hit bricks. Destroy all the bricks to go to the next level.

Right now there're only two levels (it's trivial to add more though) 
and collision detection (critical for this kind of games) sucks. Sigh...


Building
--------

You'll need [`nasm`](http://www.nasm.us) and [`alink`](alink.sourceforge.net) 
(or another linker capable of linking 16-bit `.obj` files).

Add them to your `PATH`, then run `make`.

