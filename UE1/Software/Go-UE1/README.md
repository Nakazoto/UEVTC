# UE1 Assembler and Emulator in Go

For those who would rather not fire up DOSBox and QuickBASIC to write and run UE1 software, this is for you!

## Building

`go build` in this directory should be sufficient on any operating system where Go is installable.

## Usage

### ue1 build

`ue1 build <filename>` is the most basic use. Extension can be anything, but the default output is `<filename-without-extension>.bin`. Only the final extension is changed, so `foo.bar.asm` would become `foo.bar.bin`.

If desired, you can pass the `-d` or `--dump` flags to dump the binary to stdout rather than a bin file. This will print the bytes in a human-readable form (ala hexdump), as below:

```
000  40 A8 B8 58 80 81 82 83  84 85 86 87 88 89 8A 8B  |@..X............|
010  8C 8D 8E 8F 90 98 40 58  10 24 80 11 25 81 12 26  |......@X.$..%..&|
020  82 13 27 83 10 88 11 89  12 8A 13 8B 40 58 10 24  |..'.........@X.$|
030  84 11 25 85 12 26 86 13  27 87 14 88 15 89 16 8A  |..%..&..'.......|
040  17 8B 40 58 10 24 80 11  25 81 12 26 82 13 27 83  |..@X.$..%..&..'.|
050  10 88 11 89 12 8A 13 8B  40 58 10 24 84 11 25 85  |........@X.$..%.|
060  12 26 86 13 27 87 14 88  15 89 16 8A 17 8B 40 58  |.&..'.........@X|
070  10 24 80 11 25 81 12 26  82 13 27 83 10 88 11 89  |.$..%..&..'.....|
080  12 8A 13 8B 40 58 10 24  84 11 25 85 12 26 86 13  |....@X.$..%..&..|
090  27 87 14 88 15 89 16 8A  17 8B 40 58 10 24 80 11  |'.........@X.$..|
0A0  25 81 12 26 82 13 27 83  10 88 11 89 12 8A 13 8B  |%..&..'.........|
0B0  40 58 10 24 84 11 25 85  12 26 86 13 27 87 28 8C  |@X.$..%..&..'.(.|
0C0  14 88 15 89 16 8A 17 8B  C0 F0                    |..........|
0CA
```

### ue1 emu

Options are:

```
-a
--asm
	Use provided unassembled assembly file for input.

-n
--non-interactive
	Do not display execution, only show output register (and maybe ring terminal bell).

-s
--speed
	Speed in Hertz. Must be an integer. Default is 60.
```

## Demo

![Fibonacci at 10 Hz](demo/demo.gif)
