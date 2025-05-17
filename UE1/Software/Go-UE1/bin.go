package main

import (
	"bufio"
	"fmt"
	"os"
	"time"
)

var opcodeStrings = [16]string{
	"NOP0", "LD", "ADD", "SUB",
	"ONE", "NAND", "OR", "XOR",
	"STO", "STOC", "IEN", "OEN",
	"IOC", "RTN", "SKZ", "NOPF",
}

func (c *CPU) parseOpcodeBin(b byte) (err error) {
	switch b {
	case nopz:
		c.flag.zero = 1
	case ld:
		if c.register.ien == 1 {
			c.register.rr = c.tmpbit
		}
	case add:
		if c.register.ien == 1 {
			c.tmprr = c.register.rr + c.register.carry + c.tmpbit

			c.register.rr = c.tmprr & 1
			c.register.carry = (c.tmprr & 0b10) >> 1
		}
	case sub:
		if c.register.ien == 1 {
			c.tmpdb = ^c.tmpbit & 1
			c.tmprr = c.register.rr + c.register.carry + c.tmpdb

			c.register.rr = c.tmprr & 1
			c.register.carry = (c.tmprr & 0b10) >> 1
		}
	case one:
		c.register.rr = 1
		c.register.carry = 0
	case nand:
		if c.register.ien == 1 {
			c.tmprr = c.register.rr & c.tmpbit

			if c.tmprr == 1 {
				c.register.rr = 0
			} else if c.register.rr == 0 {
				c.register.rr = 1
			}
		}
	case or:
		if c.register.ien == 1 {
			c.register.rr = c.register.rr | c.tmpbit
		}
	case xor:
		if c.register.ien == 1 {
			c.register.rr = c.register.rr ^ c.tmpbit
		}
	case sto:
		if c.register.oen == 1 {
			c.flag.wrt = 1
		}
	case stoc:
		if c.register.oen == 1 {
			c.flag.wrt = 1
			c.tmprr = ^c.register.rr & 1
		}
	case ien:
		c.register.ien = c.tmpbit
	case oen:
		c.register.oen = c.tmpbit
	case ioc:
		c.flag.ioc = 1
		fmt.Print("\a") // BEEP, depending on terminal settings
	case rtn:
		c.flag.rtn = 1
	case skz:
		c.flag.skz = 1
	case nopf:
		c.flag.f = 1
	default:
		return fmt.Errorf("unrecognized opcode. byte value: %X", b)
	}

	if c.flag.wrt == 1 {
		if b != stoc {
			c.tmprr = c.register.rr
		}
	}
	return
}

func (c *CPU) parseAddressBin(b byte) (err error) {
	var bitPos int

	op := b & 0xF0
	addr := b & 0x0F
	switch {
	case addr < 0x08:
		// SR0 - SR7
		c.whichBit = 1 << int(addr)
		c.whichOutput = Scratch
		c.tmpbit = (c.register.scratch & c.whichBit) >> int(addr)
	case addr == 0x08 && !(op == sto || op == stoc):
		// RR
		c.tmpbit = c.register.rr
	case addr < 0x10:
		bitPos = int(addr - 0x08)
		c.whichBit = 1 << bitPos

		// OR0 - OR7
		if op == sto || op == stoc {
			c.whichBit = 1 << bitPos
			c.whichOutput = Output
			c.tmpbit = (c.register.output & c.whichBit) >> bitPos
		} else {
			// IR1 - IR7
			c.tmpbit = (c.register.input & c.whichBit) >> bitPos
		}
	default:
		return fmt.Errorf("unable to parse address in byte: %v", err)
	}
	return
}

func (c *CPU) processBin(args []string, speed int, nonint bool) {
	ticker := time.NewTicker(time.Second / time.Duration(speed))
	defer ticker.Stop()

	source, err := os.Open(args[len(args)-1])
	if err != nil {
		fatalln(err)
	}
	defer source.Close()

	reader := bufio.NewReader(source)
	for {
		b, err := reader.ReadByte()
		if err != nil {
			if err.Error() == "EOF" {
				break
			}
			fatalln(err)
		}

		if err = c.parseAddressBin(b); err != nil {
			fatalln(err)
		}

		if err = c.parseOpcodeBin(b & 0xF0); err != nil {
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
		opString := opcodeStrings[b&0xF0>>4]
		addrString := fmt.Sprintf("%02X", int(b&0x0F))
		fmt.Println("INSTRUCTION   : ", opString)
		fmt.Println("MEMORY ADDRESS: ", addrString)

		c.printCpuStat()
		c.flag.wrt = 0
	}
	if nonint {
		fmt.Printf("OUTPUT    = %b (%d)\n",
			c.register.output, c.register.output)
	}
}
