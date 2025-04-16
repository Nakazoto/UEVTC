Contents:
  - ue14500-emu.c = latest source for the emulator.
  - ue14500-asm.c = source for the assembler.
  - hello.s = assembly language "Hellorld!" program.

New features in the emulator:
  - Direct setting of instruction line values using 0-3, 4-7.
  - Direct setting of data value using D/d.
  - Debug feature using B/b (meant to use from file input to create a breakpoint
    and allow examining the machine state and even modifying it before
    continuing!).
  - Simplified code to make it smaller.

UE14500 assembler:
  - I used your opcodes exactly as-is and fleshed it out with typical syntax for
    comments, labels (unused for now), and directives.
  - Can output in "raw" and "emu" formats for the actual hardware and emulator,
    respectively.
  - Like the emulator, this was designed with the Centurion in mind. It is
    extremely simple and doesn't even allocate any memory, so it reallly should
    be usable on the Centurion some day. It is actually easier to port to the
    Centurion than the emulator.
  - Despite the simplicity, it offers a number of features especially for
    dealing with the emulator including different levels of optimization.

I'll summarize Windows instructions for you here to make it easy, even though
I'm sure you'd figure it out and the code is extensively commented with same.

Build the emulator:

gcc -o ue14500-emu ue14500-emu.c -lpdcurses

Build the assembler:

gcc -o ue14500-asm ue14500-asm.c

Run the emulator in interactive mode to use manually:

./ue14500-emu

Assemble the hello.s program for emulator use, then run it in the emulator:

./ue14500-asm hello.s hello.emu
./ue14500-emu hello.emu out.txt
cat out.txt

Assemble the hello.s program for the actual hardware and do a hex dump to show
what it looks like:

./ue14500-asm -outfmt raw hello.s hello.raw
hexdump -C hello.raw

There are lots of other things to do with the assembler mostly, but also the
emulator's debug feature. Note that inserting a breakpoint can be done either
in the assembler input file or in the emulator file it produces.

