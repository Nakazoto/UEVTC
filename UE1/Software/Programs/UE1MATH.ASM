; UE1 Add or Subtract
; This program should get two six-bit inputs from the user.
; Then it should perform an add or subtract based on the 7th bit.
; 
; 7th bit on = add, off = subtract
; 
; CPU initialization
ONE  SR0            ; Force 1 into RR (Memory address is ignored)
IEN  RR             ; Load input enable register with 1 from RR
OEN  RR             ; Load output enable register with 1 from RR
; We're going to empty the output register, fill it, then empty it again
; This is so the lights look dope when we first run the program
NAND RR             ; NAND RR with itself to put a 0 in RR
STO  OR0            ; Store a zero in output register 0
STO  OR1
STO  OR2
STO  OR3
STO  OR4
STO  OR5
STO  OR6
STO  OR7
; Fill the Output Register
ONE  SR0            ; Force a 1 into the Results Register
STO  OR0            ; Store a zero in output register 0
STO  OR1
STO  OR2
STO  OR3
STO  OR4
STO  OR5
STO  OR6
STO  OR7
; Empty Scratch Register and Output Register
NAND RR             ; NAND RR with itself to put a 0 in RR
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
; Halt and wait for user to input first value.
IOC  SR0            ; Ring the bell (Memory address is ignored)
NOPF SR0            ; Halt the tape reader (Memory address is ignored)
NOP0 SR0            ; We need at least 10 of NOP0s for the tape to spin down 
NOP0 SR0            ; I'm using 16 NOP0s here just to be safe
NOP0 SR0            ; Faster tape speeds need more, slower less
NOP0 SR0            ; This should be good for about 150 ~ 200 Hz
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
; Copy switch value into Scratch Register and Output Register so we know OpA
LD   IR1            ; Start at least significant and work up
STO  SR0            ; Store it into Scratch register
STO  OR0            ; Store it into Output register
LD   IR2            ; Repeat
STO  SR1 
STO  OR1 
LD   IR3 
STO  SR2 
STO  OR2 
LD   IR4 
STO  SR3 
STO  OR3 
LD   IR5 
STO  SR4 
STO  OR4 
LD   IR6 
STO  SR5 
STO  OR5 
; Halt and wait for user to input second value.
IOC  SR0            ; Ring the bell (Memory address is ignored)
NOPF SR0            ; Halt the tape reader (Memory address is ignored)
NOP0 SR0            ; 16x NOP0s for the tape to spin down 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
NOP0 SR0 
; Check if switch is set, if set, run this, if not, skip this
; This is our first conditional branch!!
; This block runs a standard addition
ONE  SR0            ; Force 1 into RR (Memory address is ignored)
OEN  RR             ; Load output enable register with 1 from RR
NAND RR             ; NAND RR with itself to put a 0 in RR
LD   IR7            ; Load in 7th switch value
OEN  RR             ; Use that value to set RR (if 0, then OEN is off)
; Do the add
LD   SR0            ; Load OpA bit 0
ADD  IR1            ; Add with OpB bit 0
STO  OR0            ; Store the result in Output Register bit 0
LD   SR1            ; Repeat
ADD  IR2 
STO  OR1 
LD   SR2 
ADD  IR3 
STO  OR2 
LD   SR3 
ADD  IR4 
STO  OR3 
LD   SR4 
ADD  IR5 
STO  OR4 
LD   SR5 
ADD  IR6 
STO  OR5 
; Drop carry into RR and store
ADD  RR             ; Add RR with itself to drop carry into RR
STO  OR6            ; Store that in the output register
; Check if switch is set, if so, don't run this, if so, do run this
; This is our second conditional branch!!
; This block runs a subtraction
ONE  SR0            ; Force 1 into RR (Memory address is ignored)
OEN  RR             ; Load output enable register with 1 from RR
NAND RR             ; NAND RR with itself to put a 0 in RR
LD   IR7            ; Load in 7th switch value
NAND RR             ; NAND RR with itself to invert it
OEN  RR             ; Use that value to set RR (if 0, then OEN is off)
; Do the subtract
ONE  SR0            ; Force a 1 into RR and a 0 into carry
ADD  RR             ; Add RR with itself to push a 1 into carry and 0 into RR
LD   SR0            ; Load OpA bit 0
SUB  IR1            ; Add with OpB bit 0
STO  OR0            ; Store the result in Output Register bit 0
LD   SR1            ; Repeat
SUB  IR2 
STO  OR1 
LD   SR2 
SUB  IR3 
STO  OR2 
LD   SR3 
SUB  IR4 
STO  OR3 
LD   SR4 
SUB  IR5 
STO  OR4 
LD   SR5 
SUB  IR6 
STO  OR5 
NOPF SR0            ; Halt the tape reader (Memory address is ignored)