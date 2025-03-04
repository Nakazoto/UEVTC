'Remove this for compatibility on other systems'
rootpath$ = Environ$("SYSTEMROOT") 'normally "C:\WINDOWS"
fontfile$ = rootpath$ + "\Fonts\consola.ttf" 'TTF file in Windows
style$ = "monospace" 'font style is not case sensitive
f& = _LoadFont(fontfile$, 24, style$)
_Font f&
'Remove this for compatibility on other systems'

Dim file As String
Dim flin As String
Dim flot As String
Dim inpc As String
Dim opco As String
Dim mema As String
Dim writ As _Byte

Print "UE1 Assembler"
Print "File extension must be '.asm'"
Print "Output file will be the same name with a '.bin' extension."
Input "What is the file name (excluding extension): ", file
Print "Creating binary file..."

flin = file + ".asm"
flot = file + ".bin"

Open flin For Input As #1
Open flot For Binary As #2

Do While Not EOF(1)
    Line Input #1, inpc
    writ = 0
    opco = Left$(inpc, 4)
    mema = Mid$(inpc, 6, 3)

    Select Case opco
        Case "NOP0"
            writ = writ + 0
        Case "LD "
            writ = writ + 16
        Case "ADD "
            writ = writ + 32
        Case "SUB "
            writ = writ + 48
        Case "ONE "
            writ = writ + 64
        Case "NAND"
            writ = writ + 80
        Case "OR  "
            writ = writ + 96
        Case "XOR "
            writ = writ + 112
        Case "STO "
            writ = writ + 128
        Case "STOC"
            writ = writ + 144
        Case "IEN "
            writ = writ + 160
        Case "OEN "
            writ = writ + 176
        Case "IOC "
            writ = writ + 192
        Case "RTN "
            writ = writ + 208
        Case "SKZ "
            writ = writ + 224
        Case "NOPF"
            writ = writ + 240
        Case Else
            GoTo nextline
    End Select

    Select Case mema
        Case "SR0"
            writ = writ + 0
        Case "SR1"
            writ = writ + 1
        Case "SR2"
            writ = writ + 2
        Case "SR3"
            writ = writ + 3
        Case "SR4"
            writ = writ + 4
        Case "SR5"
            writ = writ + 5
        Case "SR6"
            writ = writ + 6
        Case "SR7"
            writ = writ + 7
        Case "OR0", "RR "
            writ = writ + 8
        Case "OR1", "IR1"
            writ = writ + 9
        Case "OR2", "IR2"
            writ = writ + 10
        Case "OR3", "IR3"
            writ = writ + 11
        Case "OR4", "IR4"
            writ = writ + 12
        Case "OR5", "IR5"
            writ = writ + 13
        Case "OR6", "IR6"
            writ = writ + 14
        Case "OR7", "IR7"
            writ = writ + 15
        Case Else
            Print "Missing or incorrect memory address, assemble cancelled."
            GoTo goodbye
    End Select

    Put #2, , writ
    nextline:
Loop

Print "Binary file creation finished."

goodbye:
Close #1
Close #2

