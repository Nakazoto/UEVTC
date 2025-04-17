' Rewritten by MACRO11
' Define used variables
DIM path AS STRING
DIM file AS STRING
DIM flin AS STRING
DIM flot AS STRING
DIM inpc AS STRING
DIM opco AS STRING
DIM mema AS STRING
DIM writ AS INTEGER
DIM writs AS STRING
DIM lineno AS INTEGER
DIM postn AS INTEGER
DIM got AS STRING
DIM value AS INTEGER
DIM code AS STRING

' Set run-time error handler
ON ERROR GOTO goterr

' Function to find data
' Input is code as string
' Output is value as integer. -1 indicates not found
' Caller has to restore data correctly before call
DEF fnfind (a$)
DIM dat AS STRING
DIM num AS INTEGER

DO
    READ dat, num
LOOP UNTIL dat = a$ OR num = -1
fnfind = num
END DEF

' Program starts here
CLS
PRINT "UE1 Assembler"
PRINT "File extension must be '.asm'"
PRINT "File name must be eight characters or less."
PRINT "Output file will be the same name with a '.bin' extension."

again:
PRINT
INPUT "What is the file path (ex.: c:\qbpr): ", path
INPUT "What is the file name (excluding extension): ", file

path = LTRIM$(RTRIM$(path))             ' Remove leading and traiking spaces
IF RIGHT$(path, 1) <> "\" THEN path = path + "\"

flot = path + file + ".bin"
flin = path + file + ".asm"

OPEN flin FOR INPUT AS #1               ' This will error trap if file can't be opened
OPEN flot FOR BINARY AS #2

PRINT "Creating binary file..."

lineno = 0                               ' Initialise read line number

DO
    LINE INPUT #1, inpc                  ' Read next statement

    ' Input can have a mixture of space and tab chars as white space
    ' So make any control char to a space so get removed with trim
    l% = LEN(inpc)
    FOR i% = 1 TO l%
        IF ASC(MID$(inpc, i%, 1)) < 32 THEN MID$(inpc, i%, 1) = " "
    NEXT i%
   
    lineno = lineno + 1
    postn = INSTR(inpc, ";")                              ' Find position of comment if any
    IF postn > 0 THEN inpc = LEFT$(inpc, postn - 1)       ' Remove any comments
    inpc = LTRIM$(RTRIM$(inpc))                           ' Remove leading and trailing spaces
    IF LEN(inpc) = 0 THEN GOTO nextline                   ' Ignore if no source
    postn = INSTR(inpc, " ")                              ' Find first space past opcode
    IF postn = 0 THEN PRINT "Invalid syntax at line "; lineno: GOTO nextline
    opco = LEFT$(inpc, postn - 1)                         ' Get opcode
    mema = LTRIM$(MID$(inpc, postn))                      ' Get memory

    ' Can only use ORn with STO or STOC ??
    IF (opco <> "STO" AND opco <> "STOC") AND LEFT$(mema, 2) = "OR" THEN
        PRINT "Invalid memory at line "; lineno: GOTO nextline
    END IF

    ' Try to find opcode
    RESTORE opcodes             ' Set data pointer to opcode data
    value = fnfind(opco)
    IF value = -1 THEN PRINT "Invalid opcode at line "; lineno: GOTO nextline
    writ = value

    ' Try to find memory
    RESTORE memory              ' Set data pointer to memory data
    value = fnfind(mema)
    IF value = -1 THEN PRINT "Invalid memory at line "; lineno: GOTO nextline
    writ = writ + value

    writs = CHR$(writ)
    PUT #2, , writs

nextline:
LOOP UNTIL EOF(1)

PRINT "Binary file creation finished."

goodbye:
CLOSE #1
CLOSE #2
END

' Handle any run-time errors
goterr:
' If error relates to file then handle and try again
IF ERR = 76 OR ERR = 53 OR ERR = 64 THEN
    PRINT "'"; flin; "' is not a valid file name."
    RESUME again
END IF

' Non-file error so display message and exit
PRINT "error "; ERR; " at line "; ERL
RESUME goodbye

' Opcode table
opcodes:
DATA NOP0, 0
DATA LD, 16
DATA ADD, 32
DATA SUB, 48
DATA ONE, 64
DATA NAND, 80
DATA OR, 96
DATA XOR, 112
DATA STO, 128
DATA STOC, 144
DATA IEN, 160
DATA OEN, 176
DATA IOC, 192
DATA RTN, 208
DATA SKZ, 224
DATA NOPF, 240
DATA "", -1

' Memory table
memory:
DATA SR0, 0
DATA SR1, 1
DATA SR2, 2
DATA SR3, 3
DATA SR4, 4
DATA SR5, 5
DATA SR6, 6
DATA SR7, 7
DATA OR0, 8
DATA RR, 8
DATA OR1, 9
DATA IR1, 9              
DATA OR2, 10
DATA IR2, 10
DATA OR3, 11
DATA IR3, 11
DATA OR4, 12
DATA IR4, 12
DATA OR5, 13
DATA IR5, 13
DATA OR6, 14
DATA IR6, 14
DATA OR7, 15
DATA IR7, 15
DATA "", -1

