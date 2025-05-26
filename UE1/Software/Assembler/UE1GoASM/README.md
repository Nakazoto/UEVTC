# **UE1 Assembler**

This is a Go-based assembler for the UE1 architecture, rewritten from a QBasic script. It reads `.asm` assembly files, parses opcodes and memory operands, and generates a `.bin` binary output file.


## **Features**


* Parses UE1 assembly code.
* Supports opcodes and memory operands as defined in the original QBasic script.
* Handles comments (lines starting with `;`).
* Trims whitespace and normalizes control characters in input lines.
* Provides error handling for invalid opcodes, memory operands, and file operations.
* Supports both interactive input for file paths and command-line arguments.


## **How to Compile**

To compile the Go source file into an executable, you need to have Go installed on your system.



1. **Save the Go source code:** Save the provided Go code (e.g., `ue1asm.go`) into a directory on your computer.
2. **Open your terminal or command prompt.**

**Navigate to the directory** where you saved `ue1asm.go`: \
cd /path/to/your/assembler/code



3. 

    *Run the <code>go build</code> command: \
    *go build -o ue1asm.exe ue1asm.go



4.  \

    * `-o ue1asm.exe`: This flag specifies the output executable name. You can choose any name you prefer. On Linux/macOS, the `.exe` extension is typically omitted (e.g., `go build -o ue1asm ue1asm.go`).
    * `ue1asm.go`: Replace this with the actual name of your Go source file if it's different.

After successful compilation, an executable file (e.g., `ue1asm.exe` on Windows, or `ue1asm` on Linux/macOS) will be created in the same directory.


## **How to Run**

You can run the assembler in two ways: interactively or by providing the input file via a command-line argument.


### **1. Interactive Mode (No Command-Line Arguments)**

If you run the executable without any command-line arguments, the assembler will prompt you for the file path and name.

**Example (Windows):**

.\ue1asm.exe

**Example (Linux/macOS):**

./ue1asm

The program will then guide you through entering the file path and name:

UE1 Assembler

File extension must be '.asm'

File name must be eight characters or less.

Output file will be the same name with a '.bin' extension.

What is the file path (ex.: c:\qbpr): C:\Users\YourUser\Documents\AssemblyProjects

What is the file name (excluding extension): myprogram


### **2. Using Command-Line Arguments**

You can specify the input assembly file directly using the `-i` flag. The output binary file will automatically be named with a `.bin` extension in the same directory as the input file.

**Syntax:**

./ue1asm -i &lt;path_to_your_assembly_file.asm>

**Example (Windows):**

.\ue1_assembler.exe -i "C:\Users\YourUser\Documents\AssemblyProjects\myprogram.asm"

**Example (Linux/macOS):**

./ue1_assembler -i "/home/youruser/assembly_projects/myprogram.asm"

The program will then display the input and output file paths and proceed with the assembly process.


## **Error Handling**

The assembler provides informative error messages for:



* File not found or permission issues.
* Invalid syntax (e.g., missing space between opcode and operand).
* Invalid opcodes or memory operands.
* Incorrect usage of `ORn` memory operands (only allowed with `STO` or `STOC`).

If an error occurs, the program will print the error message and, in interactive mode, allow you to try again. When run with command-line arguments, it will exit with an error code.