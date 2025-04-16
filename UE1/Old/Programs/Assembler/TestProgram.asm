; UE1 Test Program
; This shold initialize the CPU, fill the scratch register with X'FF', fill the 
; output register with X'FF', empty the scratch register to X'00', empty the 
; output register to X'00', then halt.
;
; CPU initialization
ONE  SR0            ; Force 1 into RR (Memory address is ignored)
IEN  RR             ; Load input enable register with 1 from RR
OEN  RR             ; Load output enable register with 1 from RR
NAND RR             ; NAND RR with itself to put a 0 in RR
; Round 1
; Fill scratch register with X'FF'
ONE  SR0            ; Force 1 into RR (Memory address is ignored)
STO  SR0            ; Store RR into Scratch Register bit 0
STO  SR1            ; Store RR into Scratch Register bit 1
STO  SR2            ; Store RR into Scratch Register bit 2
STO  SR3            ; Store RR into Scratch Register bit 3
STO  SR4            ; Store RR into Scratch Register bit 4
STO  SR5            ; Store RR into Scratch Register bit 5
STO  SR6            ; Store RR into Scratch Register bit 6
STO  SR7            ; Store RR into Scratch Register bit 7
; Fill output register with X'FF'
STO  OR0            ; Store RR into Output Register bit 0
STO  OR1            ; Store RR into Output Register bit 1
STO  OR2            ; Store RR into Output Register bit 2
STO  OR3            ; Store RR into Output Register bit 3
STO  OR4            ; Store RR into Output Register bit 4
STO  OR5            ; Store RR into Output Register bit 5
STO  OR6            ; Store RR into Output Register bit 6
STO  OR7            ; Store RR into Output Register bit 7
; Empty the scratch register to X'00'
STOC SR0            ; Store /RR into Scratch Register bit 0
STOC SR1            ; Store /RR into Scratch Register bit 1
STOC SR2            ; Store /RR into Scratch Register bit 2
STOC SR3            ; Store /RR into Scratch Register bit 3
STOC SR4            ; Store /RR into Scratch Register bit 4
STOC SR5            ; Store /RR into Scratch Register bit 5
STOC SR6            ; Store /RR into Scratch Register bit 6
STOC SR7            ; Store /RR into Scratch Register bit 7
; Empty the output register to X'00'
STOC OR0            ; Store /RR into Output Register bit 0
STOC OR1            ; Store /RR into Output Register bit 1
STOC OR2            ; Store /RR into Output Register bit 2
STOC OR3            ; Store /RR into Output Register bit 3
STOC OR4            ; Store /RR into Output Register bit 4
STOC OR5            ; Store /RR into Output Register bit 5
STOC OR6            ; Store /RR into Output Register bit 6
STOC OR7            ; Store /RR into Output Register bit 7
; Round 2
; Fill scratch register with X'FF'
ONE  SR0            ; Force 1 into RR (Memory address is ignored)
STO  SR0            ; Store RR into Scratch Register bit 0
STO  SR1            ; Store RR into Scratch Register bit 1
STO  SR2            ; Store RR into Scratch Register bit 2
STO  SR3            ; Store RR into Scratch Register bit 3
STO  SR4            ; Store RR into Scratch Register bit 4
STO  SR5            ; Store RR into Scratch Register bit 5
STO  SR6            ; Store RR into Scratch Register bit 6
STO  SR7            ; Store RR into Scratch Register bit 7
; Fill output register with X'FF'
STO  OR0            ; Store RR into Output Register bit 0
STO  OR1            ; Store RR into Output Register bit 1
STO  OR2            ; Store RR into Output Register bit 2
STO  OR3            ; Store RR into Output Register bit 3
STO  OR4            ; Store RR into Output Register bit 4
STO  OR5            ; Store RR into Output Register bit 5
STO  OR6            ; Store RR into Output Register bit 6
STO  OR7            ; Store RR into Output Register bit 7
; Empty the scratch register to X'00'
STOC SR0            ; Store /RR into Scratch Register bit 0
STOC SR1            ; Store /RR into Scratch Register bit 1
STOC SR2            ; Store /RR into Scratch Register bit 2
STOC SR3            ; Store /RR into Scratch Register bit 3
STOC SR4            ; Store /RR into Scratch Register bit 4
STOC SR5            ; Store /RR into Scratch Register bit 5
STOC SR6            ; Store /RR into Scratch Register bit 6
STOC SR7            ; Store /RR into Scratch Register bit 7
; Empty the output register to X'00'
STOC OR0            ; Store /RR into Output Register bit 0
STOC OR1            ; Store /RR into Output Register bit 1
STOC OR2            ; Store /RR into Output Register bit 2
STOC OR3            ; Store /RR into Output Register bit 3
STOC OR4            ; Store /RR into Output Register bit 4
STOC OR5            ; Store /RR into Output Register bit 5
STOC OR6            ; Store /RR into Output Register bit 6
STOC OR7            ; Store /RR into Output Register bit 7
; Round 3
; Fill scratch register with X'FF'
ONE  SR0            ; Force 1 into RR (Memory address is ignored)
STO  SR0            ; Store RR into Scratch Register bit 0
STO  SR1            ; Store RR into Scratch Register bit 1
STO  SR2            ; Store RR into Scratch Register bit 2
STO  SR3            ; Store RR into Scratch Register bit 3
STO  SR4            ; Store RR into Scratch Register bit 4
STO  SR5            ; Store RR into Scratch Register bit 5
STO  SR6            ; Store RR into Scratch Register bit 6
STO  SR7            ; Store RR into Scratch Register bit 7
; Fill output register with X'FF'
STO  OR0            ; Store RR into Output Register bit 0
STO  OR1            ; Store RR into Output Register bit 1
STO  OR2            ; Store RR into Output Register bit 2
STO  OR3            ; Store RR into Output Register bit 3
STO  OR4            ; Store RR into Output Register bit 4
STO  OR5            ; Store RR into Output Register bit 5
STO  OR6            ; Store RR into Output Register bit 6
STO  OR7            ; Store RR into Output Register bit 7
; Empty the scratch register to X'00'
STOC SR0            ; Store /RR into Scratch Register bit 0
STOC SR1            ; Store /RR into Scratch Register bit 1
STOC SR2            ; Store /RR into Scratch Register bit 2
STOC SR3            ; Store /RR into Scratch Register bit 3
STOC SR4            ; Store /RR into Scratch Register bit 4
STOC SR5            ; Store /RR into Scratch Register bit 5
STOC SR6            ; Store /RR into Scratch Register bit 6
STOC SR7            ; Store /RR into Scratch Register bit 7
; Empty the output register to X'00'
STOC OR0            ; Store /RR into Output Register bit 0
STOC OR1            ; Store /RR into Output Register bit 1
STOC OR2            ; Store /RR into Output Register bit 2
STOC OR3            ; Store /RR into Output Register bit 3
STOC OR4            ; Store /RR into Output Register bit 4
STOC OR5            ; Store /RR into Output Register bit 5
STOC OR6            ; Store /RR into Output Register bit 6
STOC OR7            ; Store /RR into Output Register bit 7
; Halt (In triplicate just to be sure)
NOPF SR0            ; Halt the tape reader (Memory address is ignored)
NOPF SR0            ; Halt the tape reader (Memory address is ignored)
NOPF SR0            ; Halt the tape reader (Memory address is ignored)