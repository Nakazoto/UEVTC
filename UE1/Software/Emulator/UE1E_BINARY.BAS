REM Written by MACRO11
REM File access stuff
DIM path AS STRING
DIM file AS STRING
DIM flin AS STRING

REM Opcode and key input stuff
DIM inpc AS STRING
DIM inky AS INTEGER
DIM comm AS STRING
DIM speed AS SINGLE
DIM opcon AS INTEGER
DIM meman AS INTEGER

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
DIM ien AS INTEGER
DIM oen AS INTEGER
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

DIM inb AS INTEGER
DIM ins AS STRING

' Subroutine to print n as binary at specified screen position
DECLARE SUB bin (col AS INTEGER, row AS INTEGER, n AS INTEGER)

ON ERROR GOTO goterr   ' Set error routine

' Opening menu
CLS
PRINT "UE1 Emulator"
PRINT "This UE1 Emulator requires an assembly program to run."
PRINT
PRINT "How to use:"
PRINT "The program will run on a loop until 'ESC' is pressed to quit."
PRINT "Press 'H' to halt the CPU. A Flag F instruction will also halt."
PRINT "If the CPU is halted, press any key to resume."
PRINT "Press 'A' or 'D' to select the desired input switch bit."
PRINT "Press 'W' to toggle that bit from 0 to 1 or 1 to 0."

restart:
PRINT
INPUT "What is the program file path (ex.: c:\ueasm): ", path
INPUT "What is the program file name (excluding extension): ", file

IF RIGHT$(path, 1) <> "\" THEN path = path + "\"
flin = path + file + ".bin"
OPEN flin FOR BINARY AS #1                ' This will cause error if file not found

INPUT "What is the clock speed in Hz: ", speed
IF speed = 0 THEN speed = 10
speed = 1 / speed

' Draw the initial screen
CLS
PRINT "INSTRUCTION   : "
PRINT "MEMORY ADDRESS: "
PRINT "--------------------"
PRINT
PRINT "REGISTERS"
PRINT "CARRY     = "
PRINT "RESULTS   = "
PRINT "INPUT EN  = "
PRINT "OUTPUT EN = "
PRINT "SCRATCH   = "
PRINT "OUTPUT    = "
PRINT "INPUT SW. = "
PRINT
PRINT "FLAGS"
PRINT "FLAG 0    = "
PRINT "WRITE     = "
PRINT "I/O CON   = "
PRINT "RETURN    = "
PRINT "SKIP Z    = "
PRINT
PRINT "PROCESSOR IS RUNNING"
PRINT

' Primary loop
letsgo:

' Initialise variables
carry = 0
rr = 0
ien = 0
oen = 0
outrg = 0
sctrg = 0
inprg = 0
skz = 0
rtn = 0
tprr = 0
tpdb = 0
tpreg = 0
tpbit = 0
inloc = 13
inbit = 0
tsbit = 0

LOCATE 13, inloc, 0: PRINT "^"

DO
    ' Check if a key has been pressed
    ins = INKEY$
    IF LEN(ins) > 0 THEN inky = ASC(ins) ELSE inky = 0

    ' If upper case then convert to lower case
    IF inky >= 65 AND inky <= 90 THEN inky = inky + 32

    IF inky = 27 THEN GOTO goodbye    ' ESC

    ' h
    IF inky = 104 OR flagf = 1 THEN GOSUB halted    'h

    ' a or d or w
    IF inky = 97 OR inky = 100 OR inky = 119 THEN GOSUB toggle  ' a
   
    ' Skip this instruction if last instruction was SKZ and RR = 0
    IF skz <> 0 AND rr = 0 THEN
        skz = 0
        GOTO nextline
    END IF

    ' Skip this instruction if last instruction was RTN
    IF rtn <> 0 THEN
        rtn = 0
        GOTO nextline
    END IF
    
    ' Read in next opcode and memory address
    ins = INPUT$(1, #1)

    ' If end of file ins is null is just set inp as opcode 0
    IF LEN(ins) = 0 THEN inb = 0 ELSE inb = ASC(ins)

    ' Extract opcode and memory
    opcon = (inb \ 16) * 16
    meman = inb MOD 16

    ' Reset Flags
    flago = 0
    flagf = 0
    wrt = 0
    ioc = 0
    trgt1 = 0
    trgt2 = 0

    ' Setup correct memory location to write to or read from
    ' trgt1 = the specific bit we want to focus on
    ' trgt2 = the register we want to work on (1 = scratch, 2 = output)
    SELECT CASE meman
        ' SR0
        CASE 0
            trgt1 = 1
            trgt2 = 1
            tpbit = (sctrg AND 1)

        ' SR1
        CASE 1
            trgt1 = 2
            trgt2 = 1
            tpbit = (sctrg AND 2) / 2

        ' SR2
        CASE 2
            trgt1 = 4
            trgt2 = 1
            tpbit = (sctrg AND 4) / 4

        ' SR3
        CASE 3
            trgt1 = 8
            trgt2 = 1
            tpbit = (sctrg AND 8) / 8

        ' SR4
        CASE 4
            trgt1 = 16
            trgt2 = 1
            tpbit = (sctrg AND 16) / 16

        ' SR5
        CASE 5
            trgt1 = 32
            trgt2 = 1
            tpbit = (sctrg AND 32) / 32

        ' SR6
        CASE 6
            trgt1 = 64
            trgt2 = 1
            tpbit = (sctrg AND 64) / 64

        ' SR7
        CASE 7
            trgt1 = 128
            trgt2 = 1
            tpbit = (sctrg AND 128) / 128

        ' OR0 or RR
        CASE 8
            IF opcon = 128 OR opcon = 144 THEN
                trgt1 = 1
                trgt2 = 2
                tpbit = (outrg AND 1)
            ELSE
                tpbit = rr
            END IF

        ' OR1 or IR1
        CASE 9
            IF opcon = 128 OR opcon = 144 THEN
                trgt1 = 2
                trgt2 = 2
                tpbit = (outrg AND 2) / 2
            ELSE
                tpbit = (inprg AND 2) / 2
            END IF

        ' OR2 or IR2
        CASE 10
            IF opcon = 128 OR opcon = 144 THEN
                trgt1 = 4
                trgt2 = 2
                tpbit = (outrg AND 4) / 4
            ELSE
                tpbit = (inprg AND 4) / 4
            END IF

        ' OR3 or IR3
        CASE 11
            IF opcon = 128 OR opcon = 144 THEN
                trgt1 = 8
                trgt2 = 2
                tpbit = (outrg AND 8) / 8
            ELSE
                tpbit = (inprg AND 8) / 8
            END IF

        ' OR4 or IR4
        CASE 12
            IF opcon = 128 OR opcon = 144 THEN
                trgt1 = 16
                trgt2 = 2
                tpbit = (outrg AND 16) / 16
            ELSE
                tpbit = (inprg AND 16) / 16
            END IF

        'OR5 or IR5
        CASE 13
            IF opcon = 128 OR opcon = 144 THEN
                trgt1 = 32
                trgt2 = 2
                tpbit = (outrg AND 32) / 32
            ELSE
                tpbit = (inprg AND 32) / 32
            END IF

         'OR6 or IR6
         CASE 14
             IF opcon = 128 OR opcon = 144 THEN
                trgt1 = 64
                trgt2 = 2
                tpbit = (outrg AND 64) / 64
             ELSE
                 tpbit = (inprg AND 64) / 64
             END IF

        'OR7 or IR7
        CASE 15
            IF opcon = 128 OR opcon = 144 THEN
                trgt1 = 128
                trgt2 = 2
                tpbit = (outrg AND 128) / 128
            ELSE
                tpbit = (inprg AND 128) / 128
            END IF

    END SELECT

    ' Execute the operation
    SELECT CASE opcon
        ' NOP0
        CASE 0
            flago = 1

        ' LD
        CASE 16
            IF ien = 1 THEN rr = tpbit

        ' ADD
        CASE 32
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

        ' SUB
        CASE 48
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

        ' ONE
        CASE 64
            rr = 1
            carry = 0

        ' NAND
        CASE 80
            IF ien = 1 THEN
                tprr = rr AND tpbit
                IF tprr = 1 THEN rr = 0 ELSE IF rr = 0 THEN rr = 1
            END IF

        ' OR
        CASE 96
            IF ien = 1 THEN rr = rr OR tpbit

        ' XOR
        CASE 112
            IF ien = 1 THEN rr = rr XOR tpbit

        ' STO
        CASE 128
            IF oen = 1 THEN wrt = 1

        ' STOC
        CASE 144
            IF oen = 1 THEN wrt = 1

        ' IEN
        CASE 160
            ien = rr

        ' OEN
        CASE 176
            oen = rr

        ' IOC
        CASE 192
            ioc = 1
            BEEP

        ' RTN
        CASE 208
            rtn = 1

        'SKZ
        CASE 224
            skz = 1

        ' NOPF
        CASE 240
            flagf = 1

        'CASE "HLT "   ??? Not an opcode???
            'flagf = 1

        CASE ELSE
            PRINT "Unknown opcode: "; opcon

    END SELECT

    ' Write the result to scratch or output if a STO/STOC operation
    IF wrt = 1 THEN
        tprr = rr

        IF opcon = 144 THEN
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
    
' Print all the flags and register values to screen
update:
    LOCATE 1, 17, 0: PRINT opcon;
    LOCATE 2, 17, 0: PRINT meman;
    LOCATE 6, 12, 0: PRINT carry;
    LOCATE 7, 12, 0: PRINT rr;
    LOCATE 8, 12, 0: PRINT ien;
    LOCATE 9, 12, 0: PRINT oen;
    LOCATE 15, 12, 0: PRINT flag0;
    LOCATE 16, 12, 0: PRINT wrt;
    LOCATE 17, 12, 0: PRINT ioc;
    LOCATE 18, 12, 0: PRINT rtn;
    LOCATE 19, 12, 0: PRINT skz;

    CALL bin(13, 10, sctrg)   ' Print the scratch register to the screen
    CALL bin(13, 11, outrg)   ' print the output register to the screen
    CALL bin(13, 12, inprg)   ' print the input register to the screen

' Delay routine to make it not run at full tilt
nextline:
    TIMER ON
        start = TIMER
        DO
        LOOP UNTIL TIMER > start + speed
    TIMER OFF

' End of main loop
LOOP UNTIL (EOF(1))

' If it's the end of the assembly program, seek back up to the top of
' the file, then jump back up to top and execut DO LOOP again
SEEK #1, 1
GOTO letsgo

' Close out the file and end the program
goodbye:
CLOSE #1
END

' Halt subroutine
halted:
LOCATE 21, 14, 0: PRINT "HALTED ";
LOCATE 22, 1, 0:  PRINT "PRESS ANY KEY TO RESUME...";

DO
    SLEEP 1
LOOP WHILE INKEY$ = ""

LOCATE 21, 14, 0: PRINT "RUNNING";
LOCATE 22, 1, 0: PRINT "                          ";
flagf = 0
RETURN

' Key input to change input register subroutine
toggle:
' a
IF inky = 97 AND inloc > 13 THEN inloc = inloc - 1

' d
IF inky = 100 AND inloc < 19 THEN inloc = inloc + 1

LOCATE 13, 13, 0: PRINT "        ";
LOCATE 13, inloc, 0: PRINT "^";

' w
IF inky = 119 THEN
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
RETURN

' Bad file name or path routine
goterr:
IF ERR = 76 OR ERR = 53 OR ERR = 64 THEN
    PRINT "File not found."
    PRINT "Double check path or file name."
    PRINT "Press 'R' to restart program, or press 'ESC' to quit."

    DO
        inky = ASC(INKEY$)
        IF inky = 27 THEN   ' ESC
            RESUME goodbye
        ELSEIF inky = 114 THEN  ' r
            RESUME restart
        END IF
        SLEEP 1
    LOOP
END IF

PRINT "error "; ERR; " at line "; ERL
RESUME goodbye

' Subroutine to print an integer as binary at specified screen position
SUB bin (c AS INTEGER, r AS INTEGER, n AS INTEGER)
    LOCATE r, c, 0

     i% = 128
    
     DO
         IF (n AND i%) \ i% = 1 THEN PRINT "1";  ELSE PRINT "0";
         i% = i% \ 2
     LOOP WHILE i% > 0

END SUB

