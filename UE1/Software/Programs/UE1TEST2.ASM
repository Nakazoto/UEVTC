; UE1 Test Program 2
; This shold initialize the CPU, then add 1 to the value in the scratch
; register, before copying the contents of the scratch register to the output
; register. It takes 8 loops of the tape for the full add 1 to happen.
;
; CPU initialization
ONE  SR0            ; Force 1 into RR (Memory address is ignored)
IEN  RR             ; Load input enable register with 1 from RR
OEN  RR             ; Load output enable register with 1 from RR
NAND RR             ; NAND RR with itself to put a 0 in RR
; Round 1
; Add 1 to whatever is in Scratch register
ONE  SR0            ; Force 1 into RR (Memory address is ignored)
STO  SR0            ; Store RR into Scratch Register bit 0
STOC SR7            ; Store inverse RR into Scratch Register bit 7
ADD  SR0            ; Add Scratch Register bit 0 and RR
STO  SR0            ; Store result back in Scratch Register
LD   SR7
ADD  SR1
STO  SR1
LD   SR7
ADD  SR2
STO  SR2
LD   SR7
ADD  SR3
STO  SR3
LD   SR7
ADD  SR4
STO  SR4
LD   SR7
ADD  SR5
STO  SR5
LD   SR7
STO  SR6
; Copy scratch register to output register
LD   SR0
STO  OR0
LD   SR1
STO  OR1
LD   SR2
STO  OR2
LD   SR3
STO  OR3
LD   SR4
STO  OR4
LD   SR5
STO  OR5
LD   SR6
STO  OR6
LD   SR7
STO  OR7
