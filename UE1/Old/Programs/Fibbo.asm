;Initialize
NOPO 	00
IEN 	72
OEN		72

LD		47	;Load 0o47 into RR
STOC	47	;Store complement back into 0o57
OEN		47	;If 0o47 is 1, skip next instructions

;These are skipped if 0o57 is 1
ONE		00	;Store 1 in RR
STO 	00	;Store 1 in 0o00 to get fibbo started
STO 	10	;Store 1 in 0o10 to get fibbo started
STO		47	;Store 1　in 0o47 so this only gets run once

;Restore bitmask
OEN		72	;Turn OEN on again
ONE		00	;Force 1 into RR and 0 into carry

;Start Fibbo
;Add two eight bit numbers together
LD		00	;Load 0o00 into RR
ADD		10	;Add with 0o10
STO		50	;Store into 0o50 (shift out register)
LD		01
ADD		11
STO		51
LD		02
ADD		12
STO		52
LD		03
ADD		13
STO		53
LD		04
ADD		14
STO		54
LD		05
ADD		15
STO		55
LD		06
ADD		16
STO		56
LD		07
ADD		17
STO		57

;Copy 0o50 ~ 0o57 into 0o00 ~ 0o07
LD		50	;Load 0o50 into RR (shift out register)
STO 	00  ;Store into 0o00
LD		51
STO 	01
LD		52
STO 	02
LD		53
STO 	03
LD		54
STO 	04
LD		55
STO 	05
LD		56
STO 	06
LD		57
STO 	07

;Shift result out
IOC		76	;Memory address 0o76 plus IOC operation from processor start I/O

;Add two eight bit numbers together
LD		00
ADD		10
STO		50
LD		01
ADD		11
STO		51
LD		02
ADD		12
STO		52
LD		03
ADD		13
STO		53
LD		04
ADD		14
STO		54
LD		05
ADD		15
STO		55
LD		06
ADD		16
STO		56
LD		07
ADD		17
STO		57

;Copy 0o50 ~ 0o57 into 0o10 ~ 0o17
LD		50
STO 	10
LD		51
STO 	11
LD		52
STO 	12
LD		53
STO 	13
LD		54
STO 	14
LD		55
STO 	15
LD		56
STO 	16
LD		57
STO 	17

;Shift result out
IOC		76	;Memory address 0o76 plus IOC operation from processor start I/O

