;
; UE1 DIAPER 2 - Diagnostic Program for Easy Repair - Input/Output Tests
;
; Version 1
;
; Authors:
;       Rhys Weatherley
;
; This program tests the 7 inputs and 8 outputs of the UE1.  It requires
; human intervention while the test is running.
;
; This program loops reading the state of IR1 to IR7 and copying them to
; OR1 to OR7.  OR0 is set to the even parity calculated over IR1 to IR7.
;
; This program is very short.  If punching to paper tape, I recommend
; duplicating it multiple times.
;
ONE  SR0        ; Initialize the machine.
IEN  RR
OEN  RR
;
LD   IR1        ; Process bit 1.
STO  OR1
STO  SR0        ; SR0 keeps the running even parity total.
;
LD   IR2        ; Process bit 2.
STO  OR2
XOR  SR0
STO  SR0
;
LD   IR3        ; Process bit 3.
STO  OR3
XOR  SR0
STO  SR0
;
LD   IR4        ; Process bit 4.
STO  OR4
XOR  SR0
STO  SR0
;
LD   IR5        ; Process bit 5.
STO  OR5
XOR  SR0
STO  SR0
;
LD   IR6        ; Process bit 6.
STO  OR6
XOR  SR0
STO  SR0
;
LD   IR7        ; Process bit 7.
STO  OR7
XOR  SR0
;
STO  OR0        ; Write the calculated even parity to OR0.
