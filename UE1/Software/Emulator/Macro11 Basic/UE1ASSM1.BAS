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

' These are external functions in ue1lib
DECLARE FUNCTION parse% (inps1 AS STRING, lineno AS INTEGER)
DECLARE FUNCTION find% (nam AS STRING)

' Set run-time error handler
ON ERROR GOTO goterr

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
    lineno = lineno + 1
    writ = parse%(inpc, lineno)           ' Parse line
   
    IF writ <> -1 THEN
        writs = CHR$(writ)
        PUT #2, , writs
    END IF

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

