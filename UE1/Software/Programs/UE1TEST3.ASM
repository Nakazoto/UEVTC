; UE1 Test Program 3
; This program should load whatever value is on the input switches, and copy it
; as is to the scratch register, and then copy the inverse to the output
; regsiter.
; 
; CPU initialization
ONE  SR0            ; Force 1 into RR (Memory address is ignored)
IEN  RR             ; Load input enable register with 1 from RR
OEN  RR             ; Load output enable register with 1 from RR
NAND RR             ; NAND RR with itself to put a 0 in RR
; Round 1
; Add 1 to whatever is in Scratch register
LD   IR1            ; Load value from input register 1
STO  SR1            ; Store that value into scratch register 1
STOC OR1            ; Store inverse value into output register 1
LD   IR2            ; Repeat for the remaining bits
STO  SR2
STOC OR2
LD   IR3
STO  SR3
STOC OR3
LD   IR4
STO  SR4
STOC OR4
LD   IR5
STO  SR5
STOC OR5
LD   IR6
STO  SR6
STOC OR6
LD   IR7
STO  SR7
STOC OR7
