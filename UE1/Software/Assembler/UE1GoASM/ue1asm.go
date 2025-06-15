package main

import (
	"bufio"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// opcodes maps assembly opcodes to their corresponding integer values.
var opcodes = map[string]int{
	"NOP0": 0,
	"LD":   16,
	"ADD":  32,
	"SUB":  48,
	"ONE":  64,
	"NAND": 80,
	"OR":   96,
	"XOR":  112,
	"STO":  128,
	"STOC": 144,
	"IEN":  160,
	"OEN":  176,
	"IOC":  192,
	"RTN":  208,
	"SKZ":  224,
	"NOPF": 240,
}

// memory maps memory operands to their corresponding integer values.
var memory = map[string]int{
	"SR0": 0, "SR1": 1, "SR2": 2, "SR3": 3, "SR4": 4, "SR5": 5, "SR6": 6, "SR7": 7,
	"OR0": 8, "RR": 8,
	"OR1": 9, "IR1": 9,
	"OR2": 10, "IR2": 10,
	"OR3": 11, "IR3": 11,
	"OR4": 12, "IR4": 12,
	"OR5": 13, "IR5": 13,
	"OR6": 14, "IR6": 14,
	"OR7": 15, "IR7": 15,
}

func main() {
	fmt.Println("UE1 Assembler (Go)")
	fmt.Println("File extension must be '.asm'")
	fmt.Println("File name must be eight characters or less.")
	fmt.Println("Output file will be the same name with a '.bin' extension.")
	fmt.Println("File to assemble can be specified on cmd line as -i filename")

	// Define command-line flags
	// -i: specifies the full path to the .asm file (e.g., C:\qbpr\myprog.asm)
	inputFilePathFlag := flag.String("i", "", "Path to the .asm assembly file (e.g., C:\\qbpr\\myprog.asm)")
	flag.Parse() // Parse the command-line arguments

	var inputFilePath string
	var outputFilePath string

	// Check if the input flag was provided
	if *inputFilePathFlag != "" {
		inputFilePath = *inputFilePathFlag
		// Derive output file path from input file path
		ext := filepath.Ext(inputFilePath)
		if ext == ".asm" {
			outputFilePath = inputFilePath[:len(inputFilePath)-len(ext)] + ".bin"
		} else {
			// If extension is not .asm, assume it's just the base name and add .bin
			outputFilePath = inputFilePath + ".bin"
		}
		fmt.Printf("Using input file: %s\n", inputFilePath)
		fmt.Printf("Output file will be: %s\n", outputFilePath)

		assembleErr := assembleFile(inputFilePath, outputFilePath)
		if assembleErr != nil {
			fmt.Println("Assembly failed:", assembleErr)
			os.Exit(1) // Exit with an error code
		} else {
			fmt.Println("Binary file creation finished.")
		}
	} else {
		// If no input flag, fall back to interactive mode
		for {
			fmt.Println()
			var path, file string

			fmt.Print("What is the file path (ex.: c:\\qbpr): ")
			_, err := fmt.Scanln(&path)
			if err != nil {
				fmt.Println("Error reading path:", err)
				continue
			}

			fmt.Print("What is the file name (excluding extension): ")
			_, err = fmt.Scanln(&file)
			if err != nil {
				fmt.Println("Error reading file name:", err)
				continue
			}

			// Clean up path and ensure it ends with a separator
			path = strings.TrimSpace(path)
			if path != "" && !strings.HasSuffix(path, string(os.PathSeparator)) {
				path += string(os.PathSeparator)
			}

			inputFilePath = path + file + ".asm"
			outputFilePath = path + file + ".bin"

			fmt.Println("Creating binary file...")
			assembleErr := assembleFile(inputFilePath, outputFilePath)

			if assembleErr != nil {
				// Check for specific file-related errors to prompt for retry
				if os.IsNotExist(assembleErr) || strings.Contains(assembleErr.Error(), "permission denied") || strings.Contains(assembleErr.Error(), "invalid file name") {
					fmt.Println(assembleErr)
					fmt.Println("Please try again.")
					continue // Loop back to ask for file paths again
				} else {
					fmt.Println("An unexpected error occurred:", assembleErr)
					os.Exit(1) // Exit on other errors
				}
			} else {
				fmt.Println("Binary file creation finished.")
				break // Exit on successful assembly
			}
		}
	}
}

// assembleFile reads the assembly file, processes it, and writes the binary output.
func assembleFile(inputPath, outputPath string) error {
	// Open input file
	inFile, err := os.Open(inputPath)
	if err != nil {
		return fmt.Errorf("error opening input file '%s': %w", inputPath, err)
	}
	defer inFile.Close() // Ensure the input file is closed

	// Create output file
	outFile, err := os.Create(outputPath)
	if err != nil {
		return fmt.Errorf("error creating output file '%s': %w", outputPath, err)
	}
	defer outFile.Close() // Ensure the output file is closed

	scanner := bufio.NewScanner(inFile)
	lineno := 0

	for scanner.Scan() {
		lineno++
		inpc := scanner.Text() // Read the current line

		// Replace control characters (ASCII < 32) with spaces to mimic QBasic's behavior
		// This handles tabs, newlines, etc. that might be embedded in the line.
		var cleanedInpc strings.Builder
		for _, r := range inpc {
			if r < 32 {
				cleanedInpc.WriteRune(' ')
			} else {
				cleanedInpc.WriteRune(r)
			}
		}
		inpc = cleanedInpc.String()

		// Find and remove comments (semicolon and everything after it)
		commentPos := strings.Index(inpc, ";")
		if commentPos != -1 {
			inpc = inpc[:commentPos]
		}

		// Trim leading and trailing whitespace
		inpc = strings.TrimSpace(inpc)

		// Ignore empty lines
		if len(inpc) == 0 {
			continue
		}

		// Find the first space to separate opcode and memory operand
		firstSpacePos := strings.Index(inpc, " ")
		if firstSpacePos == -1 {
			return fmt.Errorf("invalid syntax at line %d: missing space between opcode and operand", lineno)
		}

		opco := strings.ToUpper(inpc[:firstSpacePos])                    // Get opcode, convert to uppercase for case-insensitivity
		mema := strings.ToUpper(strings.TrimSpace(inpc[firstSpacePos:])) // Get memory operand, trim, convert to uppercase

		// Validate ORn usage: "Can only use ORn with STO or STOC ??"
		// This logic specifically checks if the opcode is NOT STO or STOC,
		// AND the memory operand starts with "OR".
		if (opco != "STO" && opco != "STOC") && strings.HasPrefix(mema, "OR") {
			return fmt.Errorf("invalid memory operand '%s' at line %d: ORn can only be used with STO or STOC", mema, lineno)
		}

		// Try to find opcode value
		opcodeValue, ok := opcodes[opco]
		if !ok {
			return fmt.Errorf("invalid opcode '%s' at line %d", opco, lineno)
		}

		// Try to find memory value
		memoryValue, ok := memory[mema]
		if !ok {
			return fmt.Errorf("invalid memory operand '%s' at line %d", mema, lineno)
		}

		// Calculate the final byte to write
		writ := opcodeValue + memoryValue

		// Write the byte to the binary file
		_, err = outFile.Write([]byte{byte(writ)})
		if err != nil {
			return fmt.Errorf("error writing to output file at line %d: %w", lineno, err)
		}
	}

	// Check for any scanner errors that occurred during iteration
	if err := scanner.Err(); err != nil {
		return fmt.Errorf("error reading input file: %w", err)
	}

	return nil // Success
}

func clearScreen() {

	// A more portable way for basic "clearing" is to print many newlines
	fmt.Print(strings.Repeat("\n", 80))
}
