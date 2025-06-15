package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

func getBitPosition(addr string) (int, error) {
	pos, err := strconv.Atoi(string(addr[2]))
	if err != nil {
		return -1, fmt.Errorf("error converting address bit position: %v", err)
	}
	return pos, nil
}

func (c *CPU) parseAddressString(addr string) (err error) {
	var bitPos int
	dcAddress := strings.ToLower(addr)

	switch {
	case strings.HasPrefix(dcAddress, "sr"):
		if bitPos, err = getBitPosition(dcAddress); err == nil {
			c.whichBit = 1 << bitPos
			c.whichOutput = Scratch
			c.tmpbit = (c.register.scratch & c.whichBit) >> bitPos
		}
	case strings.HasPrefix(dcAddress, "or"):
		if bitPos, err = getBitPosition(dcAddress); err == nil {
			c.whichBit = 1 << bitPos
			c.whichOutput = Output
			c.tmpbit = (c.register.output & c.whichBit) >> bitPos
		}
	case strings.HasPrefix(dcAddress, "ir"):
		if bitPos, err = getBitPosition(dcAddress); err == nil {
			c.tmpbit = (c.register.input & c.whichBit) >> bitPos
		}
	case dcAddress == "rr":
		c.tmpbit = c.register.rr
	default:
		return fmt.Errorf("unable to parse address pnemonic `%s`: %v",
			addr, err)
	}
	return
}

func (c *CPU) parseOpcodeString(opcode string) (err error) {
	// I ain't writin' no long switch statement twice!
	dcOpcode := strings.ToLower(opcode)
	opcodeBin := opcodes[dcOpcode]

	return c.parseOpcodeBin(opcodeBin)
}

func (c *CPU) processAsm(args []string, speed int, nonint bool) {
	ticker := time.NewTicker(time.Second / time.Duration(speed))
	defer ticker.Stop()

	source, err := os.Open(args[len(args)-1])
	if err != nil {
		fatalln(err)
	}
	defer source.Close()

	scanner := bufio.NewScanner(source)
	for scanner.Scan() {
		line := scanner.Text()
		tokens := strings.Fields(line)

		if tokens[0] == ";" {
			continue
		}

		if err = c.parseAddressString(tokens[1]); err != nil {
			fatalln(err)
		}

		if err = c.parseOpcodeString(tokens[0]); err != nil {
			fatalln(err)
		}

		if c.flag.wrt == 1 {
			if c.whichOutput == Output {
				err = c.writeMemRegister(Output)
			} else {
				err = c.writeMemRegister(Scratch)
			}
		}
		if err != nil {
			fatalln(err)
		}

		if nonint {
			c.flag.wrt = 0
			continue
		}

		<-ticker.C
		fmt.Println("INSTRUCTION   : ", tokens[0])
		fmt.Println("MEMORY ADDRESS: ", tokens[1])

		c.printCpuStat()
		c.flag.wrt = 0
	}
	if nonint {
		fmt.Printf("OUTPUT    = %b (%d)\n",
			c.register.output, c.register.output)
	}
}
