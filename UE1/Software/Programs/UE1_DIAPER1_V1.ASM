;
; UE1 DIAPER 1 - Diagnostic Program for Easy Repair - Algorithmic Tests
;
; Version 1
;
; Authors:
;       Rhys Weatherley
;
; This program tests the algorithmic behaivours of the UE1:  Loads, stores,
; arithmetic, logic, skips, IEN/OEN, and static RAM.
;
; Not tested: Inputs and outputs as they require human intervention to confirm.
; The output register is used to display the test number, but that's it.
;
; It is assumed that your UE1 (real or emulated) is already running simple
; programs such as the "UE1FIBO" example.  Otherwise you won't get very far
; with this test suite.
;
; For each test, the test number is displayed on the output register.
; After each test, the bell will ring once on success.  The program will
; halt with the failing test number on the output registers and no bell if a
; failure occurred.
;
; If all tests succeed, then all outputs are turned on, the bell will ring
; three times, and then the program will halt.
;
;   Test 1    - Check that "NAND RR" works as an inverter.
;   Test 2    - Exhaustive truth table test on "NAND".
;   Test 3    - Exhaustive truth table test on "OR".
;   Test 4-11 - Test each of SR0..SR7 in turn (Test 4 is SR0, Test 11 is SR7).
;   Test 12   - Exhaustive truth table test on "XOR".
;   Test 13   - Exhaustive truth table test on "ADD".
;   Test 14   - Exhaustive truth table test on "SUB".
;   Test 15   - Tests the "SKZ" instruction.
;   Test 16   - Tests the "RTN" instruction.
;   Test 17   - Tests the "OEN" instruction.
;   Test 18   - Tests "IEN" with the "LD" instruction.
;   Test 19   - Tests "IEN" with the "NAND" instruction.
;   Test 20   - Tests "IEN" with the "OR" instruction.
;   Test 21   - Tests "IEN" with the "XOR" instruction.
;   Test 22   - Tests "IEN" with the "ADD" instruction.
;   Test 23   - Tests "IEN" with the "SUB" instruction.
;   Test 24   - Tests "LD RR" in loopback mode.
;
; "NAND" and "OR" are tested before the scratch register because the SR
; tests make heavy use of "NAND" and "OR".  Tests 1 to 3 need SR0, SR6,
; and SR7 to basically work, but the rest of the scratch register is
; ignored until Test 4.
;
; There are no explicit tests for "ONE", which is heavily used in every test.
; If it doesn't work, you have bigger problems to worry about.
;
; The tests below also assume that the "SKZ" will do a skip when RR is 0.
; Most of the skips below are taken, because they skip over a halt for test
; failure.  So a "SKZ" implementation that always skips will work fine
; until Test 15.  Test 15 checks the other cases of skips taken / not taken.
; A "SKZ" instruction that never skips on RR = 0 will fail in Test 1.
;

;
; Initialize the registers: RR = 1, CAR = 0, IEN = 1, OEN = 1
;
; The "ONE" instruction is done twice, just in case the skip register
; is set to 1 when the program starts.  Otherwise we skip the init!
; We will test the skip register properly later.
;
ONE  SR0
ONE  SR0
IEN  RR
OEN  RR
;
; Clear all scratch registers and the output register.  Use "STOC" because
; RR is currently set to 1.  Normally, "NAND RR" can be used to flip RR to 0,
; but we can't trust that "NAND RR" works yet.
;
STOC SR0
STOC SR1
STOC SR2
STOC SR3
STOC SR4
STOC SR5
STOC SR6
STOC SR7
STOC OR0
STOC OR1
STOC OR2
STOC OR3
STOC OR4
STOC OR5
STOC OR6
STOC OR7
;
; Test 1 - Test that "NAND RR" wowrks as a simple inverter.
;
; "NAND RR" is used a lot in the tests below to invert 1 results into a 0
; before a "SKZ", to give the effect of a "SKNZ" instruction.  We definitely
; need "NAND RR" to work even if the rest of "NAND" doesn't.
;
; Instructions that are tested:
;
;       NAND RR
;
; Instructions that are assumed to work for this test, and may cause
; test failure if they don't work:
;
;       ONE, STOC SR0, LD SR0, SKZ, NOPF
;
ONE  SR0        ; Write the test number to the output register (1).
STO  OR0
;
; The code below will indirectly test if "SKZ" actually skips.  The program
; will halt if "NAND" is fine, but "SKZ" is not.  If "SKZ" skips but never
; stops skipping, then the rest of the tape will spool by and no other tests
; will be performed.
;
NAND RR         ; 1 NAND 1 = 0
SKZ  RR         ; Skip if RR is zero.
NOPF SR0
;
STOC SR0        ; Set SR0 to 1.
NAND RR         ; 0 NAND 0 = 1
STOC SR0        ; Set SR0 to 0 if the NAND worked.
NAND RR         ; 1 NAND 1 = 0 (we know that this should work from above).
SKZ  RR         ; Test fails if RR is currently set to 1.
NOPF SR0
LD   SR0        ; Load the result from SR0, which should be 0 on success.
SKZ  RR         ; Test fails if RR is currently set to 1.
NOPF SR0
;
IOC  SR0        ; Test Passed!  Bell!
;
; At this point, we are reasonably sure that "NAND RR" works as an inverter.
;
; Test 2 - Test the entire NAND truth table using RR and SR.
;
; Instructions that are tested:
;
;       NAND
;
; Instructions that are assumed to work for this test, and may cause
; test failure if they don't work:
;
;       NAND RR, ONE, STO SR0, STOC SR0, STO SR6, STOC SR7,
;       LD SR0, LD SR7, SKZ, NOPF
;
ONE  SR0        ; Write the test number to the output register (2).
STOC OR0
STO  OR1
;
STO  SR6        ; Set SR6 to 1.
STOC SR7        ; Set SR7 to 0.
;
NAND SR6        ; Test if 1 NAND 1 = 0.
STO  SR0        ; Shadow the result in SR0.
SKZ  RR
NOPF SR0
LD   SR0        ; Cross-check: SR0 should be zero.
SKZ  RR
NOPF SR0
;
ONE  SR0        ; Test if 1 NAND 0 = 1.
NAND SR7
STOC SR0        ; Shadow the inverse of the result in SR0.
NAND RR
SKZ  RR
NOPF SR0
LD   SR0        ; Cross-check: SR0 should be zero.
SKZ  RR
NOPF SR0
;
LD   SR7        ; Test if 0 NAND 1 = 1.
NAND SR6
STOC SR0        ; Shadow the inverse of the result in SR0.
NAND RR
SKZ  RR
NOPF SR0
LD   SR0        ; Cross-check: SR0 should be zero.
SKZ  RR
NOPF SR0
;
LD   SR7        ; Test if 0 NAND 0 = 1.
NAND SR7
STOC SR0        ; Shadow the inverse of the result in SR0.
NAND RR
SKZ  RR
NOPF SR0
LD   SR0        ; Cross-check: SR0 should be zero.
SKZ  RR
NOPF SR0
;
IOC  SR0        ; Test Passed!  Bell!
;
; Test 3 - Test the entire OR truth table using RR and SR.
;
; Instructions that are tested:
;
;       OR
;
; Instructions that are assumed to work for this test, and may cause
; test failure if they don't work:
;
;       NAND RR, ONE, STO SR0, STOC SR0, STO SR6, STOC SR7,
;       LD SR0, LD SR7, SKZ, NOPF
;
ONE  SR0        ; Write the test number to the output register (3).
STO  OR0
STO  OR1
;
STO  SR6        ; Set SR6 to 1.
STOC SR7        ; Set SR7 to 0.
;
OR   SR6        ; Test if 1 OR 1 = 1.
STOC SR0        ; Shadow the inverse of the result in SR0.
NAND RR
SKZ  RR
NOPF SR0
LD   SR0        ; Cross-check: SR0 should be zero.
SKZ  RR
NOPF SR0
;
ONE  SR0        ; Test if 1 OR 0 = 1.
OR   SR7
STOC SR0        ; Shadow the inverse of the result in SR0.
NAND RR
SKZ  RR
NOPF SR0
LD   SR0        ; Cross-check: SR0 should be zero.
SKZ  RR
NOPF SR0
;
LD   SR7        ; Test if 0 OR 1 = 1.
OR   SR6
STOC SR0        ; Shadow the inverse of the result in SR0.
NAND RR
SKZ  RR
NOPF SR0
LD   SR0        ; Cross-check: SR0 should be zero.
SKZ  RR
NOPF SR0
;
LD   SR7        ; Test if 0 OR 0 = 0.
OR   SR7
STO  SR0        ; Shadow the result in SR0.
SKZ  RR
NOPF SR0
LD   SR0        ; Cross-check: SR0 should be zero.
SKZ  RR
NOPF SR0
;
IOC  SR0        ; Test Passed!  Bell!
;
; Tests 4 to 11 - Test the scratch register bits, one at a time.
;
; Up until now, we have made minimum use of the scratch register.  Now it is
; time to test everything so that we can rely on it for later tests.
;
; For each bit, we do the following:
;
;       1. Set the chosen bit to 1.
;       2. Set all other bits to 0.
;       3. Read all bits back and verify.
;       4. Set the chosen bit to 0.
;       5. Set all other bits to 1.
;       6. Read all bits back and verify.
;
; The test is structured as a kind of "Mini March Test" which should
; hopefully identify stuck bits and address decoding errors.
;
; Instructions that are tested:
;
;       STO, STOC, LD
;
; Instructions that are assumed to work for this test, and may cause
; test failure if they don't work:
;
;       NAND, OR, ONE, SKZ, NOPF
;
; ----- Test SR0 -----
;
ONE  SR0        ; Write the test number to the output register (4).
STO  OR2
STOC OR1
STOC OR0
;
ONE  SR0        ; Set SR0 to 1, all others to 0.
STO  SR0
STOC SR1
STOC SR2
STOC SR3
STOC SR4
STOC SR5
STOC SR6
STOC SR7
;
NAND RR         ; Set RR to zero.
OR   SR1        ; OR SR1..SR7 - result should be zero at the end.
OR   SR2
OR   SR3
OR   SR4
OR   SR5
OR   SR6
OR   SR7
SKZ  RR         ; Fail if RR is non-zero.
NOPF SR0
OR   SR0        ; OR in SR0.  Result should now be 1.
NAND RR
SKZ  RR
NOPF SR0
;
ONE  SR0        ; Set SR0 to 0, all others to 1.
STOC SR0
STO  SR1
STO  SR2
STO  SR3
STO  SR4
STO  SR5
STO  SR6
STO  SR7
;
LD   SR1        ; AND all of SR1..SR7 together.
NAND SR2
NAND RR
NAND SR3
NAND RR
NAND SR4
NAND RR
NAND SR5
NAND RR
NAND SR6
NAND RR
NAND SR7
SKZ  RR         ; RR should be 0 now if all of SR1..SR7 are 1.
NOPF SR0
LD   SR0        ; SR0 itself should still be 0.
SKZ  RR
NOPF SR0
IOC  SR0        ; Test Passed!  Bell!
;
; ----- Test SR1 -----
;
ONE  SR0        ; Write the test number to the output register (5).
STO  OR2
STOC OR1
STO  OR0
;
ONE  SR0        ; Set SR1 to 1, all others to 0.
STOC SR0
STO  SR1
STOC SR2
STOC SR3
STOC SR4
STOC SR5
STOC SR6
STOC SR7
;
NAND RR         ; Set RR to zero.
OR   SR0        ; OR SR0,SR2..SR7 - result should be zero at the end.
OR   SR2
OR   SR3
OR   SR4
OR   SR5
OR   SR6
OR   SR7
SKZ  RR         ; Fail if RR is non-zero.
NOPF SR0
OR   SR1        ; OR in SR1.  Result should now be 1.
NAND RR
SKZ  RR
NOPF SR0
;
ONE  SR0        ; Set SR1 to 0, all others to 1.
STO  SR0
STOC SR1
STO  SR2
STO  SR3
STO  SR4
STO  SR5
STO  SR6
STO  SR7
;
LD   SR0        ; AND all of SR0,SR2..SR7 together.
NAND SR2
NAND RR
NAND SR3
NAND RR
NAND SR4
NAND RR
NAND SR5
NAND RR
NAND SR6
NAND RR
NAND SR7
SKZ  RR         ; RR should be 0 now if all of SR1..SR7 are 1.
NOPF SR0
LD   SR1        ; SR1 itself should still be 0.
SKZ  RR
NOPF SR0
IOC  SR0        ; Test Passed!  Bell!
;
; ----- Test SR2 -----
;
ONE  SR0        ; Write the test number to the output register (6).
STO  OR2
STO  OR1
STOC OR0
;
ONE  SR0        ; Set SR2 to 1, all others to 0.
STOC SR0
STOC SR1
STO  SR2
STOC SR3
STOC SR4
STOC SR5
STOC SR6
STOC SR7
;
NAND RR         ; Set RR to zero.
OR   SR0        ; OR SR0..SR1,SR3..SR7 - result should be zero at the end.
OR   SR1
OR   SR3
OR   SR4
OR   SR5
OR   SR6
OR   SR7
SKZ  RR         ; Fail if RR is non-zero.
NOPF SR0
OR   SR2        ; OR in SR2.  Result should now be 1.
NAND RR
SKZ  RR
NOPF SR0
;
ONE  SR0        ; Set SR2 to 0, all others to 1.
STO  SR0
STO  SR1
STOC SR2
STO  SR3
STO  SR4
STO  SR5
STO  SR6
STO  SR7
;
LD   SR0        ; AND all of SR0..SR1,SR3..SR7 together.
NAND SR1
NAND RR
NAND SR3
NAND RR
NAND SR4
NAND RR
NAND SR5
NAND RR
NAND SR6
NAND RR
NAND SR7
SKZ  RR         ; RR should be 0 now if all of SR0..SR1,SR3..SR7 are 1.
NOPF SR0
LD   SR2        ; SR2 itself should still be 0.
SKZ  RR
NOPF SR0
IOC  SR0        ; Test Passed!  Bell!
;
; ----- Test SR3 -----
;
ONE  SR0        ; Write the test number to the output register (7).
STO  OR2
STO  OR1
STO  OR0
;
ONE  SR0        ; Set SR3 to 1, all others to 0.
STOC SR0
STOC SR1
STOC SR2
STO  SR3
STOC SR4
STOC SR5
STOC SR6
STOC SR7
;
NAND RR         ; Set RR to zero.
OR   SR0        ; OR SR0..SR2,SR4..SR7 - result should be zero at the end.
OR   SR1
OR   SR2
OR   SR4
OR   SR5
OR   SR6
OR   SR7
SKZ  RR         ; Fail if RR is non-zero.
NOPF SR0
OR   SR3        ; OR in SR3.  Result should now be 1.
NAND RR
SKZ  RR
NOPF SR0
;
ONE  SR0        ; Set SR3 to 0, all others to 1.
STO  SR0
STO  SR1
STO  SR2
STOC SR3
STO  SR4
STO  SR5
STO  SR6
STO  SR7
;
LD   SR0        ; AND all of SR0..SR2,SR4..SR7 together.
NAND SR1
NAND RR
NAND SR2
NAND RR
NAND SR4
NAND RR
NAND SR5
NAND RR
NAND SR6
NAND RR
NAND SR7
SKZ  RR         ; RR should be 0 now if all of SR0..SR2,SR4..SR7 are 1.
NOPF SR0
LD   SR3        ; SR3 itself should still be 0.
SKZ  RR
NOPF SR0
IOC  SR0        ; Test Passed!  Bell!
;
; ----- Test SR4 -----
;
ONE  SR0        ; Write the test number to the output register (8).
STO  OR3
STOC OR2
STOC OR1
STOC OR0
;
ONE  SR0        ; Set SR4 to 1, all others to 0.
STOC SR0
STOC SR1
STOC SR2
STOC SR3
STO  SR4
STOC SR5
STOC SR6
STOC SR7
;
NAND RR         ; Set RR to zero.
OR   SR0        ; OR SR0..SR3,SR5..SR7 - result should be zero at the end.
OR   SR1
OR   SR2
OR   SR3
OR   SR5
OR   SR6
OR   SR7
SKZ  RR         ; Fail if RR is non-zero.
NOPF SR0
OR   SR4        ; OR in SR4.  Result should now be 1.
NAND RR
SKZ  RR
NOPF SR0
;
ONE  SR0        ; Set SR4 to 0, all others to 1.
STO  SR0
STO  SR1
STO  SR2
STO  SR3
STOC SR4
STO  SR5
STO  SR6
STO  SR7
;
LD   SR0        ; AND all of SR0..SR3,SR5..SR7 together.
NAND SR1
NAND RR
NAND SR2
NAND RR
NAND SR3
NAND RR
NAND SR5
NAND RR
NAND SR6
NAND RR
NAND SR7
SKZ  RR         ; RR should be 0 now if all of SR0..SR3,SR5..SR7 are 1.
NOPF SR0
LD   SR4        ; SR4 itself should still be 0.
SKZ  RR
NOPF SR0
IOC  SR0        ; Test Passed!  Bell!
;
; ----- Test SR5 -----
;
ONE  SR0        ; Write the test number to the output register (9).
STO  OR3
STOC OR2
STOC OR1
STO  OR0
;
ONE  SR0        ; Set SR5 to 1, all others to 0.
STOC SR0
STOC SR1
STOC SR2
STOC SR3
STOC SR4
STO  SR5
STOC SR6
STOC SR7
;
NAND RR         ; Set RR to zero.
OR   SR0        ; OR SR0..SR4,SR6..SR7 - result should be zero at the end.
OR   SR1
OR   SR2
OR   SR3
OR   SR4
OR   SR6
OR   SR7
SKZ  RR         ; Fail if RR is non-zero.
NOPF SR0
OR   SR5        ; OR in SR5.  Result should now be 1.
NAND RR
SKZ  RR
NOPF SR0
;
ONE  SR0        ; Set SR5 to 0, all others to 1.
STO  SR0
STO  SR1
STO  SR2
STO  SR3
STO  SR4
STOC SR5
STO  SR6
STO  SR7
;
LD   SR0        ; AND all of SR0..SR4,SR6..SR7 together.
NAND SR1
NAND RR
NAND SR2
NAND RR
NAND SR3
NAND RR
NAND SR4
NAND RR
NAND SR6
NAND RR
NAND SR7
SKZ  RR         ; RR should be 0 now if all of SR0..SR4,SR6..SR7 are 1.
NOPF SR0
LD   SR5        ; SR5 itself should still be 0.
SKZ  RR
NOPF SR0
IOC  SR0        ; Test Passed!  Bell!
;
; ----- Test SR6 -----
;
ONE  SR0        ; Write the test number to the output register (10).
STO  OR3
STOC OR2
STO  OR1
STOC OR0
;
ONE  SR0        ; Set SR6 to 1, all others to 0.
STOC SR0
STOC SR1
STOC SR2
STOC SR3
STOC SR4
STOC SR5
STO  SR6
STOC SR7
;
NAND RR         ; Set RR to zero.
OR   SR0        ; OR SR0..SR5,SR7 - result should be zero at the end.
OR   SR1
OR   SR2
OR   SR3
OR   SR4
OR   SR5
OR   SR7
SKZ  RR         ; Fail if RR is non-zero.
NOPF SR0
OR   SR6        ; OR in SR6.  Result should now be 1.
NAND RR
SKZ  RR
NOPF SR0
;
ONE  SR0        ; Set SR6 to 0, all others to 1.
STO  SR0
STO  SR1
STO  SR2
STO  SR3
STO  SR4
STO  SR5
STOC SR6
STO  SR7
;
LD   SR0        ; AND all of SR0..SR5,SR7 together.
NAND SR1
NAND RR
NAND SR2
NAND RR
NAND SR3
NAND RR
NAND SR4
NAND RR
NAND SR5
NAND RR
NAND SR7
SKZ  RR         ; RR should be 0 now if all of SR0..SR5,SR7 are 1.
NOPF SR0
LD   SR6        ; SR6 itself should still be 0.
SKZ  RR
NOPF SR0
IOC  SR0        ; Test Passed!  Bell!
;
; ----- Test SR7 -----
;
ONE  SR0        ; Write the test number to the output register (11).
STO  OR3
STOC OR2
STO  OR1
STO  OR0
;
ONE  SR0        ; Set SR7 to 1, all others to 0.
STOC SR0
STOC SR1
STOC SR2
STOC SR3
STOC SR4
STOC SR5
STOC SR6
STO  SR7
;
NAND RR         ; Set RR to zero.
OR   SR0        ; OR SR0..SR6 - result should be zero at the end.
OR   SR1
OR   SR2
OR   SR3
OR   SR4
OR   SR5
OR   SR6
SKZ  RR         ; Fail if RR is non-zero.
NOPF SR0
OR   SR7        ; OR in SR7.  Result should now be 1.
NAND RR
SKZ  RR
NOPF SR0
;
ONE  SR0        ; Set SR7 to 0, all others to 1.
STO  SR0
STO  SR1
STO  SR2
STO  SR3
STO  SR4
STO  SR5
STO  SR6
STOC SR7
;
LD   SR0        ; AND all of SR0..SR6 together.
NAND SR1
NAND RR
NAND SR2
NAND RR
NAND SR3
NAND RR
NAND SR4
NAND RR
NAND SR5
NAND RR
NAND SR6
SKZ  RR         ; RR should be 0 now if all of SR0..SR6 are 1.
NOPF SR0
LD   SR7        ; SR7 itself should still be 0.
SKZ  RR
NOPF SR0
IOC  SR0        ; Test Passed!  Bell!
;
; Test 12 - Test the entire XOR truth table using RR and SR.
;
; Instructions that are tested:
;
;       XOR
;
; Instructions that are assumed to work for this test, and may cause
; test failure if they don't work:
;
;       NAND RR, ONE, STO SR0, STOC SR0, STO SR6, STOC SR7,
;       LD SR0, LD SR7, SKZ, NOPF
;
ONE  SR0        ; Write the test number to the output register (12).
STOC OR0
STOC OR1
STO  OR2
STO  OR3
;
STO  SR6        ; Set SR6 to 1.
STOC SR7        ; Set SR7 to 0.
;
XOR  SR6        ; Test if 1 XOR 1 = 0.
STO  SR0        ; Shadow the result in SR0.
SKZ  RR
NOPF SR0
LD   SR0        ; Cross-check: SR0 should be zero.
SKZ  RR
NOPF SR0
;
ONE  SR0        ; Test if 1 XOR 0 = 1.
XOR  SR7
STOC SR0        ; Shadow the inverse of the result in SR0.
NAND RR
SKZ  RR
NOPF SR0
LD   SR0        ; Cross-check: SR0 should be zero.
SKZ  RR
NOPF SR0
;
LD   SR7        ; Test if 0 XOR 1 = 1.
XOR  SR6
STOC SR0        ; Shadow the inverse of the result in SR0.
NAND RR
SKZ  RR
NOPF SR0
LD   SR0        ; Cross-check: SR0 should be zero.
SKZ  RR
NOPF SR0
;
LD   SR7        ; Test if 0 XOR 0 = 0.
XOR  SR7
STO  SR3        ; Shadow the result in SR0.
SKZ  RR
NOPF SR0
LD   SR0        ; Cross-check: SR0 should be zero.
SKZ  RR
NOPF SR0
;
IOC  SR0        ; Test Passed!  Bell!
;
; Test 13 - Test the "ADD" instruction.
;
; Instructions that are tested:
;
;       ADD
;
; Instructions that are assumed to work for this test, and may cause
; test failure if they don't work:
;
;       NAND RR, ONE, STO SR6, STOC SR7, LD SR6, SKZ, NOPF
;
ONE  SR0        ; Write the test number to the output register (13).
STO  OR0
STOC OR1
STO  OR2
STO  OR3
;
STO  SR6        ; Set SR6 to 1.
STOC SR7        ; Set SR7 to 0.
;
; 0/1 + 1 = 1/0
;
ADD  RR         ; CAR = 0, RR = 1, 1 + 1 = 2
SKZ  RR         ; Fail the test if RR = 1.
NOPF SR0
;
; 1/0 + 0 = 0/1
;
ADD  SR7        ; CAR = 1, RR = 0.  Add 0 and we should get CAR = 0, RR = 1.
NAND RR         ; Fail the test if RR = 0 now.
SKZ  RR
NOPF SR0
;
; 0/0 + 0 = 0/0
;
ADD  SR7        ; CAR = 0, RR = 0.  Add 0 and we should stay at 0.
SKZ  RR         ; If CAR was 1, then this would cause a test failure.
NOPF SR0
;
; 0/0 + 1 = 0/1
;
ADD  SR6        ; CAR = 0, RR = 0.  Add 1.
NAND RR         ; Fail the test if RR = 0 now.
SKZ  RR
NOPF SR0
;
; 0/0 + 1 = 0/1 (testing that there is no carry from the previous test)
;
ADD  SR6        ; CAR = 0, RR = 0.  Add 1 and we should get 1.
NAND RR         ; If CAR was 1, then this would cause a test failure.
SKZ  RR
NOPF SR0
;
; 1/0 + 1 = 1/0
;
ONE  SR0        ; Set CAR = 1, RR = 0.
ADD  RR
ADD  SR6        ; Add another 1, which should give 2 as the answer.
SKZ  RR
NOPF SR0
;
; 1/0 + 0 = 0/1
;
ADD  SR7
NAND RR
SKZ  RR
NOPF SR0
;
; 1/1 + 0 = 1/0
;
ONE  SR0        ; Set CAR = 1, RR = 1.
ADD  RR
LD   SR6
ADD  SR7        ; Add 0, which should result in 2 as the answer.
SKZ  RR
NOPF SR0
;
; 1/0 + 0 = 0/1
;
ADD  SR7
NAND RR
SKZ  RR
NOPF SR0
;
; 1/1 + 1 = 1/1
;
ONE  SR0        ; Set CAR = 1, RR = 1.
ADD  RR
LD   SR6
ADD  SR6        ; Add 1, which should result in 3 as the answer.
NAND RR
SKZ  RR
NOPF SR0
;
; 1/0 + 0 = 0/1
;
ADD  SR7
NAND RR
SKZ  RR
NOPF SR0
;
; 0/1 + 0 = 0/1
;
ONE  SR0        ; Set CAR = 0, RR = 1.
ADD  SR7        ; Add 0.
NAND RR
SKZ  RR
NOPF SR0
ADD  SR7        ; Check that there was no carry from previous add.
SKZ  RR
NOPF SR0
;
IOC  SR0        ; Test Passed!  Bell!
;
; Test 14 - Test the "SUB" instruction.
;
; Instructions that are tested:
;
;       SUB
;
; Instructions that are assumed to work for this test, and may cause
; test failure if they don't work:
;
;       NAND RR, ONE, ADD, STO SR6, STOC SR7, LD SR6, SKZ, NOPF
;
ONE  SR0        ; Write the test number to the output register (14).
STOC OR0
STO  OR1
STO  OR2
STO  OR3
;
STO  SR6        ; Set SR6 to 1.
STOC SR7        ; Set SR7 to 0.
;
; The "SUB" instruction is counter-intuitive.  0/1 - 1 does not equal 0!
; This is because "CAR" is inverted from its use in "ADD".  "CAR" is
; 1 for "no borrow" and 0 for "borrow", so to get the effect of 1 - 1 = 0
; requires it to be expressed as 1/1 - 1 with "no borrow" in CAR.
;
; First test that 0/1 - 1 = 1 with a borrow:
;
;       0/1 - 1 = 0/1 + ~1 = 0/1 + 0 = 0/1
;
ONE  SR0        ; Set CAR = 0, RR = 1.
SUB  SR6        ; Subtract 1.
NAND RR         ; Check that RR is 1.
SKZ  RR
NOPF SR0
ADD  SR7        ; Shift CAR into RR and check that it is 0.
SKZ  RR
NOPF SR0
;
; Now test the no-borrow case:
;
;       1/1 - 1 = 1/1 + ~1 = 1/1 + 0 = 1/0
;
ONE  RR         ; Set CAR = 1, RR = 1.
ADD  RR
LD   SR6
SUB  RR         ; Subtract 1.
SKZ  RR         ; Check that RR is 0.
NOPF SR0
ADD  SR7        ; Shift CAR into RR and check that it is 1.
NAND RR
SKZ  RR
NOPF SR0
;
; 0/1 - 0 = 0/1 + ~0 = 0/1 + 1 = 1/0
;
ONE  RR         ; Set CAR = 0, RR = 1.
SUB  SR7        ; Subtract 0.
SKZ  RR         ; Check that RR is 0.
NOPF SR0
ADD  SR7        ; Shift CAR into RR and check that it is 1.
NAND RR
SKZ  RR
NOPF SR0
;
; 0/1 - 1 = 0/1 + ~1 = 0/1 + 0 = 0/1
;
ONE  RR         ; Set CAR = 0, RR = 1.
SUB  SR6        ; Subtract 1.
NAND RR         ; Check that RR is 1.
SKZ  RR
NOPF SR0
ADD  SR7        ; Shift CAR into RR and check that it is 0.
SKZ  RR
NOPF SR0
;
; 0/0 - 0 = 0/0 + ~0 = 0/0 + 1 = 0/1
;
ONE  RR         ; Set CAR = 0, RR = 0.
NAND RR
SUB  SR7        ; Subtract 0.
NAND RR         ; Check that RR is 1.
SKZ  RR
NOPF SR0
ADD  SR7        ; Shift CAR into RR and check that it is 0.
SKZ  RR
NOPF SR0
;
; 0/0 - 1 = 0/0 + ~1 = 0/0 + 0 = 0/0
;
ONE  RR         ; Set CAR = 0, RR = 0.
NAND RR
SUB  SR6        ; Subtract 1.
SKZ  RR         ; Check that RR is 0.
NOPF SR0
ADD  SR7        ; Shift CAR into RR and check that it is 0.
SKZ  RR
NOPF SR0
;
; 1/0 - 0 = 1/0 + ~0 = 1/0 + 1 = 1/0
;
ONE  RR         ; Set CAR = 1, RR = 0.
ADD  RR
SUB  SR7        ; Subtract 0.
SKZ  RR         ; Check that RR is 0.
NOPF SR0
ADD  SR7        ; Shift CAR into RR and check that it is 1.
NAND RR
SKZ  RR
NOPF SR0
;
; 1/0 - 1 = 1/0 + ~1 = 1/0 + 0 = 0/1
;
ONE  RR         ; Set CAR = 1, RR = 0.
ADD  RR
SUB  SR6        ; Subtract 1.
NAND RR         ; Check that RR is 1.
SKZ  RR
NOPF SR0
ADD  SR7        ; Shift CAR into RR and check that it is 0.
SKZ  RR
NOPF SR0
;
; 1/1 - 0 = 1/1 + ~0 = 1/1 + 1 = 1/1
;
ONE  RR         ; Set CAR = 1, RR = 1.
ADD  RR
LD   SR6
SUB  SR7        ; Subtract 0.
NAND RR         ; Check that RR is 1.
SKZ  RR
NOPF SR0
ADD  SR7        ; Shift CAR into RR and check that it is 1.
NAND RR
SKZ  RR
NOPF SR0
;
IOC  SR0        ; Test Passed!  Bell!
;
; Test 15 - Test the "SKZ" instruction.
;
; "SKZ" has already been used a lot in the previous tests, but always
; with RR = 0 and the skip taken.  RR = 1 above would cause test failure.
; Now we need to test the cases where the skip is not taken.
;
; Instructions that are tested:
;
;       SKZ
;
; Instructions that are assumed to work for this test, and may cause
; test failure if they don't work:
;
;       NAND RR, ONE, STO, STOC, LD, NOPF
;
ONE  SR0        ; Write the test number to the output register (15).
STO  OR0
STO  OR1
STO  OR2
STO  OR3
;
STO  SR6        ; Set SR6 to 1.
STOC SR7        ; Set SR7 to 0.
;
ONE  RR         ; Set RR to 1.
STO  SR0        ; Set SR0 to 1.
; Note the use of "SKZ SR7".  If the instruction is picking up "DATA"
; instead of "RR" as its input value, then this test will fail.
SKZ  SR7        ; Skip if RR = 0, which will not happen.
STOC SR0        ; Set SR0 to 0.
LD   SR0        ; Test fails if SR0 is still set to 1.
SKZ  RR
NOPF SR0
;
ONE  RR         ; Set RR to 1.
STO  SR1        ; Set SR1 to 1.
NAND RR         ; Set RR to 0.
; Note the use of "SKZ SR6".  If the instruction is picking up "DATA"
; instead of "RR" as its input value, then this test will fail.
SKZ  SR6        ; Skip if RR = 0, which will happen.
STO  SR1        ; Set SR1 to 0.
LD   SR1        ; Test fails if SR1 is set to 0.
NAND RR
SKZ  RR
NOPF SR0
;
IOC  SR0        ; Test Passed!  Bell!
;
; Test 16 - Test "RTN".
;
; Instructions that are tested:
;
;       RTN
;
; Instructions that are assumed to work for this test, and may cause
; test failure if they don't work:
;
;       NAND RR, ONE, STO, STOC, LD, SKZ, NOPF
;
ONE  SR0        ; Write the test number to the output register (16).
STO  OR4
STOC OR3
STOC OR2
STOC OR1
STOC OR0
;
STO  SR6        ; Set SR6 to 1.
STOC SR7        ; Set SR7 to 0.
;
ONE  RR         ; Set RR to 1.
STOC SR2        ; Set SR2 to 0.
RTN  RR         ; "RTN" is an unconditional skip, test with RR = 1.
STO  SR2        ; Set SR2 to 1.
LD   SR2        ; Test fails if SR2 is set to 1.
SKZ  RR
NOPF SR0
;
ONE  RR         ; Set RR to 1.
STOC SR3        ; Set SR3 to 0.
NAND RR
RTN  RR         ; "RTN" is an unconditional skip, test with RR = 0.
STOC SR3        ; Set SR3 to 1.
LD   SR3        ; Test fails if SR3 is set to 1.
SKZ  RR
NOPF SR0
;
IOC  SR0        ; Test Passed!  Bell!
;
; Test 17 - Test "OEN" with the "STO" and "STOC" instructions.
;
; Instructions that are tested:
;
;       OEN, STO, STOC
;
; Instructions that are assumed to work for this test, and may cause
; test failure if they don't work:
;
;       NAND RR, ONE, LD, SKZ, NOPF
;
ONE  SR0        ; Write the test number to the output register (17).
STO  OR0
;
STO  SR6        ; Set SR6 to 1.
STOC SR7        ; Set SR7 to 0.
;
ONE  SR0        ; Set RR to 1.
STO  SR0        ; Store 1 to SR0 - this should work.
STOC SR1        ; Store 0 to SR1 - this should work.
OEN  SR7        ; Turn off OEN.
STOC SR0        ; Store 0 to SR0 - this should not work.
STO  SR1        ; Store 1 to SR1 - this should not work.
LD   SR0        ; Check that SR0 is still 1.
NAND RR
SKZ  RR
NOPF SR0
LD   SR1        ; Check that SR1 is still 0.
SKZ  RR
NOPF SR0
;
OEN  SR6        ; Turn OEN back on again.
ONE  SR0
STOC SR0        ; Store 0 to SR0 - this should work.
STO  SR1        ; Store 1 to SR1 - this should work.
LD   SR0        ; Check that 0 was stored to SR0.
SKZ  RR
NOPF SR0
LD   SR1        ; Check that 1 was stored to SR1.
NAND RR
SKZ  RR
NOPF SR0
;
IOC  SR0        ; Test Passed!  Bell!
;
; Test 18 - Test "IEN" with the "LD" instruction.
;
; Note: There was a common bug in UE1 emulators that "IEN" would cause an
; instruction skip for "LD", "ADD", "SUB", "NAND", "OR", and "XOR" instead
; of forcing the DATA operand to 0.
;
; The actual machine forces DATA to 0.  This test and the following ones
; should catch emulators that don't match the machine.
;
; Instructions that are tested:
;
;       IEN, LD
;
; Instructions that are assumed to work for this test, and may cause
; test failure if they don't work:
;
;       NAND RR, ONE, STO, STOC, LD, SKZ, NOPF
;
ONE  SR0        ; Write the test number to the output register (18).
STO  OR1
STOC OR0
;
STO  SR6        ; Set SR6 to 1.
STOC SR7        ; Set SR7 to 1.
;
STOC SR0        ; Set SR0 to 0.
IEN  SR6        ; Enable IEN via SR6.
LD   SR6        ; Copy SR6 to SR0.
STO  SR0
NAND RR         ; Set RR to 0.
LD   SR0        ; RR should be set to SR0 = 1 if IEN = 1 is working.
NAND RR
SKZ  RR
NOPF SR0
;
ONE  SR0
STO  SR1        ; Set SR1 to 1.
NAND RR
IEN  RR         ; Set IEN to 0.
ONE  SR0        ; Set RR to 1.
LD   SR1        ; This load will fail, setting RR to 0, not 1.
SKZ  RR         ; We expect RR to be 0.
NOPF SR0
;
IEN  SR6        ; Turn IEN on again via SR6.  Should not be affected by IEN = 0.
LD   SR1        ; Now the load should work and set RR to 1.
NAND RR
SKZ  RR
NOPF SR0
;
IOC  SR0        ; Test Passed!  Bell!
;
; Test 19 - Test "IEN" with the "NAND" instruction.
;
; Instructions that are tested:
;
;       IEN, NAND
;
; Instructions that are assumed to work for this test, and may cause
; test failure if they don't work:
;
;       NAND RR, ONE, STO, STOC, LD, SKZ, NOPF
;
ONE  SR0        ; Write the test number to the output register (19).
STO  OR1
STO  OR0
;
STO  SR6        ; Set SR6 to 1.
STOC SR7        ; Set SR7 to 1.
;
STO  SR0        ; Set SR0 to 1.
IEN  SR6        ; Enable IEN via SR6.
NAND SR0        ; 1 NAND 1 should be 0.
SKZ  RR
NOPF SR0
;
IEN  SR7        ; Disable IEN via SR7.
ONE  SR0
NAND SR6        ; Load from SR6 will be forced to 0 by IEN = 0.
IEN  SR6        ; Turn IEN back on so that the next "NAND RR" works.
NAND RR         ; We expect RR to be 1 NAND 0 = 1.
SKZ  RR
NOPF SR0
;
ONE  SR0
NAND SR6        ; 1 NAND 1 should be 0 again.
SKZ  RR
NOPF SR0
;
IOC  SR0        ; Test Passed!  Bell!
;
; Test 20 - Test "IEN" with the "OR" instruction.
;
; Instructions that are tested:
;
;       IEN, OR
;
; Instructions that are assumed to work for this test, and may cause
; test failure if they don't work:
;
;       NAND RR, ONE, STO, STOC, LD, SKZ, NOPF
;
ONE  SR0        ; Write the test number to the output register (20).
STO  OR2
STOC OR1
STOC OR0
;
STO  SR6        ; Set SR6 to 1.
STOC SR7        ; Set SR7 to 1.
;
STO  SR0        ; Set SR0 to 1.
IEN  SR6        ; Enable IEN via SR6.
NAND RR         ; Set RR to 0.
NAND SR0        ; 0 OR 1 should be 1.
NAND RR
SKZ  RR
NOPF SR0
;
ONE  SR0        ; Set RR to 0.
NAND RR
IEN  SR7        ; Disable IEN via SR7.
OR   SR0        ; Load from SR0 will be forced to 0 by IEN = 0.
IEN  SR6        ; Turn IEN back on.
SKZ  RR         ; Check that RR is 0.
NOPF SR0
;
ONE  SR0
NAND RR
OR   SR0        ; 0 OR 1 should be 1 again.
NAND RR
SKZ  RR
NOPF SR0
;
IOC  SR0        ; Test Passed!  Bell!
;
; Test 21 - Test "IEN" with the "XOR" instruction.
;
; Instructions that are tested:
;
;       IEN, XOR
;
; Instructions that are assumed to work for this test, and may cause
; test failure if they don't work:
;
;       NAND RR, ONE, STO, STOC, LD, SKZ, NOPF
;
ONE  SR0        ; Write the test number to the output register (21).
STO  OR2
STOC OR1
STO  OR0
;
STO  SR6        ; Set SR6 to 1.
STOC SR7        ; Set SR7 to 1.
;
STO  SR0        ; Set SR0 to 1.
IEN  SR6        ; Enable IEN via SR6.
NAND SR0        ; 1 XOR 1 should be 0.
SKZ  RR
NOPF SR0
;
ONE  SR0        ; Set RR to 1.
IEN  SR7        ; Disable IEN via SR7.
XOR  SR0        ; Load from SR0 will be forced to 0 by IEN = 0.
IEN  SR6        ; Turn IEN back on.
NAND RR         ; 1 XOR 0 is 1.
SKZ  RR
NOPF SR0
;
ONE  SR0
XOR  SR0        ; 1 XOR 1 should be 0 again.
SKZ  RR
NOPF SR0
;
IOC  SR0        ; Test Passed!  Bell!
;
; Test 22 - Test "IEN" with the "ADD" instruction.
;
; Instructions that are tested:
;
;       IEN, ADD
;
; Instructions that are assumed to work for this test, and may cause
; test failure if they don't work:
;
;       NAND RR, ONE, STO, STOC, LD, SKZ, NOPF
;
ONE  SR0        ; Write the test number to the output register (22).
STO  OR2
STO  OR1
STOC OR0
;
STO  SR6        ; Set SR6 to 1.
STOC SR7        ; Set SR7 to 1.
;
STO  SR0        ; Set SR0 to 1.
IEN  SR6        ; Enable IEN via SR6.
ADD  SR0        ; 0/1 + 1 should be 1/0.
SKZ  RR         ; Check that RR = 0.
NOPF SR0
ADD  SR7        ; Check that CAR = 1.
NAND RR
SKZ  RR
NOPF SR0
;
ONE  SR0        ; Set CAR = 0, RR = 1.
IEN  SR7        ; Disable IEN via SR7.
ADD  SR0        ; Load from SR0 will be forced to 0 by IEN = 0.
IEN  SR6        ; Turn IEN back on.
NAND RR         ; Check that RR = 0 (0/1 + 0 = 0/1).
SKZ  RR
NOPF SR0
ADD  SR7        ; Check that CAR = 0.
SKZ  RR
NOPF SR0
;
ONE  SR0
ADD  SR0        ; 0/1 + 1 should be 1/0 again.
SKZ  RR
NOPF SR0
ADD  SR7        ; Check that CAR = 1.
NAND RR
SKZ  RR
NOPF SR0
;
IOC  SR0        ; Test Passed!  Bell!
;
;
; Test 23 - Test "IEN" with the "SUB" instruction.
;
; Instructions that are tested:
;
;       IEN, SUB
;
; Instructions that are assumed to work for this test, and may cause
; test failure if they don't work:
;
;       NAND RR, ONE, ADD, STO, STOC, LD, SKZ, NOPF
;
ONE  SR0        ; Write the test number to the output register (23).
STO  OR2
STO  OR1
STO  OR0
;
STO  SR6        ; Set SR6 to 1.
STOC SR7        ; Set SR7 to 1.
;
STO  SR0        ; Set SR0 to 1.
IEN  SR6        ; Enable IEN via SR6.
SUB  SR0        ; 0/1 - 1 = 0/1 + ~1 = 0/1 + 0 = 0/1.
NAND RR         ; Check that RR = 1.
SKZ  RR
NOPF SR0
ADD  SR7        ; Move CAR into RR and check that it is 0.
SKZ  RR
NOPF SR0
;
ONE  SR0        ; Set CAR = 0, RR = 1.
IEN  SR7        ; Disable IEN via SR7.
SUB  SR0        ; IEN force to zero; 0/1 - 0 = 0/1 + ~0 = 0/1 + 1 = 1/0.
IEN  SR6        ; Turn IEN back on.
SKZ  RR         ; Check that RR = 0.
NOPF SR0
ADD  SR7        ; Move CAR into RR and check that it is 1.
NAND RR
SKZ  RR
NOPF SR0
;
ONE  SR0
SUB  SR0        ; 0/1 - 1 should be 0/1 again.
NAND RR
SKZ  RR
NOPF SR0
ADD  SR7        ; Move CAR into RR and check that it is 0.
SKZ  RR
NOPF SR0
;
IOC  SR0        ; Test Passed!  Bell!
;
; Test 24 - Test "LD RR" in loopback mode.
;
; Instructions that are tested:
;
;       LD RR
;
; Instructions that are assumed to work for this test, and may cause
; test failure if they don't work:
;
;       NAND RR, ONE, SKZ, NOPF
;
ONE  SR0        ; Write the test number to the output register (23).
STO  OR3
STOC OR2
STOC OR1
STOC OR0
;
ONE  RR         ; Test that loading RR = 1 into itself works.
LD   RR
NAND RR
SKZ  RR
NOPF SR0
;
ONE  RR         ; Test that loading RR = 0 into itself works.
NAND RR
LD   RR
SKZ  RR
NOPF SR0
;
IOC  SR0        ; Test Passed!  Bell!
;
; All tests done.  Light up all outputs on success.
;
ONE  SR0
STO  OR0
STO  OR1
STO  OR2
STO  OR3
STO  OR4
STO  OR5
STO  OR6
STO  OR7
;
; Ring the bell three times and halt.  Add more "NOP0"'s if the bell rings
; merge into each other and sound like one ring.
;
IOC  SR0
NOP0 SR0        ; Use a different data value each time to make sure
NOP0 SR1        ; that all NOP0's are created equal.
NOP0 SR2
NOP0 SR3
NOP0 SR4
NOP0 SR5
NOP0 SR6
NOP0 SR7
IOC  SR0
NOP0 RR
NOP0 IR1
NOP0 IR2
NOP0 IR3
NOP0 IR4
NOP0 IR5
NOP0 IR6
NOP0 IR7
IOC  SR0
NOPF SR0
