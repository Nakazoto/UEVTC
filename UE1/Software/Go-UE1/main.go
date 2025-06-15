package main

import (
	"flag"
	"fmt"
	"os"
)

// enumerate both output and opcodes here in main -
// assembly and emulation both need these constants
const (
	Output = iota
	Scratch
)

const (
	nopz byte = iota << 4
	ld
	add
	sub
	one
	nand
	or
	xor
	sto
	stoc
	ien
	oen
	ioc
	rtn
	skz
	nopf
)

// a little concordance we'll use later
var opcodes = map[string]byte{
	"nop0": nopz, "ld": ld, "add": add, "sub": sub,
	"one": one, "nand": nand, "or": or, "xor": xor,
	"sto": sto, "stoc": stoc, "ien": ien, "oen": oen,
	"ioc": ioc, "rtn": rtn, "skz": skz, "nopf": nopf,
}

func fatalf(f string, v ...any) {
	fmt.Printf(f, v)
	os.Exit(1)
}

func fatalln(e error) {
	fmt.Println(e)
	os.Exit(1)
}

func usage(msg string, f *flag.FlagSet) func() {
	return func() {
		fmt.Fprintf(os.Stderr, msg)

		if f != nil {
			f.PrintDefaults()
		}
		os.Exit(1)
	}
}

func main() {
	defaultUsage := usage("Usage: ue1 [build, emu] (options) <file>\n", nil)
	flag.Usage = defaultUsage
	flag.Parse()

	args := flag.Args()
	if len(args) == 0 {
		defaultUsage()
	}
	cmd, args := args[0], args[1:]

	switch cmd {
	case "build":
		buildAsm(args)
	case "emu":
		ueOne := &CPU{
			flag:     new(Flags),
			register: new(Registers),
		}

		ueOne.startEmulation(args)
	default:
		fmt.Printf("Unrecognized subcommand %q.\n", cmd)
		defaultUsage()
	}
}
