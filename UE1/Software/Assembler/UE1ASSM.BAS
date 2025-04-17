DIM path AS STRING
DIM file AS STRING
DIM flin AS STRING
DIM flot AS STRING
DIM inpc AS STRING
DIM opco AS STRING
DIM mema AS STRING
DIM writ AS INTEGER
DIM writs AS STRING

CLS
PRINT "UE1 Assembler"
PRINT "File extension must be '.asm'"
PRINT "File name must be eight characters or less."
PRINT "Output file will be the same name with a '.bin' extension."
INPUT "What is the file path (ex.: c:\qbpr): ", path
INPUT "What is the file name (excluding extension): ", file
PRINT "Creating binary file..."

IF RIGHT$(path, 1) <> "\" THEN path = path + "\"

flin = path + file + ".asm"
flot = path + file + ".bin"
PRINT flin

OPEN flin FOR INPUT AS #1
OPEN flot FOR BINARY AS #2

DO
    LINE INPUT #1, inpc
    writ = 0
    opco = LEFT$(inpc, 4)
    mema = MID$(inpc, 6, 3)

    SELECT CASE opco
        CASE "NOP0"
            writ = writ + 0
        CASE "LD  "
            writ = writ + 16
        CASE "ADD "
            writ = writ + 32
        CASE "SUB "
            writ = writ + 48
        CASE "ONE "
            writ = writ + 64
        CASE "NAND"
            writ = writ + 80
        CASE "OR  "
            writ = writ + 96
        CASE "XOR "
            writ = writ + 112
        CASE "STO "
            writ = writ + 128
        CASE "STOC"
            writ = writ + 144
        CASE "IEN "
            writ = writ + 160
        CASE "OEN "
            writ = writ + 176
        CASE "IOC "
            writ = writ + 192
        CASE "RTN "
            writ = writ + 208
        CASE "SKZ "
            writ = writ + 224
        CASE "NOPF"
            writ = writ + 240
        CASE ELSE
            GOTO nextline
    END SELECT

    SELECT CASE mema
        CASE "SR0"
            writ = writ + 0
        CASE "SR1"
            writ = writ + 1
        CASE "SR2"
            writ = writ + 2
        CASE "SR3"
            writ = writ + 3
        CASE "SR4"
            writ = writ + 4
        CASE "SR5"
            writ = writ + 5
        CASE "SR6"
            writ = writ + 6
        CASE "SR7"
            writ = writ + 7
        CASE "OR0", "RR "
            writ = writ + 8
        CASE "OR1", "IR1"
            writ = writ + 9
        CASE "OR2", "IR2"
            writ = writ + 10
        CASE "OR3", "IR3"
            writ = writ + 11
        CASE "OR4", "IR4"
            writ = writ + 12
        CASE "OR5", "IR5"
            writ = writ + 13
        CASE "OR6", "IR6"
            writ = writ + 14
        CASE "OR7", "IR7"
            writ = writ + 15
        CASE ELSE
            PRINT "Missing or incorrect memory address, assemble cancelled."
            GOTO goodbye
    END SELECT

    writs = CHR$(writ)
    PUT #2, , writs
nextline:
LOOP UNTIL (EOF(1))

PRINT "Binary file creation finished."

goodbye:
CLOSE #1
CLOSE #2

