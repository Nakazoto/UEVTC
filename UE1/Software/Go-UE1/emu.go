package main

import (
	"flag"
	"fmt"
)

type Flags struct {
	f    byte
	ioc  byte
	skz  byte
	rtn  byte
	wrt  byte
	zero byte
}

type Registers struct {
	carry   byte
	ien     byte
	input   byte
	oen     byte
	output  byte
	rr      byte
	scratch byte
}

type CPU struct {
	tmpbit byte
	tmpdb  byte
	tmprr  byte

	whichBit    byte
	whichOutput int

	flag     *Flags
	register *Registers
}

func (c *CPU) writeMemRegister(outRegister int) (err error) {
	registerValue := c.register.scratch
	if outRegister == Output {
		registerValue = c.register.output
	}

	val := registerValue
	if c.tmpbit == 1 && c.tmprr == 0 {
		val = registerValue - c.whichBit
	} else if c.tmpbit == 0 && c.tmprr == 1 {
		val = registerValue + c.whichBit
	}

	switch outRegister {
	case Output:
		c.register.output = val
	case Scratch:
		c.register.scratch = val
	default:
		return fmt.Errorf("unrecognized output number. Got: `%d`",
			outRegister)
	}
	return
}

func (c *CPU) printCpuStat() {
	fmt.Println("--------------------")
	fmt.Println("REGISTERS")
	fmt.Printf("CARRY     = %b\n", c.register.carry)
	fmt.Printf("RESULTS   = %b\n", c.register.rr)
	fmt.Printf("INPUT EN  = %b\n", c.register.ien)
	fmt.Printf("OUTPUT EN = %b\n", c.register.oen)
	fmt.Printf("SCRATCH   = %b (%d)\n",
		c.register.scratch, c.register.scratch)
	fmt.Printf("OUTPUT    = %b (%d)\n",
		c.register.output, c.register.output)
	fmt.Printf("INPUT SW. = %b\n\n", c.register.input)

	fmt.Println("FLAGS")
	fmt.Printf("FLAG 0    = %b\n", c.flag.zero)
	fmt.Printf("WRITE     = %b\n", c.flag.wrt)
	fmt.Printf("I/O CON   = %b\n", c.flag.ioc)
	fmt.Printf("RETURN    = %b\n", c.flag.rtn)
	fmt.Printf("SKIP Z    = %b\n\n", c.flag.skz)
}

func (c *CPU) startEmulation(args []string) {
	flagSet := flag.NewFlagSet("ue1 emu", flag.ExitOnError)

	flagSet.Usage = usage("Usage: ue1 emu (options) <file>\n", flagSet)

	asmRun := flagSet.Bool("a", false, "")
	flagSet.BoolVar(asmRun, "asm", false, "use a .asm file for input rather than a binary")

	nonInt := flagSet.Bool("n", false, "")
	flagSet.BoolVar(nonInt, "non-interactive", false, "noninteractive mode - only output register displayed")

	speed := flagSet.Int("s", 60, "")
	flagSet.IntVar(speed, "speed", 60, "simulated clock speed in Hertz")

	err := flagSet.Parse(args)
	if err != nil {
		fatalln(err)
	}
	args = flagSet.Args()

	if len(args) != 1 {
		fatalln(fmt.Errorf("input file not supplied"))
	}

	if *speed <= 0 {
		fatalf("user-supplied speed cannot be used. got: %d\n", *speed)
	}

	if *asmRun {
		c.processAsm(args, *speed, *nonInt)
		return
	}
	c.processBin(args, *speed, *nonInt)
}
