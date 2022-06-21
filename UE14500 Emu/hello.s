.outfmt emu     ; Output in emulator format.
.delay 20       ; Delay of 20 = 10 Hz with .fixedlen = inst.
.init 1111001101; Initialize the UE14500 in the worst configuration.

; Hellorld! for the UE14500.
;
; To assemble: ue14500-asm hello.s hello.emu
;
; To emulate: ue14500-emu hello.emu out.txt
; The resulting out.txt contains the results of the program.

; Emulator options.
.fixedlen inst ; Generate fixed-length output, instructions only.
.comments on   ; Copy comments to output.
.quit on       ; Quit the emulator after running.

; Set the data line to 1 so we can do IEN 1 to initialize. We will not change
; any data after this.
.data 1

; Initialize the CPU. This is the generic initialization to ensure a known CPU
; state in any possible case, which is not really needed fully for this program.
	IEN ; Do input enable twice since the first may be skipped if the CPU
	IEN ; booted with the skip flag high.
	OEN ; Output enable on.
	ONE ; 1 -> RR, 0 -> Carry.
	XOR ; 1^1 (0) -> RR.
.emu b

; 'H' = 0x48 = 01001000
	STO
	STO
	STO
	STOC
	STO
	STO
	STOC
	STO

; 'e' = 0x65 = 01100101
	STOC
	STO
	STOC
	STO
	STO
	STOC
	STOC
	STO

; 'l' = 0x6c = 01101100
	STO
	STO
	STOC
	STOC
	STO
	STOC
	STOC
	STO

; 'l' = 0x6c = 01101100
	STO
	STO
	STOC
	STOC
	STO
	STOC
	STOC
	STO

; 'o' = 0x6f = 01101111
	STOC
	STOC
	STOC
	STOC
	STO
	STOC
	STOC
	STO

; 'r' = 0x72 = 01110010
	STO
	STOC
	STO
	STO
	STOC
	STOC
	STOC
	STO

; 'l' = 0x6c = 01101100
	STO
	STO
	STOC
	STOC
	STO
	STOC
	STOC
	STO

; 'd' = 0x64 = 01100100
	STO
	STO
	STOC
	STO
	STO
	STOC
	STOC
	STO

; '!' = 0x21 = 00100001
	STOC
	STO
	STO
	STO
	STO
	STOC
	STO
	STO

; '\n' = 0x0a = 00001010
	STO
	STOC
	STO
	STOC
	STO
	STO
	STO
	STO

