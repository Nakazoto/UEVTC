; UE1 Test Program 4
; This program should calculate the Fibbonacci sequence.
; 
; CPU initialization
ONE  SR0            ; Force 1 into RR (Memory address is ignored)
IEN  RR             ; Load input enable register with 1 from RR
OEN  RR             ; Load output enable register with 1 from RR
NAND RR             ; NAND RR with itself to put a 0 in RR
; Empty Scratch Register and Output Register
STO  SR0            ; Store a zero in scratch register 0
STO  SR1
STO  SR2
STO  SR3
STO  SR4
STO  SR5
STO  SR6
STO  SR7
STO  OR0            ; Store a zero in output register 0
STO  OR1
STO  OR2
STO  OR3
STO  OR4
STO  OR5
STO  OR6
STO  OR7
; Initialize the two 4-bit operands in the scratch register
; Initialize the output register result
STOC SR0            ; RR has a zero, invert that and store in scratch register
STOC OR0            ; RR has a zero, invert that and store in output register
; Add the two 4-bit operands together and store result in output
ONE  SR0            ; Force 1 into RR and 0 into carry
NAND RR             ; NAND RR with itself to put a 0 in RR
LD   SR0            ; Load OpA bit 0 into RR
ADD  SR4            ; Add OpA bit 0 with OpB bit 0
STO  SR0            ; Store result back into OpA
LD   SR1            ; Repeat for the entire four bit operand
ADD  SR5
STO  SR1
LD   SR2
ADD  SR6
STO  SR2
LD   SR3
ADD  SR7
STO  SR3
LD   SR0
STO  OR0            ; Store the result into the output register
LD   SR1
STO  OR1
LD   SR2
STO  OR2
LD   SR3
STO  OR3
; Add the two 4-bit operands together and store result in output
ONE  SR0            ; Force 1 into RR and 0 into carry
NAND RR             ; NAND RR with itself to put a 0 in RR
LD   SR0            ; Load OpA bit 0 into RR
ADD  SR4            ; Add OpA bit 0 with OpB bit 0
STO  SR4            ; Store result back into OpA
LD   SR1            ; Repeat for the entire four bit operand
ADD  SR5
STO  SR5
LD   SR2
ADD  SR6
STO  SR6
LD   SR3
ADD  SR7
STO  SR7
LD   SR4
STO  OR0            ; Store the result into the output register
LD   SR5
STO  OR1
LD   SR6
STO  OR2
LD   SR7
STO  OR3
; Add the two 4-bit operands together and store result in output
ONE  SR0            ; Force 1 into RR and 0 into carry
NAND RR             ; NAND RR with itself to put a 0 in RR
LD   SR0            ; Load OpA bit 0 into RR
ADD  SR4            ; Add OpA bit 0 with OpB bit 0
STO  SR0            ; Store result back into OpA
LD   SR1            ; Repeat for the entire four bit operand
ADD  SR5
STO  SR1
LD   SR2
ADD  SR6
STO  SR2
LD   SR3
ADD  SR7
STO  SR3
LD   SR0
STO  OR0            ; Store the result into the output register
LD   SR1
STO  OR1
LD   SR2
STO  OR2
LD   SR3
STO  OR3
; Add the two 4-bit operands together and store result in output
ONE  SR0            ; Force 1 into RR and 0 into carry
NAND RR             ; NAND RR with itself to put a 0 in RR
LD   SR0            ; Load OpA bit 0 into RR
ADD  SR4            ; Add OpA bit 0 with OpB bit 0
STO  SR4            ; Store result back into OpA
LD   SR1            ; Repeat for the entire four bit operand
ADD  SR5
STO  SR5
LD   SR2
ADD  SR6
STO  SR6
LD   SR3
ADD  SR7
STO  SR7
LD   SR4
STO  OR0            ; Store the result into the output register
LD   SR5
STO  OR1
LD   SR6
STO  OR2
LD   SR7
STO  OR3
; Add the two 4-bit operands together and store result in output
ONE  SR0            ; Force 1 into RR and 0 into carry
NAND RR             ; NAND RR with itself to put a 0 in RR
LD   SR0            ; Load OpA bit 0 into RR
ADD  SR4            ; Add OpA bit 0 with OpB bit 0
STO  SR0            ; Store result back into OpA
LD   SR1            ; Repeat for the entire four bit operand
ADD  SR5
STO  SR1
LD   SR2
ADD  SR6
STO  SR2
LD   SR3
ADD  SR7
STO  SR3
LD   SR0
STO  OR0            ; Store the result into the output register
LD   SR1
STO  OR1
LD   SR2
STO  OR2
LD   SR3
STO  OR3
; Add the two 4-bit operands together and store result in output
ONE  SR0            ; Force 1 into RR and 0 into carry
NAND RR             ; NAND RR with itself to put a 0 in RR
LD   SR0            ; Load OpA bit 0 into RR
ADD  SR4            ; Add OpA bit 0 with OpB bit 0
STO  SR4            ; Store result back into OpA
LD   SR1            ; Repeat for the entire four bit operand
ADD  SR5
STO  SR5
LD   SR2
ADD  SR6
STO  SR6
LD   SR3
ADD  SR7
STO  SR7
LD   SR4
STO  OR0            ; Store the result into the output register
LD   SR5
STO  OR1
LD   SR6
STO  OR2
LD   SR7
STO  OR3
; Add the two 4-bit operands together and store result in output
ONE  SR0            ; Force 1 into RR and 0 into carry
NAND RR             ; NAND RR with itself to put a 0 in RR
LD   SR0            ; Load OpA bit 0 into RR
ADD  SR4            ; Add OpA bit 0 with OpB bit 0
STO  SR0            ; Store result back into OpA
LD   SR1            ; Repeat for the entire four bit operand
ADD  SR5
STO  SR1
LD   SR2
ADD  SR6
STO  SR2
LD   SR3
ADD  SR7
STO  SR3
LD   SR0
STO  OR0            ; Store the result into the output register
LD   SR1
STO  OR1
LD   SR2
STO  OR2
LD   SR3
STO  OR3
; Add the two 4-bit operands together and store result in output
ONE  SR0            ; Force 1 into RR and 0 into carry
NAND RR             ; NAND RR with itself to put a 0 in RR
LD   SR0            ; Load OpA bit 0 into RR
ADD  SR4            ; Add OpA bit 0 with OpB bit 0
STO  SR4            ; Store result back into OpA
LD   SR1            ; Repeat for the entire four bit operand
ADD  SR5
STO  SR5
LD   SR2
ADD  SR6
STO  SR6
LD   SR3
ADD  SR7
STO  SR7
; Store final carry, update the output register, ring the bell and halt
ADD  RR             ; Add RR with itself to drop carry into it (cheater)
STO  OR4
LD   SR4
STO  OR0            ; Store the result into the output register
LD   SR5
STO  OR1
LD   SR6
STO  OR2
LD   SR7
STO  OR3
IOC  SR0            ; Ring the bell (Memory address is ignored)
NOPF SR0            ; Halt the tape reader (Memory address is ignored)
;