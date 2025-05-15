package main

import (
	"bufio"
	"flag"
	"fmt"
	"os"
	"strings"
)

func isAscii(b byte) bool { return b >= 32 && b <= 126 }

func writeOpcode(op string) (byte, error) {
	dcOp := strings.ToLower(op)
	if b, ok := opcodes[dcOp]; ok {
		return b, nil
	}
	return 0, fmt.Errorf("Opcode invalid: %s\n", op)
}

func writeAddress(b byte, addr string) (byte, error) {
	var err error
	var bitPos int
	dcAddress := strings.ToLower(addr)

	switch {
	case strings.HasPrefix(dcAddress, "sr"):
		if bitPos, err = getBitPosition(dcAddress); err == nil {
			b += byte(bitPos)
		}
	case strings.HasPrefix(dcAddress, "or"),
		strings.HasPrefix(dcAddress, "ir"):
		if bitPos, err = getBitPosition(dcAddress); err == nil {
			b += byte(bitPos + 8)
		}
	case dcAddress == "rr":
		b += 8
	default:
		return 0, fmt.Errorf("Memory address invalid: %v\n", err)
	}
	return b, nil
}

func makeBinFilename(filename string) string {
	split := strings.Split(filename, ".")
	prefix := strings.Join(split[:len(split)-1], ".")

	return prefix + ".bin"
}

func handleDump(bytes []byte) {
	for i := 0; i < len(bytes); i++ {
		// byte count to start the row, much like hexdump
		if i%16 == 0 {
			fmt.Printf("%03X\u00A0 ", i)
		}

		// bytes are a space apart, except after 8 bytes,
		// just like hexd-... well, you get the idea.
		fmt.Printf("%02X ", bytes[i])
		if (i+1)%8 == 0 {
			fmt.Printf("\u00A0")
		}

		// there will likely never be deliberate characters
		// in the output, but we're on a roll!
		if (i+1)%16 == 0 {
			fmt.Printf("|")
			for j := i - 15; j <= i; j++ {
				if isAscii(bytes[j]) {
					fmt.Printf("%c", bytes[j])
				} else {
					fmt.Printf(".")
				}
			}
			fmt.Printf("|\n")
		}
	}

	// handle the last partial line, if there is one
	if len(bytes)%16 != 0 {
		remaining := len(bytes) % 16
		for k := 0; k < (16-remaining)*3; k++ { // padding
			fmt.Printf(" ")
		}
		if (16 - remaining) > 8 {
			fmt.Printf(" ") // add extra space for the 8-byte boundary
		}
		fmt.Printf(" |")

		start := len(bytes) - remaining
		for l := start; l < len(bytes); l++ {
			if isAscii(bytes[l]) {
				fmt.Printf("%c", bytes[l])
			} else {
				fmt.Printf(".")
			}
		}
		fmt.Printf("|\n")
	}
	fmt.Printf("%03X\n", len(bytes))
}

func assemble(f *os.File) (bytes []byte, err error) {
	defer f.Close()

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		tokens := strings.Fields(line)

		if tokens[0] == ";" {
			continue
		}

		op, err := writeOpcode(tokens[0])
		if err != nil {
			break
		}

		fullbyte, err := writeAddress(op, tokens[1])
		if err != nil {
			break
		}

		bytes = append(bytes, fullbyte)
	}
	return
}

func buildAsm(args []string) {
	flagSet := flag.NewFlagSet("ue1 build", flag.ExitOnError)
	flagSet.Usage = usage("Usage: ue1 build (options) <file>\n", flagSet)

	dump := flagSet.Bool("d", false, "")
	flagSet.BoolVar(dump, "dump", false, "dump assembled output to stdout in hex")

	output := flagSet.String("o", "", "filename for output (default is <file>.bin)")

	err := flagSet.Parse(args)
	if err != nil {
		fatalln(err)
	}
	args = flagSet.Args()

	if len(args) != 1 {
		fatalln(fmt.Errorf("ASM file not supplied"))
	}

	asmFile := args[len(args)-1]
	binFile := makeBinFilename(asmFile)
	if *output != "" {
		binFile = *output
	}

	src, err := os.Open(asmFile)
	if err != nil {
		fatalln(err)
	}

	assembled, err := assemble(src)
	if err != nil {
		fatalln(err)
	}

	// dump to stdout rather than a binary, in a hexdump-y sort of way
	if *dump {
		handleDump(assembled)
		return
	}

	dest, err := os.Create(binFile)
	if err != nil {
		fatalln(err)
	}
	defer dest.Close()

	length, err := dest.Write(assembled)
	if err != nil {
		fatalln(err)
	}
	dest.Sync()

	fmt.Printf("Wrote %d bytes to '%s'\n", length, binFile)
}
