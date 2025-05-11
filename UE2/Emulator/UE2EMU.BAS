REM ****************************************************************************
REM *                     Register Initialization                              *
REM ****************************************************************************
REM 15-Bit Regsiters
DIM ACR AS INTEGER            ' ACR = Accumulator Register
DIM HCR AS INTEGER            ' HCR = Holding Cell Register
DIM BVR AS INTEGER            ' BVR = Bravo Register
DIM CHR AS INTEGER            ' CHR = Charlie Register 
REM 12-Bit Registers
DIM PCR AS INTEGER            ' PCR = Program Counter Register
DIM MAR AS INTEGER            ' MAR = Memory Address Register
DIM AIR AS INTEGER            ' AIR = Address Input Register
REM 3-Bit Registers
DIM OIR AS INTEGER            ' OIR = OpCode Input Register
REM 1-Bit Status Registers
DIM CAR AS INTEGER            ' CAR = Carry Flag
DIM ZER AS INTEGER            ' ZER = Zero Flag
DIM MRD AS INTEGER            ' MRD = Memory Ready Flag

REM Initialize Emulator Specific Stuff (lower case)
DIM sped AS INTEGER           ' Used to determine clock speed
DIM strt AS INTEGER           ' Used in the speed routine
DIM inky AS INTEGER           ' The input for key presses
DIM inkt AS INTEGER           ' Used for the halt subroutine
DIM inpc AS STRING            ' Where the file is loaded into
DIM path AS STRING            ' Used specify the file directory
DIM file AS STRING            ' Used to specify the file name
DIM opco AS STRING            ' Ued to store the 3-bit opcode
DIM mema AS STRING            ' Used to store the 12-bit addr/lit/src_dest
DIM comm AS STRING            ' Used to detect a comment in the asm

REM Initialize Microcode Bits
DIM MEIN AS INTEGER           ' MEIN = Memory Input (Address)
DIM MBIN AS INTEGER           ' MBIN = Memory Input (Data)
DIM MEOT AS INTEGER           ' MEOT = Memory Output (Data)
DIM PCIC AS INTEGER           ' PCIC = Program Counter ?? I forgot...
DIM PCIN AS INTEGER           ' PCIN = Program Counter Input
DIM PCOT AS INTEGER           ' PCOT = Program Counter Output
DIM MAIN AS INTEGER           ' MAIN = Memory Address Input
DIM MAOT AS INTEGER           ' MAOT = Memory Address Output
DIM OIFM AS INTEGER           ' OIFM = OpCode Input From Memory
DIM AIFM AS INTEGER           ' AIFM = Adress Input From Memory
DIM AIOT AS INTEGER           ' AIOT = Address Instruction Output
DIM HCFM AS INTEGER           ' HCFM = Holding Cell from Memory
DIM HCTM AS INTEGER           ' HCTM = Holding Cell to Memory
DIM HCOT AS INTEGER           ' HCOT = Holding Cell Register Ouput
DIM HCIN AS INTEGER           ' HCIN = Holding Cell Register Input
DIM ACIN AS INTEGER           ' ACIN = Accumulator Register Input
DIM ACOT AS INTEGER           ' ACOT = Accumulator Register Ouput
DIM BVIN AS INTEGER           ' BVIN = Bravo Register Input
DIM BVOT AS INTEGER           ' BVOT = Bravo Register Output
DIM CHIN AS INTEGER           ' CHIN = Charlie Register Input
DIM CHOT AS INTEGER           ' CHOT = Charlie Register Output

REM ****************************************************************************
REM *                            File Load                                     *
REM ****************************************************************************
restart:
CLS
PRINT "UE2 Emulator"
PRINT "This UE2 Emulator requires an assembly program to run."
PRINT ""
PRINT "How to use:"
PRINT "The program will run on a loop until 'ESC' is pressed to quit."
PRINT "Press 'H' to halt the CPU."
PRINT "If the CPU is halted, press the 'G' key to resume."
PRINT ""
INPUT "What is the program file path (ex.: c:\ue2asm): ", path
INPUT "What is the program file name (excluding extension): ", file
INPUT "What is the clock speed in Hz: ", sped
IF sped = 0 THEN sped = 10
sped = 1 / sped

ON ERROR GOSUB badfile
IF RIGHT$(path, 1) <> "\" THEN path = path + "\"
flin = path + file + ".asm"
OPEN flin FOR INPUT AS #1

REM ****************************************************************************
REM *                                Reset                                     *
REM ****************************************************************************
reset:
ACR = 0
HCR = 0
BVR = 0
CHR = 0
PCR = 0
MAR = 0
AIR = 0
OIR = 0
CAR = 0
ZER = 0
MRD = 0

REM ****************************************************************************
REM *                             Primary Loop                                 *
REM ****************************************************************************
letsgo:
DO
    REM Check if a key has been pressed
    inky = INKEY$
    IF inky = CHR$(27) THEN GOTO goodbye          ' ESC key was pressed
    IF inky = CHR$(104) OR THEN GOSUB halted      ' H key was pressed

    REM Read in next opcode and memory address
    LINE INPUT #1, inpc
    opco = LEFT$(inpc, 3)
    mema = MID$(inpc, 6, 3)
    comm = LEFT$(inpc, 1)
    IF comm = ";" THEN GOTO skipcomm








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


REM ****************************************************************************
REM *                           Extra Subroutines                              *
REM ****************************************************************************

REM Bad file name or path
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
RETURN