Dim file As String
Dim flin As String
Dim flot As String
Dim inpc As String
Dim comm As String
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
    comm = Left$(inpc, 1)
    If comm = ";" Then GoTo nextline
    writ = 0
    opco = Left$(inpc, 4)
    If opco = "NOP0" Then writ = writ + 0
    If opco = "LD  " Then writ = writ + 16
    If opco = "ADD " Then writ = writ + 32
    If opco = "SUB " Then writ = writ + 48
    If opco = "ONE " Then writ = writ + 64
    If opco = "NAND" Then writ = writ + 80
    If opco = "OR  " Then writ = writ + 96
    If opco = "XOR " Then writ = writ + 112
    If opco = "STO " Then writ = writ + 128
    If opco = "STOC" Then writ = writ + 144
    If opco = "IEN " Then writ = writ + 160
    If opco = "OEN " Then writ = writ + 176
    If opco = "IOC " Then writ = writ + 192
    If opco = "RTN " Then writ = writ + 208
    If opco = "SKZ " Then writ = writ + 224
    If opco = "NOPF" Then writ = writ + 240

    mema = Mid$(inpc, 6, 3)
    If mema = "SR0" Then writ = writ + 0
    If mema = "SR1" Then writ = writ + 1
    If mema = "SR2" Then writ = writ + 2
    If mema = "SR3" Then writ = writ + 3
    If mema = "SR4" Then writ = writ + 4
    If mema = "SR5" Then writ = writ + 5
    If mema = "SR6" Then writ = writ + 6
    If mema = "SR7" Then writ = writ + 7
    If mema = "OR0" Or mema = "RR " Then writ = writ + 8
    If mema = "OR1" Or mema = "IR1" Then writ = writ + 9
    If mema = "OR2" Or mema = "IR2" Then writ = writ + 10
    If mema = "OR3" Or mema = "IR3" Then writ = writ + 11
    If mema = "OR4" Or mema = "IR4" Then writ = writ + 12
    If mema = "OR5" Or mema = "IR5" Then writ = writ + 13
    If mema = "OR6" Or mema = "IR6" Then writ = writ + 14
    If mema = "OR7" Or mema = "IR7" Then writ = writ + 15


    Put #2, , writ

    nextline:
Loop

Print "Binary file creation finished."
Close #1
Close #2


