REM File access stuff
DIM path AS STRING
DIM file AS STRING
DIM flin AS STRING

REM Opcode and key input stuff
DIM inpc AS STRING
DIM inky AS STRING
DIM inkt AS INTEGER
DIM opco AS STRING
DIM mema AS STRING
DIM comm AS STRING
DIM speed AS SINGLE

REM Flags
DIM flago AS INTEGER
DIM flagf AS INTEGER
DIM wrt AS INTEGER
DIM skz AS INTEGER
DIM ioc AS INTEGER
DIM rtn AS INTEGER

REM Registers
DIM carry AS INTEGER
DIM rr AS INTEGER
DIM ienrg AS INTEGER
DIM oenrg AS INTEGER
DIM outrg AS INTEGER
DIM sctrg AS INTEGER
DIM inprg AS INTEGER

REM Temporary holding cells
DIM tprr AS INTEGER
DIM tpdb AS INTEGER
DIM tpreg AS INTEGER
DIM trgt1 AS INTEGER
DIM trgt2 AS INTEGER
DIM tpbit AS INTEGER
DIM inloc AS INTEGER
DIM inbit AS INTEGER
DIM tsbit AS INTEGER

REM Opening menu
restart:
CLS
PRINT "UE1 Emulator"
PRINT "This UE1 Emulator requires an assembly program to run."
PRINT ""
PRINT "How to use:"
PRINT "The program will run on a loop until 'ESC' is pressed to quit."
PRINT "Press 'H' to halt the CPU. A Flag F instruction will also halt."
PRINT "If the CPU is halted, press any key to resume."
PRINT "Press 'A' or 'D' to select the desired input switch bit."
PRINT "Press 'W' to toggle that bit from 0 to 1 or 1 to 0."
PRINT ""
INPUT "What is the program file path (ex.: c:\ueasm): ", path
INPUT "What is the program file name (excluding extension): ", file
INPUT "What is the clock speed in Hz: ", speed
IF speed = 0 THEN speed = 10
speed = 1 / speed

ON ERROR GOTO badfile
IF RIGHT$(path, 1) <> "\" THEN path = path + "\"
flin = path + file + ".asm"
OPEN flin FOR INPUT AS #1

REM Draw the initial screen
CLS
PRINT "INSTRUCTION   : "
PRINT "MEMORY ADDRESS: "
PRINT "--------------------"
PRINT ""
PRINT "REGISTERS"
PRINT "CARRY     = "
PRINT "RESULTS   = "
PRINT "INPUT EN  = "
PRINT "OUTPUT EN = "
PRINT "SCRATCH   = "
PRINT "OUTPUT    = "
PRINT "INPUT SW. = "
PRINT ""
PRINT "FLAGS"
PRINT "FLAG 0    = "
PRINT "WRITE     = "
PRINT "I/O CON   = "
PRINT "RETURN    = "
PRINT "SKIP Z    = "
PRINT ""
PRINT "PROCESSOR IS RUNNING"
PRINT ""
inloc = 13
LOCATE 13, inloc, 0
PRINT "^"

REM Primary loop
letsgo:
DO
    REM Check if a key has been pressed
    inky = INKEY$
    IF inky = CHR$(27) THEN GOTO goodbye
    IF inky = CHR$(104) OR flagf = 1 THEN GOSUB halted
    IF inky = CHR$(97) OR inky = CHR$(100) OR inky = CHR$(119) THEN GOSUB toggle
   
    REM Skip this instruction if last instruction was SKZ and RR = 0
    IF skz <> 0 AND rr = 0 THEN
        skz = 0
        GOTO nextline
    END IF
    REM Skip this instruction if last instruction was RTN
    IF rtn <> 0 THEN
        rtn = 0
        GOTO nextline
    END IF
    
    REM Read in next opcode and memory address
    LINE INPUT #1, inpc
    writ = 0
    opco = LEFT$(inpc, 4)
    mema = MID$(inpc, 6, 3)
    comm = LEFT$(inpc, 1)
    IF comm = ";" THEN GOTO skipcomm

    REM Reset Flags
    flago = 0
    flagf = 0
    wrt = 0
    ioc = 0
    trgt1 = 0
    trgt2 = 0

    REM Setup correct memory location to write to or read from
    REM trgt1 = the specific bit we want to focus on
    REM trgt2 = the register we want to work on (1 = scratch, 2 = output)
    SELECT CASE mema
        CASE "SR0"
            trgt1 = 1
            trgt2 = 1
            tpbit = (sctrg AND 1)
        CASE "SR1"
            trgt1 = 2
            trgt2 = 1
            tpbit = (sctrg AND 2) / 2
        CASE "SR2"
            trgt1 = 4
            trgt2 = 1
            tpbit = (sctrg AND 4) / 4
        CASE "SR3"
            trgt1 = 8
            trgt2 = 1
            tpbit = (sctrg AND 8) / 8
        CASE "SR4"
            trgt1 = 16
            trgt2 = 1
            tpbit = (sctrg AND 16) / 16
        CASE "SR5"
            trgt1 = 32
            trgt2 = 1
            tpbit = (sctrg AND 32) / 32
        CASE "SR6"
            trgt1 = 64
            trgt2 = 1
            tpbit = (sctrg AND 64) / 64
        CASE "SR7"
            trgt1 = 128
            trgt2 = 1
            tpbit = (sctrg AND 128) / 128
        CASE "OR0"
            trgt1 = 1
            trgt2 = 2
            tpbit = (outrg AND 1)
        CASE "OR1"
            trgt1 = 2
            trgt2 = 2
            tpbit = (outrg AND 2) / 2
        CASE "OR2"
            trgt1 = 4
            trgt2 = 2
            tpbit = (outrg AND 4) / 4
        CASE "OR3"
            trgt1 = 8
            trgt2 = 2
            tpbit = (outrg AND 8) / 8
        CASE "OR4"
            trgt1 = 16
            trgt2 = 2
            tpbit = (outrg AND 16) / 16
        CASE "OR5"
            trgt1 = 32
            trgt2 = 2
            tpbit = (outrg AND 32) / 32
        CASE "OR6"
            trgt1 = 64
            trgt2 = 2
            tpbit = (outrg AND 64) / 64
        CASE "OR7"
            trgt1 = 128
            trgt2 = 2
            tpbit = (outrg AND 128) / 128
        CASE "RR "
            tpbit = rr
        CASE "IR1"
            tpbit = (inprg AND 2) / 2
        CASE "IR2"
            tpbit = (inprg AND 4) / 4
        CASE "IR3"
            tpbit = (inprg AND 8) / 8
        CASE "IR4"
            tpbit = (inprg AND 16) / 16
        CASE "IR5"
            tpbit = (inprg AND 32) / 32
        CASE "IR6"
            tpbit = (inprg AND 64) / 64
        CASE "IR7"
            tpbit = (inprg AND 128) / 128
    END SELECT

    REM Execute the operation
    SELECT CASE opco
        CASE "NOP0"
            flago = 1
        CASE "LD  "
            IF ien = 1 THEN rr = tpbit
        CASE "ADD "
            IF ien = 1 THEN
                tprr = rr + carry + tpbit
                IF tprr = 0 THEN
                    rr = 0
                    carry = 0
                ELSEIF tprr = 1 THEN
                    rr = 1
                    carry = 0
                ELSEIF tprr = 2 THEN
                    rr = 0
                    carry = 1
                ELSEIF tprr = 3 THEN
                    rr = 1
                    carry = 1
                END IF
            END IF
        CASE "SUB "
            IF ien = 1 THEN
                IF tpbit = 1 THEN tpdb = 0 ELSE tpdb = 1
                tprr = rr + carry + tpdb
                IF tprr = 0 THEN
                    rr = 0
                    carry = 0
                ELSEIF tprr = 1 THEN
                    rr = 1
                    carry = 0
                ELSEIF tprr = 2 THEN
                    rr = 0
                    carry = 1
                ELSEIF tprr = 3 THEN
                    rr = 1
                    carry = 1
                END IF
            END IF
        CASE "ONE "
            rr = 1
            carry = 0
        CASE "NAND"
            IF ien = 1 THEN
                tprr = rr AND tpbit
                IF tprr = 1 THEN rr = 0 ELSE IF rr = 0 THEN rr = 1
            END IF
        CASE "OR  "
            IF ien = 1 THEN rr = rr OR tpbit
        CASE "XOR "
            IF ien = 1 THEN rr = rr XOR tpbit
        CASE "STO "
            IF oen = 1 THEN wrt = 1
        CASE "STOC"
            IF oen = 1 THEN wrt = 1
        CASE "IEN "
            ien = rr
        CASE "OEN "
            oen = rr
        CASE "IOC "
            ioc = 1
            BEEP
        CASE "RTN "
            rtn = 1
        CASE "SKZ "
            skz = 1
        CASE "NOPF"
            flagf = 1
        CASE "HLT "
            flagf = 1
    END SELECT

    REM Write the result to scratch or output if a STO/STOC operation
memstuff:
    IF wrt = 1 THEN
        tprr = rr
        IF opco = "STOC" THEN
              IF rr = 1 THEN tprr = 0 ELSE IF rr = 0 THEN tprr = 1
        END IF
        IF trgt2 = 1 THEN
            IF tpbit = 1 AND tprr = 0 THEN sctrg = sctrg - trgt1
            IF tpbit = 0 AND tprr = 1 THEN sctrg = sctrg + trgt1
        ELSEIF trgt2 = 2 THEN
            IF tpbit = 1 AND tprr = 0 THEN outrg = outrg - trgt1
            IF tpbit = 0 AND tprr = 1 THEN outrg = outrg + trgt1
        END IF
    END IF

REM Update the display
GOSUB update
REM Delay routine to make it not run at full tilt
nextline:
    TIMER ON
        start = TIMER
        DO
        LOOP UNTIL TIMER > start + speed
    TIMER OFF

REM End of main loop
skipcomm:
LOOP UNTIL (EOF(1))

REM If it's the end of the assembly program, seek back up to the top of
REM the file, then jump back up to top and execut DO LOOP again
SEEK #1, 2
GOTO letsgo

REM Close out the file and end the program
goodbye:
CLOSE #1
END


REM Subroutine to print all the flags and register values to screen
update:
    LOCATE 1, 17, 0
    PRINT opco
    LOCATE 2, 17, 0
    PRINT mema
    LOCATE 6, 12, 0
    PRINT carry
    LOCATE 7, 12, 0
    PRINT rr
    LOCATE 8, 12, 0
    PRINT ien
    LOCATE 9, 12, 0
    PRINT oen
    LOCATE 15, 12, 0
    PRINT flag0
    LOCATE 16, 12, 0
    PRINT wrt
    LOCATE 17, 12, 0
    PRINT ioc
    LOCATE 18, 12, 0
    PRINT rtn
    LOCATE 19, 12, 0
    PRINT skz

    REM Print the scratch register to screen
    LOCATE 10, 13, 0
    IF (sctrg AND 128) / 128 = 1 THEN PRINT "1";  ELSE PRINT "0";
    LOCATE 10, 14, 0
    IF (sctrg AND 64) / 64 = 1 THEN PRINT "1";  ELSE PRINT "0";
    LOCATE 10, 15, 0
    IF (sctrg AND 32) / 32 = 1 THEN PRINT "1";  ELSE PRINT "0";
    LOCATE 10, 16, 0
    IF (sctrg AND 16) / 16 = 1 THEN PRINT "1";  ELSE PRINT "0";
    LOCATE 10, 17, 0
    IF (sctrg AND 8) / 8 = 1 THEN PRINT "1";  ELSE PRINT "0";
    LOCATE 10, 18, 0
    IF (sctrg AND 4) / 4 = 1 THEN PRINT "1";  ELSE PRINT "0";
    LOCATE 10, 19, 0
    IF (sctrg AND 2) / 2 = 1 THEN PRINT "1";  ELSE PRINT "0";
    LOCATE 10, 20, 0
    IF (sctrg AND 1) = 1 THEN PRINT "1" ELSE PRINT "0"

    REM Print the output register to screen
    LOCATE 11, 13, 0
    IF (outrg AND 128) / 128 = 1 THEN PRINT "1";  ELSE PRINT "0";
    LOCATE 11, 14, 0
    IF (outrg AND 64) / 64 = 1 THEN PRINT "1";  ELSE PRINT "0";
    LOCATE 11, 15, 0
    IF (outrg AND 32) / 32 = 1 THEN PRINT "1";  ELSE PRINT "0";
    LOCATE 11, 16, 0
    IF (outrg AND 16) / 16 = 1 THEN PRINT "1";  ELSE PRINT "0";
    LOCATE 11, 17, 0
    IF (outrg AND 8) / 8 = 1 THEN PRINT "1";  ELSE PRINT "0";
    LOCATE 11, 18, 0
    IF (outrg AND 4) / 4 = 1 THEN PRINT "1";  ELSE PRINT "0";
    LOCATE 11, 19, 0
    IF (outrg AND 2) / 2 = 1 THEN PRINT "1";  ELSE PRINT "0";
    LOCATE 11, 20, 0
    IF (outrg AND 1) = 1 THEN PRINT "1" ELSE PRINT "0"

    REM Print the input register to screen
    LOCATE 12, 13, 0
    IF (inprg AND 128) / 128 = 1 THEN PRINT "1";  ELSE PRINT "0";
    LOCATE 12, 14, 0
    IF (inprg AND 64) / 64 = 1 THEN PRINT "1";  ELSE PRINT "0";
    LOCATE 12, 15, 0
    IF (inprg AND 32) / 32 = 1 THEN PRINT "1";  ELSE PRINT "0";
    LOCATE 12, 16, 0
    IF (inprg AND 16) / 16 = 1 THEN PRINT "1";  ELSE PRINT "0";
    LOCATE 12, 17, 0
    IF (inprg AND 8) / 8 = 1 THEN PRINT "1";  ELSE PRINT "0";
    LOCATE 12, 18, 0
    IF (inprg AND 4) / 4 = 1 THEN PRINT "1";  ELSE PRINT "0";
    LOCATE 12, 19, 0
    IF (inprg AND 2) / 2 = 1 THEN PRINT "1";  ELSE PRINT "0";
RETURN

REM Halt subroutine
halted:
LOCATE 21, 14, 0
PRINT "HALTED "
LOCATE 22, 1, 0
PRINT "PRESS 'G' TO RESUME..."
DO
    inky = INKEY$
    IF inky = CHR$(97) OR inky = CHR$(100) OR inky = CHR$(119) THEN GOSUB toggle
    TIMER ON
        start = TIMER
        DO
        LOOP UNTIL TIMER > start + .1
    TIMER OFF
    IF inky = CHR$(71) OR inky = CHR$(103) THEN inkt = 1 ELSE inkt = 0
LOOP WHILE inkt = 0
LOCATE 21, 14, 0
PRINT "RUNNING"
LOCATE 22, 1, 0
PRINT "                          "
flagf = 0
RETURN

REM Key input to change input register subroutine
toggle:
IF inky = CHR$(97) AND inloc > 13 THEN inloc = inloc - 1
IF inky = CHR$(100) AND inloc < 19 THEN inloc = inloc + 1
LOCATE 13, 13, 0
PRINT "        "
LOCATE 13, inloc, 0
PRINT "^"
    IF inky = CHR$(119) THEN
        IF inloc = 13 THEN tsbit = 128
        IF inloc = 14 THEN tsbit = 64
        IF inloc = 15 THEN tsbit = 32
        IF inloc = 16 THEN tsbit = 16
        IF inloc = 17 THEN tsbit = 8
        IF inloc = 18 THEN tsbit = 4
        IF inloc = 19 THEN tsbit = 2
        inbit = (inprg AND tsbit) / tsbit
      IF inbit = 1 THEN inprg = inprg - tsbit ELSE inprg = inprg + tsbit
    END IF
    GOSUB update
RETURN

REM Bad file name or path subroutine
REM Although, it's not really a subroutine
REM And for some reason, it only works once, the second crashes...
badfile:
PRINT "File not found."
PRINT "Double check path or file name."
PRINT "Press 'R' to restart program, or press 'ESC' to quit."
DO
    inky = INKEY$
    IF inky = CHR$(27) THEN
        GOTO goodbye
    ELSEIF inky = CHR$(114) THEN
        GOTO restart
    END IF
    SLEEP 1
LOOP

