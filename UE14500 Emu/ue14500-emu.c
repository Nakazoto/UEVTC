/* UE14500 emulator.

   License: Public Domain

   The code is very basic. The only requirement is a curses library (and the
   standard C library. On Linux and Mac, ncurses is used; on Windows pdcurses
   is used. To build, you really just need to compile this file and link to the
   cursees library. Build and run instructions (there are many ways - use these
   as a guide):

   Linux:
     - Ensure GCC is installed.
     - Ensure the ncurses development package (ncurses-dev) is installed.
     - gcc -o ue14500-emu ue14500-emu.c -lncurses
     - ./ue14500-emu

   Mac:
     - Ensure Xcode is installed.
     - clang -o ue14500-emu ue14500-emu.c -lncurses
     - ./ue14500-emu

   Windows:
     - Install MSYS2 (https://www.msys2.org) including the base dev package.
     - Install pdcurses (pacman -S mingw-w64-x86_64-pdcurses).
     - gcc -o ue14500-emu ue14500-emu.c -lpdcurses
     - ./ue14500-emu.exe

   After starting, the STATUS window will guide you through the initialization
   procedure which allows you to initialize the tubes to start up in any state.
   After initialization, the STATUS window disassembles the instruction input.
   Note that the clock requires toggling so you can see the clock in the high
   and low states.

   Controls:
     Q/q = quit.
     Space/return/enter/up/down/T/t = toggle.
     Left/right/H/h/L/l/tab/F1-F6 = move the cursor (^).
     0-3 = select I0-I3 respectively low.
     4-7 = select I0-I3 respectively high.
     d/D = select data input low/high.
     c/C = select clock input.
     k/K = equivalent to "c  " in a single cycle.
     b/B = trigger/resume a breakpoint.

   Command line:
     - If no arguments are given, interactive mode is entered. See above.
     - If one argument is given, it is the input file. If the first argument
       is "-", that is equivalent to no input file - this is used when you want
       an output file only. See below.
     - If two arguments are given, the first is the input file and the second
       is the output file. If the second argument is "-", the output is sent
       to stdout. See below.

   Input File: If an input file is given, inputs are read from that file until
   the file is exhausted or an error occurs. After input file exhaustion,
   interactive mode is entered unless the input file included a quit command.
   The input file format is described below. While the input file is being
   used, pressing any key will cut short the current delay period between
   commands.

   Output File: If an output file is given, data writes are recorded to that
   file in pure little-endian format. This means each bit is formed into bytes
   from least-to-most significant and written out when each bit has been set.
   If an incomplete byte is left at the end, it is written with zeros for the
   upper bits.

   Input File Format: The first line of the file must be a decimal integer that
   specifies the time to wait between key strokes in milliseconds (must be
   greater than zero) followed by a newline. The second line must be ten
   characters used to initialize the CPU followed by a newline. After that,
   the rest of the file is read as keystrokes to use as if typed manually,
   unless the character is a semicolon, in which case everything starting at
   the semicolon is ignored up to and including the next newline. As a special
   case, carriage returns (0x0D, '\r') are ignored in input files to avoid
   problems with DOS vs Unix line endings.

   Tip: insert characters which will be ignored to introduce an extra delay at
        certain points if desired.
   Tip: use 'q' in your input file to exit the emulator after running your
        program, especially if writing the output to a file.

   Breakpoints are meant to be used with input files as a form of rudimentary
   debugging. When a breakpoint is hit, the emulator stops reading from the
   input file and enters interactive mode until the breakpoint command is
   received again, at which point the emulator resumes reading the input file.
*/

#ifdef WIN32
#  include <pdcurses.h>
#else
#  include <curses.h>
#endif
#include <stdlib.h>

/* Screen size. */
#define SCREEN_Y 24
#define SCREEN_X 80

/* Controls. */
typedef enum controls_
{
  c_i3,
  c_i2,
  c_i1,
  c_i0,
  c_d,
  c_clk,

  num_controls
} controls;

/* Instructions. */
typedef enum instruction_
{
  i_nop0, /* 0000: NOP0 = No change in registers. RR -> RR. FLG0 high. */
  i_ld,   /* 0001: LD   = Load result register. Data -> RR. */
  i_add,  /* 0010: ADD  = Addition. D + RR -> RR. */
  i_sub,  /* 0011: SUB  = Subtraction. QD + RR -> RR. */
  i_one,  /* 0100: ONE  = Force one. 1 -> RR. 0 -> CAR. */
  i_nand, /* 0101: NAND = Logical NAND. Q(RR * D) -> RR. */
  i_or,   /* 0110: OR   = Logical OR. RR + D -> RR. */
  i_xor,  /* 0111: XOR  = Exclusive OR. RR != D -> RR. */
  i_sto,  /* 1000: STO  = Store. RR -> Data. Write high if OEN. */
  i_stoc, /* 1001: STOC = Store complement. QRR -> Data. Write high if OEN. */
  i_ien,  /* 1010: IEN  = Input enable. D -> IEN. */
  i_oen,  /* 1011: OEN  = Output enable. D -> OEN. */
  i_jmp,  /* 1100: JMP  = Jump. Jump high. */
  i_rtn,  /* 1101: RTN  = Return. RTN high. 1 -> Skip. */
  i_skz,  /* 1110: SKZ  = Skip if zero. 1 -> Skip if RR == 0. */
  i_nopf  /* 1111: NOPF = No change in registers. RR -> RR. FLGF high. */
} instruction;
static const char *instructions[] =
{
  "NOP0",
  "LD",
  "ADD",
  "SUB",
  "ONE",
  "NAND",
  "OR",
  "XOR",
  "STO",
  "STOC",
  "IEN",
  "OEN",
  "JMP",
  "RTN",
  "SKZ",
  "NOPF"
};

/* Structure to hold the state of the machine. */
typedef struct machine_state_
{
  /* The screen. */
  WINDOW *screen;

  /* The currently-selected control and the state of that control. */
  controls control;
  unsigned control_states[num_controls];

  /* Instruction register. */
  instruction ir;

  /* Input/output enable registers. */
  unsigned ien;
  unsigned oen;

  /* Result/carry registers. */
  unsigned rr;
  unsigned cr;

  /* Skip register. */
  unsigned skip;

  /* Input file or NULL for interactive. */
  FILE *in_file;
  unsigned delay;

  /* Output file or NULL for none. */
  FILE *out_file;
  unsigned curr_byte;
  unsigned bits_set;

  /* Breakpoint mode. */
  unsigned in_break;

  /* Error message or NULL for none. */
  const char *error;
} machine_state;

/* Return the instruction for the given state. */
#define GET_INSTR(state)                              \
  (((state)->control_states[c_i0] ? i_ld : i_nop0) |  \
   ((state)->control_states[c_i1] ? i_add : i_nop0) | \
   ((state)->control_states[c_i2] ? i_one : i_nop0) | \
   ((state)->control_states[c_i3] ? i_sto : i_nop0))

/* Helper functions. */
static int init_args(machine_state *state, int argc, char **argv);
static int uninit(machine_state *state);
static void draw_cpu(machine_state *state);
static void draw_remote(machine_state *state);
static void draw_status(machine_state *state);
static void draw_help(machine_state *state);
static void power_on(machine_state *state);
static void main_loop(machine_state *state);
static void clock_high(machine_state *state);
static void clock_low(machine_state *state);
static void select_control(machine_state *state, controls ctrl);
static void toggle_control(machine_state *state);
static void toggle_clock(machine_state *state);
static int get_input(machine_state *state);
static void write_data(machine_state *state, unsigned bit);

int main(int argc, char **argv)
{
  int y;
  int x;
  int delay;
  machine_state state = { 0 };

  /* Initialize arguments. */
  delay = init_args(&state, argc, argv);
  if (delay == 0)
  {
    return 1;
  }

  /* Initialize curses. Make sure the screen is big enough. This emulator is
     written to fit a standard physical TTY only. */
  state.screen = initscr();
  getmaxyx(state.screen, y, x);
  if (y < SCREEN_Y || x < SCREEN_X)
  {
    endwin();
    puts("Screen is too small.");
    return 1;
  }

  /* Turn off echo. */
  noecho();

  /* Enable keypad to get function key support. */
  keypad(stdscr, TRUE);

  /* Disable newline translation. */
  nonl();

  /* Make the cursor invisible. */
  curs_set(0);

  /* Enable unbuffered character input if no input file. */
  if (state.in_file == NULL)
  {
    cbreak();
  }
  else
  {
    /* Set the timeout with the delay time. */
    wtimeout(state.screen, delay);
  }

  /* Draw the CPU, remote, and status. */
  draw_cpu(&state);
  draw_remote(&state);
  draw_status(&state);

  /* Power on, then display help. */
  power_on(&state);
  draw_help(&state);

  /* Refresh. */
  wrefresh(state.screen);

  /* Loop to handle input. */
  main_loop(&state);

  /* End curses mode, restoring the terminal. */
  endwin();

  /* Uninitialize. */
  return uninit(&state);
}

static int init_args(machine_state *state, int argc, char **argv)
{
  char buff[80];
  int delay = 1;

  /* If there is an argument, it is the input file. */
  if (argc > 1)
  {
    /* Open the file for read. */
    state->in_file = fopen(argv[1], "rb");
    if (state->in_file == NULL)
    {
      fputs("Error opening input file.\n", stderr);
      return 0;
    }

    /* Read the first line to get the delay time. */
    if (fgets(buff, sizeof(buff), state->in_file) == NULL)
    {
      fputs("Error reading delay time.\n", stderr);
      return 0;
    }
    delay = (int)strtol(buff, NULL, 10);
  }

  /* If there is another argument, it is the output file. */
  if (argc > 2)
  {
    /* Open the file for write. */
    state->out_file = fopen(argv[2], "wb");
    if (state->out_file == NULL)
    {
      fputs("Error opening output file.\n", stderr);
      return 0;
    }
  }

  /* Success. */
  return delay;
}

static int uninit(machine_state *state)
{
  /* Close the input file. */
  if (state->in_file != NULL)
  {
    if (fclose(state->in_file) != 0)
    {
      fputs("Error closing input file.\n", stderr);
      return 1;
    }
  }

  /* Flush any pending byte and close the output file. */
  if (state->out_file != NULL)
  {
    if (state->bits_set != 0)
    {
      if (fputc(state->curr_byte, state->out_file) != state->curr_byte)
      {
        fputs("Error writing output file.\n", stderr);
        return 1;
      }
    }

    if (fclose(state->out_file) != 0)
    {
      fputs("Error closing output file.\n", stderr);
      return 1;
    }
  }

  /* Success. */
  return 0;
}

/* Add a horizontal line at the current position or at a given position. */
#define ADD_HLINE(win) waddch((win), ACS_HLINE)
#define MV_ADD_HLINE(win, y, x) mvwaddch((win), (y), (x), ACS_HLINE)

/* Add a vertical line at the current position or a given position. */
#define ADD_VLINE(win) waddch((win), ACS_VLINE)
#define MV_ADD_VLINE(win, y, x) mvwaddch((win), (y), (x), ACS_VLINE)

/* Add a left tee at the given position. */
#define MV_ADD_LTEE(win, y, x) mvwaddch((win), (y), (x), ACS_LTEE)

/* Add a right tee at the current position or at a given position. */
#define ADD_RTEE(win) waddch((win), ACS_RTEE)
#define MV_ADD_RTEE(win, y, x) mvwaddch((win), (y), (x), ACS_RTEE)

/* Add an upper-left corner at a given position. */
#define MV_ADD_UL(win, y, x) mvwaddch((win), (y), (x), ACS_ULCORNER)

/* Add an upper-right corner at the current position. */
#define ADD_UR(win) waddch((win), ACS_URCORNER)

/* Add a lower-left corner at a given position. */
#define MV_ADD_LL(win, y, x) mvwaddch((win), (y), (x), ACS_LLCORNER)

/* Add a lower-right corner at the current position. */
#define ADD_LR(win) waddch((win), ACS_LRCORNER)

/* Add a title string at the current position or a given position. */
#define ADD_TITLE(win, title) \
  wattron((win), A_BOLD);     \
  waddstr((win), (title));    \
  wattroff((win), A_BOLD)
#define MV_ADD_TITLE(win, y, x, title) \
  wattron((win), A_BOLD);              \
  mvwaddstr((win), (y), (x), (title)); \
  wattroff((win), A_BOLD)

/* Add a vaccuum tube at the given coordinate pair. */
#define ADD_TUBE(win, c) mvwaddch((win), c, '.')

/* Add a VFD at the given coordinate pair. */
#define ADD_VFD(win, c) mvwaddch((win), c, 'v')

/* Add an input at the given coordinate pair. */
#define ADD_INPUT(win, c, ch) mvwaddch((win), c, (ch))

/* VFD on/off. */
#define VFD_ON(win, c) mvwaddch((win), c, 'V' | A_BOLD)
#define VFD_ON_YX(win, y, x) mvwaddch((win), (y), (x), 'V' | A_BOLD)
#define VFD_OFF(win, c) mvwaddch((win), c, 'v' | A_DIM)
#define VFD_OFF_YX(win, y, x) mvwaddch((win), (y), (x), 'v' | A_DIM)

/* Input control 0/1. */
#define CONTROL_ON(win, c) mvwchgat((win), c, 1, A_STANDOUT, 0, NULL)
#define CONTROL_ON_YX(win, y, x)                    \
  mvwchgat((win), (y), (x), 1, A_STANDOUT, 0, NULL)
#define CONTROL_OFF(win, c) mvwchgat((win), c, 1, A_NORMAL, 0, NULL)
#define CONTROL_OFF_YX(win, y, x)                 \
  mvwchgat((win), (y), (x), 1, A_NORMAL, 0, NULL)

/* Input pointer on/off. */
#define POINTER_ON(win, y, x)              \
  mvwaddch((win), (y), (x), '^' | A_BOLD); \
  wmove((win), (y), (x))
#define POINTER_OFF(win, y, x) mvwaddch((win), (y), (x), ACS_HLINE)

/* Overall geometry:

     START|. .|                     UE14500
SKP--IR--IRB-INST-DEC-DECB  .: tube, v: VFD off, V: VFD on
|.|......|..| v |....|....| INST: instruction register VFDs
|.|......|..| v |....|....| IV: IEN VFD
|.|......|..| v |....|....| CRB: carry register buffer VFD
|.|......|..| v |....|....| RR: results register VFD
+-IENC--IEDT--IV--XOR-GLU1+ LV: logic unit VFD
|  .. |  .. | v  |.. |    | OSBS: OEN/SKIP VFDs
|  .. |--IENDFF--|.. |....| W: write VFD             +---------STATUS----------+
|     |  ......  |   |    | 0: flag 0 VFD            |                         |
+-CLKC---ADDER-G2-CARR-CRB+ J: jump flag VFD         +-------------------------+
|  ..   |.... |. | .... |v| R: return flag VFD
|  ..   |.... |. | .... |.| F: flag f VFD
+--LV---|     |. |------|.|
|   v   |LOGIC|. |-RR-|R|v| +---REMOTE----+ D: data, R: result register
+--RC---|.... |  |....|R|.| |D R W 0 J R F| W: write, 0: flag 0, J: jump
|  ..   |.... |  |....|B|.| |v v v v v v v| R: return, F: flag f
+C2-S--SKIP--WRITE-OB-OVFD+ |v v v v   v v| IIII: instruction
|..|.|......|......|.|W| v| |I I I I   D C| D: data ext. input, C: clock
|..|.|-OSBS-| .... |.|0| v| |3 2 1 0      |
+C1-O|..v..v|M|....|.|J| v| | INST    D  C| Q to quit.
|..|.|OENDFF|-FLGF-|.|R| v| |1 1 1 1  1  L| Clock toggles high/low separately.
|..|.|......| .... | |F| v| |0 0 0 0  0  K| Arrows/space/return/enter toggle.
            | .... |        +-------------+ Arrows/h/l/tab/F1-F6 move cursor.

   START = Soft start.
   SKP = Skip functionality on instruction register. 1x4 tubes.
   IR = Instruction register. 6x4 tubes.
   IRB = Instruction register buffers. 2x4 tubes.
   INST = Instruction VFDs. 1x4 VFDs top to bottom bits 0-3.
   DEC = Instruction register decoder. 4x4 tubes.
   DECB = Instruction register decoder buffers. 4x4 tubes.
   IENC = Input enable control. 2x2 tubes.
   IEDT = Input enable display tubes. 2x1 tubes.
   IV = Input enable display VFD. 1 VFD.
   IENDFF = Input enable register. 6x1 tubes.
   XOR = XOR gate. 2x2 tubes.
   GLU1 = Glue logic. 4x1 tubes.
   CLKC = Clock control. 2x2 tubes.
   LV = Logic unit VFD. 1 VFD.
   RC = Result register input control. 2x1 tubes.
   ADDER = Arithmetic unit. 4x2 tubes.
   LOGIC = Logic unit. 4x2 tubes.
   G2 = Glue logic. 1x4 tubes.
   CARR = Carry register 4x2 tubes.
   RR = Results register. 4x2 tubes.
   CRB = Carry register buffers. 1 VFD, 1x2 tubes.
   RRB = Results register buffers. 1 VFD, 1x2 tubes.
   C2 = Clock 2. 2x2 tubes.
   C1 = Clock 1. 2x2 tubes.
   S = Skip control. 1x2 tubes.
   O = Output enable control. 1x2 tubes.
   SKIP = Skip register. 6x1 tubes.
   OSBS = OEN/SKIP register buffer/inverter/display. 2/1/2/1 tube/VFD.
   OENDFF = Output enable register. 6x1 tubes.
   WRITE = Write board. 6x1 tubes, 4x1 tubes.
   M = Multiplexer. 4x1 tubes.
   FLGF = Flag F. 4x2 tubes.
   OB = Output buffers. 1x4 tubes.
   OVFD = Output VFDs. 1x5 VFDs.

   D R W 0 J R F = Data/RR/write/flag 0/jump/return/flag F VFDs.
   I3I2I1I0 = Instruction VFDs.
   D C = Data/clock VFDs.
   INST = Instruction switches.
   D = Data input button.
   CLK = Clock button.
*/

/* Coordinate. */
typedef struct coord_
{
  int y;
  int x;
} coord;

/* CPU tube locations. */
#define START_TUBE0 0, 11
#define START_TUBE1 0, 13

#define SKP_TUBE0 2, 1
#define SKP_TUBE1 3, 1
#define SKP_TUBE2 4, 1
#define SKP_TUBE3 5, 1

#define IR_TUBE00 2, 3
#define IR_TUBE01 2, 4
#define IR_TUBE02 2, 5
#define IR_TUBE03 2, 6
#define IR_TUBE04 2, 7
#define IR_TUBE05 2, 8
#define IR_TUBE10 3, 3
#define IR_TUBE11 3, 4
#define IR_TUBE12 3, 5
#define IR_TUBE13 3, 6
#define IR_TUBE14 3, 7
#define IR_TUBE15 3, 8
#define IR_TUBE20 4, 3
#define IR_TUBE21 4, 4
#define IR_TUBE22 4, 5
#define IR_TUBE23 4, 6
#define IR_TUBE24 4, 7
#define IR_TUBE25 4, 8
#define IR_TUBE30 5, 3
#define IR_TUBE31 5, 4
#define IR_TUBE32 5, 5
#define IR_TUBE33 5, 6
#define IR_TUBE34 5, 7
#define IR_TUBE35 5, 8

#define IRB_TUBE00 2, 10
#define IRB_TUBE01 2, 11
#define IRB_TUBE10 3, 10
#define IRB_TUBE11 3, 11
#define IRB_TUBE20 4, 10
#define IRB_TUBE21 4, 11
#define IRB_TUBE30 5, 10
#define IRB_TUBE31 5, 11

#define DEC_TUBE00 2, 17
#define DEC_TUBE01 2, 18
#define DEC_TUBE02 2, 19
#define DEC_TUBE03 2, 20
#define DEC_TUBE10 3, 17
#define DEC_TUBE11 3, 18
#define DEC_TUBE12 3, 19
#define DEC_TUBE13 3, 20
#define DEC_TUBE20 4, 17
#define DEC_TUBE21 4, 18
#define DEC_TUBE22 4, 19
#define DEC_TUBE23 4, 20
#define DEC_TUBE30 5, 17
#define DEC_TUBE31 5, 18
#define DEC_TUBE32 5, 19
#define DEC_TUBE33 5, 20

#define DECB_TUBE00 2, 22
#define DECB_TUBE01 2, 23
#define DECB_TUBE02 2, 24
#define DECB_TUBE03 2, 25
#define DECB_TUBE10 3, 22
#define DECB_TUBE11 3, 23
#define DECB_TUBE12 3, 24
#define DECB_TUBE13 3, 25
#define DECB_TUBE20 4, 22
#define DECB_TUBE21 4, 23
#define DECB_TUBE22 4, 24
#define DECB_TUBE23 4, 25
#define DECB_TUBE30 5, 22
#define DECB_TUBE31 5, 23
#define DECB_TUBE32 5, 24
#define DECB_TUBE33 5, 25

#define IENC_TUBE00 7, 3
#define IENC_TUBE01 7, 4
#define IENC_TUBE10 8, 3
#define IENC_TUBE11 8, 4

#define IEDT_TUBE0 7, 9
#define IEDT_TUBE1 7, 10

#define XOR_TUBE00 7, 18
#define XOR_TUBE01 7, 19
#define XOR_TUBE10 8, 18
#define XOR_TUBE11 8, 19

#define GLU1_TUBE0 8, 22
#define GLU1_TUBE1 8, 23
#define GLU1_TUBE2 8, 24
#define GLU1_TUBE3 8, 25

#define IENDFF_TUBE0 9, 9
#define IENDFF_TUBE1 9, 10
#define IENDFF_TUBE2 9, 11
#define IENDFF_TUBE3 9, 12
#define IENDFF_TUBE4 9, 13
#define IENDFF_TUBE5 9, 14

#define CLKC_TUBE00 11, 3
#define CLKC_TUBE01 11, 4
#define CLKC_TUBE10 12, 3
#define CLKC_TUBE11 12, 4

#define RC_TUBE0 16, 3
#define RC_TUBE1 16, 4

#define ADDER_TUBE00 11, 9
#define ADDER_TUBE01 11, 10
#define ADDER_TUBE02 11, 11
#define ADDER_TUBE03 11, 12
#define ADDER_TUBE10 12, 9
#define ADDER_TUBE11 12, 10
#define ADDER_TUBE12 12, 11
#define ADDER_TUBE13 12, 12

#define LOGIC_TUBE00 15, 9
#define LOGIC_TUBE01 15, 10
#define LOGIC_TUBE02 15, 11
#define LOGIC_TUBE03 15, 12
#define LOGIC_TUBE10 16, 9
#define LOGIC_TUBE11 16, 10
#define LOGIC_TUBE12 16, 11
#define LOGIC_TUBE13 16, 12

#define G2_TUBE0 11, 15
#define G2_TUBE1 12, 15
#define G2_TUBE2 13, 15
#define G2_TUBE3 14, 15

#define CARR_TUBE00 11, 19
#define CARR_TUBE01 11, 20
#define CARR_TUBE02 11, 21
#define CARR_TUBE03 11, 22
#define CARR_TUBE10 12, 19
#define CARR_TUBE11 12, 20
#define CARR_TUBE12 12, 21
#define CARR_TUBE13 12, 22

#define RR_TUBE00 15, 18
#define RR_TUBE01 15, 19
#define RR_TUBE02 15, 20
#define RR_TUBE03 15, 21
#define RR_TUBE10 16, 18
#define RR_TUBE11 16, 19
#define RR_TUBE12 16, 20
#define RR_TUBE13 16, 21

#define CRB_TUBE0 12, 25
#define CRB_TUBE1 13, 25

#define RRB_TUBE0 15, 25
#define RRB_TUBE1 16, 25

#define C2_TUBE00 18, 1
#define C2_TUBE01 18, 2
#define C2_TUBE10 19, 1
#define C2_TUBE11 19, 2

#define C1_TUBE00 21, 1
#define C1_TUBE01 21, 2
#define C1_TUBE10 22, 1
#define C1_TUBE11 22, 2

#define S_TUBE0 18, 4
#define S_TUBE1 19, 4

#define O_TUBE0 21, 4
#define O_TUBE1 22, 4

#define SKIP_TUBE0 18, 6
#define SKIP_TUBE1 18, 7
#define SKIP_TUBE2 18, 8
#define SKIP_TUBE3 18, 9
#define SKIP_TUBE4 18, 10
#define SKIP_TUBE5 18, 11

#define OSBS_TUBE0 20, 6
#define OSBS_TUBE1 20, 7
#define OSBS_TUBE2 20, 9
#define OSBS_TUBE3 20, 10

#define OENDFF_TUBE0 22, 6
#define OENDFF_TUBE1 22, 7
#define OENDFF_TUBE2 22, 8
#define OENDFF_TUBE3 22, 9
#define OENDFF_TUBE4 22, 10
#define OENDFF_TUBE5 22, 11

#define WRITE_TUBE00 18, 13
#define WRITE_TUBE01 18, 14
#define WRITE_TUBE02 18, 15
#define WRITE_TUBE03 18, 16
#define WRITE_TUBE04 18, 17
#define WRITE_TUBE05 18, 18
#define WRITE_TUBE10 19, 14
#define WRITE_TUBE11 19, 15
#define WRITE_TUBE12 19, 16
#define WRITE_TUBE13 19, 17

#define M_TUBE0 20, 15
#define M_TUBE1 20, 16
#define M_TUBE2 20, 17
#define M_TUBE3 20, 18

#define FLGF_TUBE00 22, 14
#define FLGF_TUBE01 22, 15
#define FLGF_TUBE02 22, 16
#define FLGF_TUBE03 22, 17
#define FLGF_TUBE10 23, 14
#define FLGF_TUBE11 23, 15
#define FLGF_TUBE12 23, 16
#define FLGF_TUBE13 23, 17

#define OB_TUBE0 18, 20
#define OB_TUBE1 19, 20
#define OB_TUBE2 20, 20
#define OB_TUBE3 21, 20

/* CPU VFD locations. */
#define INST_VFD0 2, 14
#define INST_VFD1 3, 14
#define INST_VFD2 4, 14
#define INST_VFD3 5, 14
#define IV_VFD 7, 14
#define LV_VFD 14, 4
#define CR_VFD 11, 25
#define RR_VFD 14, 25
#define OEN_VFD 20, 8
#define SKIP_VFD 20, 11
#define WRITE_VFD 18, 25
#define FLG0_VFD 19, 25
#define JUMP_VFD 20, 25
#define RETURN_VFD 21, 25
#define FLGF_VFD 22, 25

static void draw_cpu(machine_state *state)
{
  /* Title. */
  MV_ADD_TITLE(state->screen, 0, 36, "UE14500");

  /* Soft start. */
  MV_ADD_TITLE(state->screen, 0, 5, "START");
  ADD_VLINE(state->screen);
  ADD_TUBE(state->screen, START_TUBE0);
  ADD_TUBE(state->screen, START_TUBE1);
  ADD_VLINE(state->screen);

  /* Skip. */
  MV_ADD_TITLE(state->screen, 1, 0, "SKP");
  MV_ADD_VLINE(state->screen, 2, 0);
  ADD_TUBE(state->screen, SKP_TUBE0);
  ADD_VLINE(state->screen);
  MV_ADD_VLINE(state->screen, 3, 0);
  ADD_TUBE(state->screen, SKP_TUBE1);
  ADD_VLINE(state->screen);
  MV_ADD_VLINE(state->screen, 4, 0);
  ADD_TUBE(state->screen, SKP_TUBE2);
  ADD_VLINE(state->screen);
  MV_ADD_VLINE(state->screen, 5, 0);
  ADD_TUBE(state->screen, SKP_TUBE3);
  ADD_VLINE(state->screen);

  /* Instruction register. */
  MV_ADD_HLINE(state->screen, 1, 3);
  ADD_HLINE(state->screen);
  ADD_TITLE(state->screen, "IR");
  ADD_TUBE(state->screen, IR_TUBE00);
  ADD_TUBE(state->screen, IR_TUBE01);
  ADD_TUBE(state->screen, IR_TUBE02);
  ADD_TUBE(state->screen, IR_TUBE03);
  ADD_TUBE(state->screen, IR_TUBE04);
  ADD_TUBE(state->screen, IR_TUBE05);
  ADD_VLINE(state->screen);
  ADD_TUBE(state->screen, IR_TUBE10);
  ADD_TUBE(state->screen, IR_TUBE11);
  ADD_TUBE(state->screen, IR_TUBE12);
  ADD_TUBE(state->screen, IR_TUBE13);
  ADD_TUBE(state->screen, IR_TUBE14);
  ADD_TUBE(state->screen, IR_TUBE15);
  ADD_VLINE(state->screen);
  ADD_TUBE(state->screen, IR_TUBE20);
  ADD_TUBE(state->screen, IR_TUBE21);
  ADD_TUBE(state->screen, IR_TUBE22);
  ADD_TUBE(state->screen, IR_TUBE23);
  ADD_TUBE(state->screen, IR_TUBE24);
  ADD_TUBE(state->screen, IR_TUBE25);
  ADD_VLINE(state->screen);
  ADD_TUBE(state->screen, IR_TUBE30);
  ADD_TUBE(state->screen, IR_TUBE31);
  ADD_TUBE(state->screen, IR_TUBE32);
  ADD_TUBE(state->screen, IR_TUBE33);
  ADD_TUBE(state->screen, IR_TUBE34);
  ADD_TUBE(state->screen, IR_TUBE35);
  ADD_VLINE(state->screen);

  /* Instruction register buffer. */
  MV_ADD_HLINE(state->screen, 1, 7);
  ADD_HLINE(state->screen);
  ADD_TITLE(state->screen, "IRB");
  ADD_TUBE(state->screen, IRB_TUBE00);
  ADD_TUBE(state->screen, IRB_TUBE01);
  ADD_VLINE(state->screen);
  ADD_TUBE(state->screen, IRB_TUBE10);
  ADD_TUBE(state->screen, IRB_TUBE11);
  ADD_VLINE(state->screen);
  ADD_TUBE(state->screen, IRB_TUBE20);
  ADD_TUBE(state->screen, IRB_TUBE21);
  ADD_VLINE(state->screen);
  ADD_TUBE(state->screen, IRB_TUBE30);
  ADD_TUBE(state->screen, IRB_TUBE31);
  ADD_VLINE(state->screen);

  /* Instruction VFDs. */
  MV_ADD_HLINE(state->screen, 1, 12);
  ADD_TITLE(state->screen, "INST");
  ADD_VFD(state->screen, INST_VFD0);
  ADD_VFD(state->screen, INST_VFD1);
  ADD_VFD(state->screen, INST_VFD2);
  ADD_VFD(state->screen, INST_VFD3);

  /* Instruction register decoder. */
  MV_ADD_HLINE(state->screen, 1, 17);
  ADD_TITLE(state->screen, "DEC");
  MV_ADD_VLINE(state->screen, 2, 16);
  ADD_TUBE(state->screen, DEC_TUBE00);
  ADD_TUBE(state->screen, DEC_TUBE01);
  ADD_TUBE(state->screen, DEC_TUBE02);
  ADD_TUBE(state->screen, DEC_TUBE03);
  ADD_VLINE(state->screen);
  MV_ADD_VLINE(state->screen, 3, 16);
  ADD_TUBE(state->screen, DEC_TUBE10);
  ADD_TUBE(state->screen, DEC_TUBE11);
  ADD_TUBE(state->screen, DEC_TUBE12);
  ADD_TUBE(state->screen, DEC_TUBE13);
  ADD_VLINE(state->screen);
  MV_ADD_VLINE(state->screen, 4, 16);
  ADD_TUBE(state->screen, DEC_TUBE20);
  ADD_TUBE(state->screen, DEC_TUBE21);
  ADD_TUBE(state->screen, DEC_TUBE22);
  ADD_TUBE(state->screen, DEC_TUBE23);
  ADD_VLINE(state->screen);
  MV_ADD_VLINE(state->screen, 5, 16);
  ADD_TUBE(state->screen, DEC_TUBE30);
  ADD_TUBE(state->screen, DEC_TUBE31);
  ADD_TUBE(state->screen, DEC_TUBE32);
  ADD_TUBE(state->screen, DEC_TUBE33);
  ADD_VLINE(state->screen);

  /* Instruction register decoder buffers. */
  MV_ADD_HLINE(state->screen, 1, 21);
  ADD_TITLE(state->screen, "DECB");
  ADD_TUBE(state->screen, DECB_TUBE00);
  ADD_TUBE(state->screen, DECB_TUBE01);
  ADD_TUBE(state->screen, DECB_TUBE02);
  ADD_TUBE(state->screen, DECB_TUBE03);
  ADD_VLINE(state->screen);
  ADD_TUBE(state->screen, DECB_TUBE10);
  ADD_TUBE(state->screen, DECB_TUBE11);
  ADD_TUBE(state->screen, DECB_TUBE12);
  ADD_TUBE(state->screen, DECB_TUBE13);
  ADD_VLINE(state->screen);
  ADD_TUBE(state->screen, DECB_TUBE20);
  ADD_TUBE(state->screen, DECB_TUBE21);
  ADD_TUBE(state->screen, DECB_TUBE22);
  ADD_TUBE(state->screen, DECB_TUBE23);
  ADD_VLINE(state->screen);
  ADD_TUBE(state->screen, DECB_TUBE30);
  ADD_TUBE(state->screen, DECB_TUBE31);
  ADD_TUBE(state->screen, DECB_TUBE32);
  ADD_TUBE(state->screen, DECB_TUBE33);
  ADD_VLINE(state->screen);

  /* Divider. */
  MV_ADD_LTEE(state->screen, 6, 0);
  ADD_HLINE(state->screen);
  ADD_TITLE(state->screen, "IENC");
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_TITLE(state->screen, "IEDT");
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_TITLE(state->screen, "IV");
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_TITLE(state->screen, "XOR");
  ADD_HLINE(state->screen);
  ADD_TITLE(state->screen, "GLU1");
  ADD_RTEE(state->screen);

  /* Input enable control. */
  MV_ADD_VLINE(state->screen, 7, 0);
  ADD_TUBE(state->screen, IENC_TUBE00);
  ADD_TUBE(state->screen, IENC_TUBE01);
  MV_ADD_VLINE(state->screen, 8, 0);
  ADD_TUBE(state->screen, IENC_TUBE10);
  ADD_TUBE(state->screen, IENC_TUBE11);
  MV_ADD_VLINE(state->screen, 9, 0);

  /* Input enable display tubes. */
  MV_ADD_VLINE(state->screen, 7, 6);
  ADD_TUBE(state->screen, IEDT_TUBE0);
  ADD_TUBE(state->screen, IEDT_TUBE1);

  /* Input enable display VFD. */
  MV_ADD_VLINE(state->screen, 7, 12);
  ADD_VFD(state->screen, IV_VFD);

  /* XOR. */
  MV_ADD_VLINE(state->screen, 7, 17);
  ADD_TUBE(state->screen, XOR_TUBE00);
  ADD_TUBE(state->screen, XOR_TUBE01);
  ADD_TUBE(state->screen, XOR_TUBE10);
  ADD_TUBE(state->screen, XOR_TUBE11);
  MV_ADD_VLINE(state->screen, 9, 17);

  /* Glue 1. */
  MV_ADD_VLINE(state->screen, 7, 21);
  MV_ADD_VLINE(state->screen, 7, 26);
  MV_ADD_VLINE(state->screen, 8, 21);
  ADD_TUBE(state->screen, GLU1_TUBE0);
  ADD_TUBE(state->screen, GLU1_TUBE1);
  ADD_TUBE(state->screen, GLU1_TUBE2);
  ADD_TUBE(state->screen, GLU1_TUBE3);
  ADD_VLINE(state->screen);
  MV_ADD_VLINE(state->screen, 9, 21);
  MV_ADD_VLINE(state->screen, 9, 26);

  /* Input enable D flip-flop. */
  MV_ADD_LTEE(state->screen, 8, 6);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_TITLE(state->screen, "IENDFF");
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_RTEE(state->screen);
  MV_ADD_VLINE(state->screen, 9, 6);
  ADD_TUBE(state->screen, IENDFF_TUBE0);
  ADD_TUBE(state->screen, IENDFF_TUBE1);
  ADD_TUBE(state->screen, IENDFF_TUBE2);
  ADD_TUBE(state->screen, IENDFF_TUBE3);
  ADD_TUBE(state->screen, IENDFF_TUBE4);
  ADD_TUBE(state->screen, IENDFF_TUBE5);

  /* Divider. */
  MV_ADD_LTEE(state->screen, 10, 0);
  ADD_HLINE(state->screen);
  ADD_TITLE(state->screen, "CLKC");
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_TITLE(state->screen, "ADDER");
  ADD_HLINE(state->screen);
  ADD_TITLE(state->screen, "G2");
  ADD_HLINE(state->screen);
  ADD_TITLE(state->screen, "CARR");
  ADD_HLINE(state->screen);
  ADD_TITLE(state->screen, "CRB");
  ADD_RTEE(state->screen);

  /* Clock control. */
  MV_ADD_VLINE(state->screen, 11, 0);
  ADD_TUBE(state->screen, CLKC_TUBE00);
  ADD_TUBE(state->screen, CLKC_TUBE01);
  MV_ADD_VLINE(state->screen, 12, 0);
  ADD_TUBE(state->screen, CLKC_TUBE10);
  ADD_TUBE(state->screen, CLKC_TUBE11);

  /* Logic unit VFD. */
  MV_ADD_LTEE(state->screen, 13, 0);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_TITLE(state->screen, "LV");
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_RTEE(state->screen);
  MV_ADD_VLINE(state->screen, 14, 0);
  ADD_VFD(state->screen, LV_VFD);

  /* Result register input control. */
  MV_ADD_LTEE(state->screen, 15, 0);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_TITLE(state->screen, "RC");
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_RTEE(state->screen);
  MV_ADD_VLINE(state->screen, 16, 0);
  ADD_TUBE(state->screen, RC_TUBE0);
  ADD_TUBE(state->screen, RC_TUBE1);

  /* Adder. */
  MV_ADD_VLINE(state->screen, 11, 8);
  ADD_TUBE(state->screen, ADDER_TUBE00);
  ADD_TUBE(state->screen, ADDER_TUBE01);
  ADD_TUBE(state->screen, ADDER_TUBE02);
  ADD_TUBE(state->screen, ADDER_TUBE03);
  MV_ADD_VLINE(state->screen, 12, 8);
  ADD_TUBE(state->screen, ADDER_TUBE10);
  ADD_TUBE(state->screen, ADDER_TUBE11);
  ADD_TUBE(state->screen, ADDER_TUBE12);
  ADD_TUBE(state->screen, ADDER_TUBE13);

  /* Logic unit. */
  MV_ADD_VLINE(state->screen, 14, 8);
  ADD_TITLE(state->screen, "LOGIC");
  MV_ADD_VLINE(state->screen, 15, 8);
  ADD_TUBE(state->screen, LOGIC_TUBE00);
  ADD_TUBE(state->screen, LOGIC_TUBE01);
  ADD_TUBE(state->screen, LOGIC_TUBE02);
  ADD_TUBE(state->screen, LOGIC_TUBE03);
  MV_ADD_VLINE(state->screen, 16, 8);
  ADD_TUBE(state->screen, LOGIC_TUBE10);
  ADD_TUBE(state->screen, LOGIC_TUBE11);
  ADD_TUBE(state->screen, LOGIC_TUBE12);
  ADD_TUBE(state->screen, LOGIC_TUBE13);

  /* Glue logic. */
  MV_ADD_VLINE(state->screen, 11, 14);
  ADD_TUBE(state->screen, G2_TUBE0);
  MV_ADD_VLINE(state->screen, 12, 14);
  ADD_TUBE(state->screen, G2_TUBE1);
  MV_ADD_VLINE(state->screen, 13, 14);
  ADD_TUBE(state->screen, G2_TUBE2);
  MV_ADD_VLINE(state->screen, 14, 14);
  ADD_TUBE(state->screen, G2_TUBE3);
  MV_ADD_VLINE(state->screen, 15, 14);
  MV_ADD_VLINE(state->screen, 16, 14);

  /* Carry register. */
  MV_ADD_VLINE(state->screen, 11, 17);
  ADD_TUBE(state->screen, CARR_TUBE00);
  ADD_TUBE(state->screen, CARR_TUBE01);
  ADD_TUBE(state->screen, CARR_TUBE02);
  ADD_TUBE(state->screen, CARR_TUBE03);
  MV_ADD_VLINE(state->screen, 12, 17);
  ADD_TUBE(state->screen, CARR_TUBE10);
  ADD_TUBE(state->screen, CARR_TUBE11);
  ADD_TUBE(state->screen, CARR_TUBE12);
  ADD_TUBE(state->screen, CARR_TUBE13);

  /* Results register. */
  MV_ADD_LTEE(state->screen, 13, 17);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_RTEE(state->screen);
  MV_ADD_LTEE(state->screen, 14, 17);
  ADD_HLINE(state->screen);
  ADD_TITLE(state->screen, "RR");
  ADD_HLINE(state->screen);
  MV_ADD_VLINE(state->screen, 15, 17);
  ADD_TUBE(state->screen, RR_TUBE00);
  ADD_TUBE(state->screen, RR_TUBE01);
  ADD_TUBE(state->screen, RR_TUBE02);
  ADD_TUBE(state->screen, RR_TUBE03);
  MV_ADD_VLINE(state->screen, 16, 17);
  ADD_TUBE(state->screen, RR_TUBE10);
  ADD_TUBE(state->screen, RR_TUBE11);
  ADD_TUBE(state->screen, RR_TUBE12);
  ADD_TUBE(state->screen, RR_TUBE13);

  /* Carry register buffers. */
  MV_ADD_VLINE(state->screen, 11, 24);
  ADD_VFD(state->screen, CR_VFD);
  ADD_VLINE(state->screen);
  MV_ADD_VLINE(state->screen, 12, 24);
  ADD_TUBE(state->screen, CRB_TUBE0);
  ADD_VLINE(state->screen);
  MV_ADD_VLINE(state->screen, 13, 24);
  ADD_TUBE(state->screen, CRB_TUBE1);
  ADD_VLINE(state->screen);

  /* Results register buffers. */
  MV_ADD_RTEE(state->screen, 14, 22);
  ADD_TITLE(state->screen, "R");
  ADD_VLINE(state->screen);
  ADD_VFD(state->screen, RR_VFD);
  ADD_VLINE(state->screen);
  MV_ADD_VLINE(state->screen, 15, 22);
  ADD_TITLE(state->screen, "R");
  ADD_VLINE(state->screen);
  ADD_TUBE(state->screen, RRB_TUBE0);
  ADD_VLINE(state->screen);
  MV_ADD_VLINE(state->screen, 16, 22);
  ADD_TITLE(state->screen, "B");
  ADD_VLINE(state->screen);
  ADD_TUBE(state->screen, RRB_TUBE1);
  ADD_VLINE(state->screen);

  /* Divider. */
  MV_ADD_LTEE(state->screen, 17, 0);
  ADD_TITLE(state->screen, "C2");
  ADD_HLINE(state->screen);
  ADD_TITLE(state->screen, "S");
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_TITLE(state->screen, "SKIP");
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_TITLE(state->screen, "WRITE");
  ADD_HLINE(state->screen);
  ADD_TITLE(state->screen, "OB");
  ADD_HLINE(state->screen);
  ADD_TITLE(state->screen, "OVFD");
  ADD_RTEE(state->screen);

  /* Clock 2. */
  MV_ADD_VLINE(state->screen, 18, 0);
  ADD_TUBE(state->screen, C2_TUBE00);
  ADD_TUBE(state->screen, C2_TUBE01);
  MV_ADD_VLINE(state->screen, 19, 0);
  ADD_TUBE(state->screen, C2_TUBE10);
  ADD_TUBE(state->screen, C2_TUBE11);

  /* Clock 1. */
  MV_ADD_LTEE(state->screen, 20, 0);
  ADD_TITLE(state->screen, "C1");
  MV_ADD_VLINE(state->screen, 21, 0);
  ADD_TUBE(state->screen, C1_TUBE00);
  ADD_TUBE(state->screen, C1_TUBE01);
  MV_ADD_VLINE(state->screen, 22, 0);
  ADD_TUBE(state->screen, C1_TUBE10);
  ADD_TUBE(state->screen, C1_TUBE11);

  /* Skip control. */
  MV_ADD_VLINE(state->screen, 18, 3);
  ADD_TUBE(state->screen, S_TUBE0);
  MV_ADD_VLINE(state->screen, 19, 3);
  ADD_TUBE(state->screen, S_TUBE1);

  /* Output enable control. */
  MV_ADD_HLINE(state->screen, 20, 3);
  ADD_TITLE(state->screen, "O");
  MV_ADD_VLINE(state->screen, 21, 3);
  ADD_TUBE(state->screen, O_TUBE0);
  MV_ADD_VLINE(state->screen, 22, 3);
  ADD_TUBE(state->screen, O_TUBE1);

  /* Skip register. */
  MV_ADD_VLINE(state->screen, 18, 5);
  ADD_TUBE(state->screen, SKIP_TUBE0);
  ADD_TUBE(state->screen, SKIP_TUBE1);
  ADD_TUBE(state->screen, SKIP_TUBE2);
  ADD_TUBE(state->screen, SKIP_TUBE3);
  ADD_TUBE(state->screen, SKIP_TUBE4);
  ADD_TUBE(state->screen, SKIP_TUBE5);

  /* OEN/SKIP register buffers and VFDs. */
  MV_ADD_LTEE(state->screen, 19, 5);
  ADD_HLINE(state->screen);
  ADD_TITLE(state->screen, "OSBS");
  ADD_HLINE(state->screen);
  ADD_RTEE(state->screen);
  MV_ADD_VLINE(state->screen, 20, 5);
  ADD_TUBE(state->screen, OSBS_TUBE0);
  ADD_TUBE(state->screen, OSBS_TUBE1);
  ADD_VFD(state->screen, OEN_VFD);
  ADD_TUBE(state->screen, OSBS_TUBE2);
  ADD_TUBE(state->screen, OSBS_TUBE3);
  ADD_VFD(state->screen, SKIP_VFD);

  /* Output enable register. */
  MV_ADD_VLINE(state->screen, 21, 5);
  ADD_TITLE(state->screen, "OENDFF");
  MV_ADD_VLINE(state->screen, 22, 5);
  ADD_TUBE(state->screen, OENDFF_TUBE0);
  ADD_TUBE(state->screen, OENDFF_TUBE1);
  ADD_TUBE(state->screen, OENDFF_TUBE2);
  ADD_TUBE(state->screen, OENDFF_TUBE3);
  ADD_TUBE(state->screen, OENDFF_TUBE4);
  ADD_TUBE(state->screen, OENDFF_TUBE5);

  /* Write board. */
  MV_ADD_VLINE(state->screen, 18, 12);
  ADD_TUBE(state->screen, WRITE_TUBE00);
  ADD_TUBE(state->screen, WRITE_TUBE01);
  ADD_TUBE(state->screen, WRITE_TUBE02);
  ADD_TUBE(state->screen, WRITE_TUBE03);
  ADD_TUBE(state->screen, WRITE_TUBE04);
  ADD_TUBE(state->screen, WRITE_TUBE05);
  MV_ADD_VLINE(state->screen, 19, 12);
  ADD_TUBE(state->screen, WRITE_TUBE10);
  ADD_TUBE(state->screen, WRITE_TUBE11);
  ADD_TUBE(state->screen, WRITE_TUBE12);
  ADD_TUBE(state->screen, WRITE_TUBE13);

  /* Multiplexer. */
  MV_ADD_VLINE(state->screen, 20, 12);
  ADD_TITLE(state->screen, "M");
  ADD_VLINE(state->screen);
  ADD_TUBE(state->screen, M_TUBE0);
  ADD_TUBE(state->screen, M_TUBE1);
  ADD_TUBE(state->screen, M_TUBE2);
  ADD_TUBE(state->screen, M_TUBE3);

  /* Flag F. */
  MV_ADD_LTEE(state->screen, 21, 12);
  ADD_HLINE(state->screen);
  ADD_TITLE(state->screen, "FLGF");
  ADD_HLINE(state->screen);
  MV_ADD_VLINE(state->screen, 22, 12);
  ADD_TUBE(state->screen, FLGF_TUBE00);
  ADD_TUBE(state->screen, FLGF_TUBE01);
  ADD_TUBE(state->screen, FLGF_TUBE02);
  ADD_TUBE(state->screen, FLGF_TUBE03);
  MV_ADD_VLINE(state->screen, 23, 12);
  ADD_TUBE(state->screen, FLGF_TUBE10);
  ADD_TUBE(state->screen, FLGF_TUBE11);
  ADD_TUBE(state->screen, FLGF_TUBE12);
  ADD_TUBE(state->screen, FLGF_TUBE13);

  /* Output buffers. */
  MV_ADD_VLINE(state->screen, 18, 19);
  ADD_TUBE(state->screen, OB_TUBE0);
  MV_ADD_VLINE(state->screen, 19, 19);
  ADD_TUBE(state->screen, OB_TUBE1);
  MV_ADD_VLINE(state->screen, 20, 19);
  ADD_TUBE(state->screen, OB_TUBE2);
  MV_ADD_VLINE(state->screen, 21, 19);
  ADD_TUBE(state->screen, OB_TUBE3);
  MV_ADD_VLINE(state->screen, 22, 19);
  MV_ADD_VLINE(state->screen, 23, 19);

  /* Output VFDs. */
  MV_ADD_VLINE(state->screen, 18, 21);
  ADD_TITLE(state->screen, "W");
  ADD_VLINE(state->screen);
  ADD_VFD(state->screen, WRITE_VFD);
  ADD_VLINE(state->screen);
  MV_ADD_VLINE(state->screen, 19, 21);
  ADD_TITLE(state->screen, "0");
  ADD_VLINE(state->screen);
  ADD_VFD(state->screen, FLG0_VFD);
  ADD_VLINE(state->screen);
  MV_ADD_VLINE(state->screen, 20, 21);
  ADD_TITLE(state->screen, "J");
  ADD_VLINE(state->screen);
  ADD_VFD(state->screen, JUMP_VFD);
  ADD_VLINE(state->screen);
  MV_ADD_VLINE(state->screen, 21, 21);
  ADD_TITLE(state->screen, "R");
  ADD_VLINE(state->screen);
  ADD_VFD(state->screen, RETURN_VFD);
  ADD_VLINE(state->screen);
  MV_ADD_VLINE(state->screen, 22, 21);
  ADD_TITLE(state->screen, "F");
  ADD_VLINE(state->screen);
  ADD_VFD(state->screen, FLGF_VFD);
  ADD_VLINE(state->screen);
}

/* Remote VFD locations. */
#define REMOTE_DATA_VFD 16, 29
#define REMOTE_RR_VFD 16, 31
#define REMOTE_WRITE_VFD 16, 33
#define REMOTE_FLG0_VFD 16, 35
#define REMOTE_JUMP_VFD 16, 37
#define REMOTE_RETURN_VFD 16, 39
#define REMOTE_FLGF_VFD 16, 41
#define REMOTE_I3_VFD 17, 29
#define REMOTE_I2_VFD 17, 31
#define REMOTE_I1_VFD 17, 33
#define REMOTE_I0_VFD 17, 35
#define REMOTE_D_VFD 17, 39
#define REMOTE_C_VFD 17, 41

/* Remote input controls. */
#define REMOTE_POINTER 23
#define REMOTE_I3_1 21, 29
#define REMOTE_I3_0 22, 29
#define REMOTE_I3_P REMOTE_POINTER, 29
#define REMOTE_I2_1 21, 31
#define REMOTE_I2_0 22, 31
#define REMOTE_I2_P REMOTE_POINTER, 31
#define REMOTE_I1_1 21, 33
#define REMOTE_I1_0 22, 33
#define REMOTE_I1_P REMOTE_POINTER, 33
#define REMOTE_I0_1 21, 35
#define REMOTE_I0_0 22, 35
#define REMOTE_I0_P REMOTE_POINTER, 35
#define REMOTE_D_1 21, 38
#define REMOTE_D_0 22, 38
#define REMOTE_D_P REMOTE_POINTER, 38
#define REMOTE_CLK_C 20, 41
#define REMOTE_CLK_L 21, 41
#define REMOTE_CLK_K 22, 41
#define REMOTE_CLK_P REMOTE_POINTER, 41

/* Location indexes. */
typedef enum bc_indexes_
{
  bci_0,
  bci_1,
  bci_pointer,
  bci_vfd
} bc_indexes;

/* Binary control 0, 1, pointer, and VFD location. */
static const coord binary_controls[num_controls][4] =
{
  { {REMOTE_I3_0}, {REMOTE_I3_1}, {REMOTE_I3_P}, {REMOTE_I3_VFD} },
  { {REMOTE_I2_0}, {REMOTE_I2_1}, {REMOTE_I2_P}, {REMOTE_I2_VFD} },
  { {REMOTE_I1_0}, {REMOTE_I1_1}, {REMOTE_I1_P}, {REMOTE_I1_VFD} },
  { {REMOTE_I0_0}, {REMOTE_I0_1}, {REMOTE_I0_P}, {REMOTE_I0_VFD} },
  { {REMOTE_D_0}, {REMOTE_D_1}, {REMOTE_D_P}, {REMOTE_D_VFD} },
  { { 0, 0 }, { 0, 0 }, {REMOTE_CLK_P}, {REMOTE_C_VFD} }
};

static void draw_remote(machine_state *state)
{
  /* Title. */
  MV_ADD_UL(state->screen, 14, 28);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_TITLE(state->screen, "REMOTE");
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_UR(state->screen);

  /* Output VFD titles. */
  MV_ADD_VLINE(state->screen, 15, 28);
  ADD_TITLE(state->screen, "D R W 0 J R F");
  ADD_VLINE(state->screen);

  /* Output VFDs. */
  MV_ADD_VLINE(state->screen, 16, 28);
  ADD_VFD(state->screen, REMOTE_DATA_VFD);
  ADD_VFD(state->screen, REMOTE_RR_VFD);
  ADD_VFD(state->screen, REMOTE_WRITE_VFD);
  ADD_VFD(state->screen, REMOTE_FLG0_VFD);
  ADD_VFD(state->screen, REMOTE_JUMP_VFD);
  ADD_VFD(state->screen, REMOTE_RETURN_VFD);
  ADD_VFD(state->screen, REMOTE_FLGF_VFD);
  ADD_VLINE(state->screen);

  /* Input VFDs. */
  MV_ADD_VLINE(state->screen, 17, 28);
  ADD_VFD(state->screen, REMOTE_I3_VFD);
  ADD_VFD(state->screen, REMOTE_I2_VFD);
  ADD_VFD(state->screen, REMOTE_I1_VFD);
  ADD_VFD(state->screen, REMOTE_I0_VFD);
  ADD_VFD(state->screen, REMOTE_D_VFD);
  ADD_VFD(state->screen, REMOTE_C_VFD);
  ADD_VLINE(state->screen);

  /* Input VFD titles. */
  MV_ADD_VLINE(state->screen, 18, 28);
  ADD_TITLE(state->screen, "I I I I   D C");
  ADD_VLINE(state->screen);
  MV_ADD_VLINE(state->screen, 19, 28);
  ADD_TITLE(state->screen, "3 2 1 0      ");
  ADD_VLINE(state->screen);

  /* Input controls. */
  MV_ADD_VLINE(state->screen, 20, 28);
  ADD_TITLE(state->screen, " INST    D");
  ADD_INPUT(state->screen, REMOTE_CLK_C, 'C');
  ADD_VLINE(state->screen);
  MV_ADD_VLINE(state->screen, 21, 28);
  ADD_INPUT(state->screen, REMOTE_I3_1, '1');
  ADD_INPUT(state->screen, REMOTE_I2_1, '1');
  ADD_INPUT(state->screen, REMOTE_I1_1, '1');
  ADD_INPUT(state->screen, REMOTE_I0_1, '1');
  ADD_INPUT(state->screen, REMOTE_D_1, '1');
  ADD_INPUT(state->screen, REMOTE_CLK_L, 'L');
  ADD_VLINE(state->screen);
  MV_ADD_VLINE(state->screen, 22, 28);
  ADD_INPUT(state->screen, REMOTE_I3_0, '0');
  ADD_INPUT(state->screen, REMOTE_I2_0, '0');
  ADD_INPUT(state->screen, REMOTE_I1_0, '0');
  ADD_INPUT(state->screen, REMOTE_I0_0, '0');
  ADD_INPUT(state->screen, REMOTE_D_0, '0');
  ADD_INPUT(state->screen, REMOTE_CLK_K, 'K');
  ADD_VLINE(state->screen);

  /* Bottom border. */
  MV_ADD_LL(state->screen, 23, 28);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_LR(state->screen);
}

/* Set the status. */
#define STATUS_Y 9
#define STATUS_X 54
#define SET_STATUS(win, status)                                      \
  mvwaddstr((win), STATUS_Y, STATUS_X, "                         "); \
  mvwaddstr((win), STATUS_Y, STATUS_X, (status));                    \
  wrefresh(win)

static void draw_status(machine_state *state)
{
  /* Title. */
  MV_ADD_UL(state->screen, 8, 53);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_TITLE(state->screen, "STATUS");
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_UR(state->screen);

  /* Left/right border. */
  MV_ADD_VLINE(state->screen, 9, 53);
  MV_ADD_VLINE(state->screen, 9, 79);

  /* Bottom border. */
  MV_ADD_LL(state->screen, 10, 53);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_HLINE(state->screen);
  ADD_LR(state->screen);
}

static void draw_help(machine_state *state)
{
  mvwaddstr(state->screen, 1, 28,
            ".: tube, v: VFD off, V: VFD on");
  mvwaddstr(state->screen, 2, 28,
            "INST: instruction register VFDs");
  mvwaddstr(state->screen, 3, 28,
            "IV: IEN VFD");
  mvwaddstr(state->screen, 4, 28,
            "CRB: carry register buffer VFD");
  mvwaddstr(state->screen, 5, 28,
            "RR: results register VFD");
  mvwaddstr(state->screen, 6, 28,
            "LV: logic unit VFD");
  mvwaddstr(state->screen, 7, 28,
            "OSBS: OEN/SKIP VFDs");
  mvwaddstr(state->screen, 8, 28,
            "W: write VFD");
  mvwaddstr(state->screen, 9, 28,
            "0: flag 0 VFD");
  mvwaddstr(state->screen, 10, 28,
            "J: jump flag VFD");
  mvwaddstr(state->screen, 11, 28,
            "R: return flag VFD");
  mvwaddstr(state->screen, 12, 28,
            "F: flag f VFD");
  mvwaddstr(state->screen, 14, 44,
            "D: data, R: result register");
  mvwaddstr(state->screen, 15, 44,
            "W: write, 0: flag 0, J: jump");
  mvwaddstr(state->screen, 16, 44,
            "R: return, F: flag f");
  mvwaddstr(state->screen, 17, 44,
            "IIII: instruction");
  mvwaddstr(state->screen, 18, 44,
            "D: data ext. input, C: clock");
  mvwaddstr(state->screen, 20, 44,
            "Q to quit.");
  mvwaddstr(state->screen, 21, 44,
            "Clock toggles high/low separately.");
  mvwaddstr(state->screen, 22, 44,
            "Arrows/space/return/enter toggle.");
  mvwaddstr(state->screen, 23, 44,
            "Arrows/h/l/tab/F1-F6 move cursor.");
}

static void power_on(machine_state *state)
{
  int ch;

  /* Instruction registers. */
  state->ir = i_nop0;
  SET_STATUS(state->screen, "Press a key to init INST0");
  ch = get_input(state);
  if (ch & 1)
  {
    state->ir |= i_ld;
    VFD_ON(state->screen, INST_VFD0);
  }
  else
  {
    VFD_OFF(state->screen, INST_VFD0);
  }
  SET_STATUS(state->screen, "Press a key to init INST1");
  ch = get_input(state);
  if (ch & 1)
  {
    state->ir |= i_add;
    VFD_ON(state->screen, INST_VFD1);
  }
  else
  {
    VFD_OFF(state->screen, INST_VFD1);
  }
  SET_STATUS(state->screen, "Press a key to init INST2");
  ch = get_input(state);
  if (ch & 1)
  {
    state->ir |= i_one;
    VFD_ON(state->screen, INST_VFD2);
  }
  else
  {
    VFD_OFF(state->screen, INST_VFD2);
  }
  SET_STATUS(state->screen, "Press a key to init INST3");
  ch = get_input(state);
  if (ch & 1)
  {
    state->ir |= i_sto;
    VFD_ON(state->screen, INST_VFD3);
  }
  else
  {
    VFD_OFF(state->screen, INST_VFD3);
  }

  /* Input enable. */
  SET_STATUS(state->screen, "Press a key to init IEN");
  state->ien = get_input(state) & 1;
  if (state->ien)
  {
    VFD_ON(state->screen, IV_VFD);
  }
  else
  {
    VFD_OFF(state->screen, IV_VFD);
  }

  /* Logic unit. */
  SET_STATUS(state->screen, "Press a key to init LOGIC");
  ch = get_input(state);
  if (ch & 1)
  {
    VFD_ON(state->screen, LV_VFD);
  }
  else
  {
    VFD_OFF(state->screen, LV_VFD);
  }

  /* Carry register. */
  SET_STATUS(state->screen, "Press a key to init CARRY");
  state->cr = get_input(state) & 1;
  if (state->cr)
  {
    VFD_ON(state->screen, CR_VFD);
  }
  else
  {
    VFD_OFF(state->screen, CR_VFD);
  }

  /* Results register. */
  SET_STATUS(state->screen, "Press a key to init RR");
  state->rr = get_input(state) & 1;
  if (state->rr)
  {
    VFD_ON(state->screen, RR_VFD);
  }
  else
  {
    VFD_OFF(state->screen, RR_VFD);
  }

  /* Output enable. */
  SET_STATUS(state->screen, "Press a key to init OEN");
  state->oen = get_input(state) & 1;
  if (state->oen)
  {
    VFD_ON(state->screen, OEN_VFD);
  }
  else
  {
    VFD_OFF(state->screen, OEN_VFD);
  }

  /* Skip register. */
  SET_STATUS(state->screen, "Press a key to init SKIP");
  state->skip = get_input(state) & 1;
  if (state->skip)
  {
    VFD_ON(state->screen, SKIP_VFD);
  }
  else
  {
    VFD_OFF(state->screen, SKIP_VFD);
  }

  /* Outputs power up off. Except RR, which matches RR above. */
  VFD_OFF(state->screen, REMOTE_DATA_VFD);
  if (state->rr)
  {
    VFD_ON(state->screen, REMOTE_RR_VFD);
  }
  else
  {
    VFD_OFF(state->screen, REMOTE_RR_VFD);
  }
  VFD_OFF(state->screen, WRITE_VFD);
  VFD_OFF(state->screen, REMOTE_WRITE_VFD);
  VFD_OFF(state->screen, FLG0_VFD);
  VFD_OFF(state->screen, REMOTE_FLG0_VFD);
  VFD_OFF(state->screen, JUMP_VFD);
  VFD_OFF(state->screen, REMOTE_JUMP_VFD);
  VFD_OFF(state->screen, RETURN_VFD);
  VFD_OFF(state->screen, REMOTE_RETURN_VFD);
  VFD_OFF(state->screen, FLGF_VFD);
  VFD_OFF(state->screen, REMOTE_FLGF_VFD);

  /* Inputs power up off. */
  VFD_OFF(state->screen, REMOTE_I3_VFD);
  VFD_OFF(state->screen, REMOTE_I2_VFD);
  VFD_OFF(state->screen, REMOTE_I1_VFD);
  VFD_OFF(state->screen, REMOTE_I0_VFD);
  VFD_OFF(state->screen, REMOTE_D_VFD);
  VFD_OFF(state->screen, REMOTE_C_VFD);

  /* Input controls all zero. */
  state->control_states[c_i3] = bci_0;
  CONTROL_ON_YX(state->screen,
             binary_controls[c_i3][bci_0].y, binary_controls[c_i3][bci_0].x);
  state->control_states[c_i2] = bci_0;
  CONTROL_ON_YX(state->screen,
             binary_controls[c_i2][bci_0].y, binary_controls[c_i2][bci_0].x);
  state->control_states[c_i1] = bci_0;
  CONTROL_ON_YX(state->screen,
             binary_controls[c_i1][bci_0].y, binary_controls[c_i1][bci_0].x);
  state->control_states[c_i0] = bci_0;
  CONTROL_ON_YX(state->screen,
             binary_controls[c_i0][bci_0].y, binary_controls[c_i0][bci_0].x);
  state->control_states[c_d] = bci_0;
  CONTROL_ON_YX(state->screen,
             binary_controls[c_d][bci_0].y, binary_controls[c_d][bci_0].x);
  state->control_states[c_clk] = bci_0;
  SET_STATUS(state->screen, instructions[GET_INSTR(state)]);

  /* Cursor starts at I3. */
  state->control = c_i3;
  POINTER_ON(state->screen,
             binary_controls[c_i3][bci_pointer].y,
             binary_controls[c_i3][bci_pointer].x);

  /* Read the rest of the current line if reading from a file. */
  if (state->in_file != NULL)
  {
    while (get_input(state) != '\n')
    { }
  }
}

static void main_loop(machine_state *state)
{
  int ch;
  int done = 0;

  while (!done)
  {
    /* Get the next input character. */
    ch = get_input(state);

    /* Handle the input. */
    switch (ch)
    {
      case 'h':
      case 'H':
      case KEY_LEFT:
        /* Select the control to the left, wrapping around. */
        if (state->control == c_i3)
        {
          select_control(state, c_clk);
        }
        else
        {
          select_control(state, state->control - 1);
        }
        break;

      case '\t':
      case 'l':
      case 'L':
      case KEY_RIGHT:
        /* Select the control to the right, wrapping around. */
        if (state->control == c_clk)
        {
          select_control(state, c_i3);
        }
        else
        {
          select_control(state, state->control + 1);
        }
        break;

      case KEY_F(1):
        /* Select the instruction 3 control. */
        select_control(state, c_i3);
        break;

      case KEY_F(2):
        /* Select the instruction 2 control. */
        select_control(state, c_i2);
        break;

      case KEY_F(3):
        /* Select the instruction 1 control. */
        select_control(state, c_i1);
        break;

      case KEY_F(4):
        /* Select the instruction 0 control. */
        select_control(state, c_i0);
        break;

      case KEY_F(5):
        /* Select the data control. */
        select_control(state, c_d);
        break;

      case 'c':
      case 'C':
      case KEY_F(6):
        /* Select the clock control. */
        select_control(state, c_clk);
        break;

      case '\r':
      case '\n':
      case ' ':
      case 't':
      case 'T':
      case KEY_ENTER:
      case KEY_UP:
      case KEY_DOWN:
        /* Toggle the current control. */
        if (state->control == c_clk)
        {
          toggle_clock(state);
        }
        else
        {
          toggle_control(state);
        }
        break;

      case '0':
        /* Set I0 off. */
        select_control(state, c_i0);
        if (state->control_states[c_i0] != 0)
        {
          toggle_control(state);
        }
        break;

      case '1':
        /* Set I1 off. */
        select_control(state, c_i1);
        if (state->control_states[c_i1] != 0)
        {
          toggle_control(state);
        }
        break;

      case '2':
        /* Set I2 off. */
        select_control(state, c_i2);
        if (state->control_states[c_i2] != 0)
        {
          toggle_control(state);
        }
        break;

      case '3':
        /* Set I3 off. */
        select_control(state, c_i3);
        if (state->control_states[c_i3] != 0)
        {
          toggle_control(state);
        }
        break;

      case '4':
        /* Set I0 on. */
        select_control(state, c_i0);
        if (state->control_states[c_i0] == 0)
        {
          toggle_control(state);
        }
        break;

      case '5':
        /* Set I1 on. */
        select_control(state, c_i1);
        if (state->control_states[c_i1] == 0)
        {
          toggle_control(state);
        }
        break;

      case '6':
        /* Set I2 on. */
        select_control(state, c_i2);
        if (state->control_states[c_i2] == 0)
        {
          toggle_control(state);
        }
        break;

      case '7':
        /* Set I3 on. */
        select_control(state, c_i3);
        if (state->control_states[c_i3] == 0)
        {
          toggle_control(state);
        }
        break;

      case 'd':
        /* Set data off. */
        select_control(state, c_d);
        if (state->control_states[c_d] != 0)
        {
          toggle_control(state);
        }
        break;

      case 'D':
        /* Set data on. */
        select_control(state, c_d);
        if (state->control_states[c_d] == 0)
        {
          toggle_control(state);
        }
        break;

      case 'k':
      case 'K':
        /* Select the clock control. */
        select_control(state, c_clk);

        /* Toggle twice. */
        toggle_clock(state);
        toggle_clock(state);
        break;

      case 'b':
      case 'B':
        /* Toggle breakpoint mode. */
        if (state->in_break)
        {
          state->in_break = 0;
        }
        else
        {
          state->in_break = 1;
          SET_STATUS(state->screen, "Breakpoint. B to resume.");
        }
        break;

      case 'q':
      case 'Q':
        /* Quit. */
        done = 1;
        break;

      default:
        /* Ignore others. */
        break;
    }

    /* If an error has been set, quit. */
    if (state->error != NULL)
    {
      done = 1;
    }
  }
}

static void clock_high(machine_state *state)
{
  unsigned data;
  unsigned skip = state->skip;

  /* Turn skip off it was on. */
  if (skip)
  {
    state->skip = 0;
    VFD_OFF(state->screen, SKIP_VFD);
  }

  /* Load the instruction in the instruction register. If the skip flag is set,
     the instruction lines are all pulled high. */
  state->ir = skip ? i_nopf : GET_INSTR(state);
  if (state->control_states[c_i3] | skip)
  {
    VFD_ON(state->screen, INST_VFD3);
  }
  else
  {
    VFD_OFF(state->screen, INST_VFD3);
  }
  if (state->control_states[c_i2] | skip)
  {
    VFD_ON(state->screen, INST_VFD2);
  }
  else
  {
    VFD_OFF(state->screen, INST_VFD2);
  }
  if (state->control_states[c_i1] | skip)
  {
    VFD_ON(state->screen, INST_VFD1);
  }
  else
  {
    VFD_OFF(state->screen, INST_VFD1);
  }
  if (state->control_states[c_i0] | skip)
  {
    VFD_ON(state->screen, INST_VFD0);
  }
  else
  {
    VFD_OFF(state->screen, INST_VFD0);
  }

  /* Turn off FLG0, JUMP, RETURN, FLGF in case they were on. */
  VFD_OFF(state->screen, FLG0_VFD);
  VFD_OFF(state->screen, REMOTE_FLG0_VFD);
  VFD_OFF(state->screen, JUMP_VFD);
  VFD_OFF(state->screen, REMOTE_JUMP_VFD);
  VFD_OFF(state->screen, RETURN_VFD);
  VFD_OFF(state->screen, REMOTE_RETURN_VFD);
  VFD_OFF(state->screen, FLGF_VFD);
  VFD_OFF(state->screen, REMOTE_FLGF_VFD);

  /* Turn off the logic VFD in case this is not a logic instruction. */
  VFD_OFF(state->screen, LV_VFD);

  /* Determine the data. If IEN is off, the data is zero; otherwise it is the
     data bus line. However, if the instruction is IEN, the data bus is read
     regardless. */
  data = state->ien || state->ir == i_ien ? state->control_states[c_d] : 0;

  /* Perform the instruction to update the result and carry registers. */
  switch (state->ir)
  {
    case i_nop0:
      /* FLG0 high. */
      VFD_ON(state->screen, FLG0_VFD);
      VFD_ON(state->screen, REMOTE_FLG0_VFD);
      break;

    case i_ld:
      /* Result register set to data. */
      state->rr = data;
      if (data)
      {
        VFD_ON(state->screen, RR_VFD);
        VFD_ON(state->screen, REMOTE_RR_VFD);
      }
      else
      {
        VFD_OFF(state->screen, RR_VFD);
        VFD_OFF(state->screen, REMOTE_RR_VFD);
      }
      break;

    case i_add:
      /* Result register set to data plus result register plus carry. Carry
         register set appropriately. */
      state->rr += data + state->cr;
      state->cr = state->rr >> 1;
      state->rr &= 1;
      if (state->rr)
      {
        VFD_ON(state->screen, RR_VFD);
        VFD_ON(state->screen, REMOTE_RR_VFD);
      }
      else
      {
        VFD_OFF(state->screen, RR_VFD);
        VFD_OFF(state->screen, REMOTE_RR_VFD);
      }
      if (state->cr)
      {
        VFD_ON(state->screen, CR_VFD);
      }
      else
      {
        VFD_OFF(state->screen, CR_VFD);
      }
      break;

    case i_sub:
      /* Result register set to complement of data plus result register plus
         carry. Carry register set appropriately. */
      state->rr += (data ^ 1) + state->cr;
      state->cr = state->rr >> 1;
      state->rr &= 1;
      if (state->rr)
      {
        VFD_ON(state->screen, RR_VFD);
        VFD_ON(state->screen, REMOTE_RR_VFD);
      }
      else
      {
        VFD_OFF(state->screen, RR_VFD);
        VFD_OFF(state->screen, REMOTE_RR_VFD);
      }
      if (state->cr)
      {
        VFD_ON(state->screen, CR_VFD);
      }
      else
      {
        VFD_OFF(state->screen, CR_VFD);
      }
      break;

    case i_one:
      /* Result register set to one. Carry register cleared. */
      state->rr = 1;
      state->cr = 0;
      VFD_ON(state->screen, RR_VFD);
      VFD_ON(state->screen, REMOTE_RR_VFD);
      VFD_OFF(state->screen, CR_VFD);
      break;

    case i_nand:
      /* Result register set to complement of result register and data. */
      state->rr = (state->rr & data) ^ 1;
      if (state->rr)
      {
        VFD_ON(state->screen, LV_VFD);
        VFD_ON(state->screen, RR_VFD);
        VFD_ON(state->screen, REMOTE_RR_VFD);
      }
      else
      {
        VFD_OFF(state->screen, RR_VFD);
        VFD_OFF(state->screen, REMOTE_RR_VFD);
      }
      break;

    case i_or:
      /* Result register set to result register or data. */
      state->rr |= data;
      if (state->rr)
      {
        VFD_ON(state->screen, LV_VFD);
        VFD_ON(state->screen, RR_VFD);
        VFD_ON(state->screen, REMOTE_RR_VFD);
      }
      else
      {
        VFD_OFF(state->screen, RR_VFD);
        VFD_OFF(state->screen, REMOTE_RR_VFD);
      }
      break;

    case i_xor:
      /* Result register set to result register or data. */
      state->rr ^= data;
      if (state->rr)
      {
        VFD_ON(state->screen, LV_VFD);
        VFD_ON(state->screen, RR_VFD);
        VFD_ON(state->screen, REMOTE_RR_VFD);
      }
      else
      {
        VFD_OFF(state->screen, RR_VFD);
        VFD_OFF(state->screen, REMOTE_RR_VFD);
      }
      break;

    case i_sto:
      /* Data bus set to result register. Write high if OEN. */
      if (state->rr)
      {
        VFD_ON(state->screen, REMOTE_DATA_VFD);
      }
      else
      {
        VFD_OFF(state->screen, REMOTE_DATA_VFD);
      }
      if (state->oen)
      {
        VFD_ON(state->screen, WRITE_VFD);
        VFD_ON(state->screen, REMOTE_WRITE_VFD);
        write_data(state, state->rr);
      }
      break;

    case i_stoc:
      /* Data bus set to complement of result register. Write high if OEN. */
      if (!state->rr)
      {
        VFD_ON(state->screen, REMOTE_DATA_VFD);
      }
      else
      {
        VFD_OFF(state->screen, REMOTE_DATA_VFD);
      }
      if (state->oen)
      {
        VFD_ON(state->screen, WRITE_VFD);
        VFD_ON(state->screen, REMOTE_WRITE_VFD);
        write_data(state, state->rr ^ 1);
      }
      break;

    case i_ien:
      /* Input enable register set to data. */
      state->ien = data;
      if (data)
      {
        VFD_ON(state->screen, IV_VFD);
      }
      else
      {
        VFD_OFF(state->screen, IV_VFD);
      }
      break;

    case i_oen:
      /* Output enable register set to data. */
      state->oen = data;
      if (data)
      {
        VFD_ON(state->screen, OEN_VFD);
      }
      else
      {
        VFD_OFF(state->screen, OEN_VFD);
      }
      break;

    case i_jmp:
      /* JUMP high. */
      VFD_ON(state->screen, JUMP_VFD);
      VFD_ON(state->screen, REMOTE_JUMP_VFD);
      break;

    case i_rtn:
      /* RETURN high. Skip next instruction. */
      VFD_ON(state->screen, RETURN_VFD);
      VFD_ON(state->screen, REMOTE_RETURN_VFD);
      state->skip = 1;
      VFD_ON(state->screen, SKIP_VFD);
      break;

    case i_skz:
      /* Skip register set to one if result register is zero. */
      if (state->rr == 0)
      {
        state->skip = 1;
        VFD_ON(state->screen, SKIP_VFD);
      }
      break;

    case i_nopf:
      /* FLGF high unless this was NOPF due to skip. */
      if (!skip)
      {
        VFD_ON(state->screen, FLGF_VFD);
        VFD_ON(state->screen, REMOTE_FLGF_VFD);
      }
      break;
  }

  /* Refresh. */
  wrefresh(state->screen);
}

static void clock_low(machine_state *state)
{
  /* Perform the instruction to update the result and carry registers. */
  switch (state->ir)
  {
    case i_nop0:
    case i_ld:
    case i_add:
    case i_sub:
    case i_one:
    case i_nand:
    case i_or:
    case i_xor:
      /* No change. */
      break;

    case i_sto:
    case i_stoc:
      /* Return the write line low. */
      VFD_OFF(state->screen, WRITE_VFD);
      VFD_OFF(state->screen, REMOTE_WRITE_VFD);
      break;

    case i_ien:
    case i_oen:
    case i_jmp:
    case i_rtn:
    case i_skz:
    case i_nopf:
      /* No change. */
      break;
  }

  /* Refresh. */
  wrefresh(state->screen);
}

static void select_control(machine_state *state, controls ctrl)
{
  const coord *c;

  /* Select the control. */
  c = binary_controls[state->control] + bci_pointer;
  POINTER_OFF(state->screen, c->y, c->x);
  state->control = ctrl;
  c = binary_controls[ctrl] + bci_pointer;
  POINTER_ON(state->screen, c->y, c->x);
}

static void toggle_control(machine_state *state)
{
  const coord *c;

  /* Turn off the current setting. */
  c = binary_controls[state->control] + state->control_states[state->control];
  CONTROL_OFF_YX(state->screen, c->y, c->x);

  /* Toggle the current value. */
  state->control_states[state->control] ^= 1;

  /* Turn on the new setting. */
  c = binary_controls[state->control] + state->control_states[state->control];
  CONTROL_ON_YX(state->screen, c->y, c->x);

  /* Set the corresponding VFD to match. */
  c = binary_controls[state->control] + bci_vfd;
  if (state->control_states[state->control])
  {
    VFD_ON_YX(state->screen, c->y, c->x);
  }
  else
  {
    VFD_OFF_YX(state->screen, c->y, c->x);
  }

  /* The data line also controls the data VFD on the remote. */
  if (state->control == c_d)
  {
    if (state->control_states[c_d])
    {
      VFD_ON(state->screen, REMOTE_DATA_VFD);
    }
    else
    {
      VFD_OFF(state->screen, REMOTE_DATA_VFD);
    }
  }

  /* Update status. */
  SET_STATUS(state->screen, instructions[GET_INSTR(state)]);
}

static void toggle_clock(machine_state *state)
{
  /* Perform clock-triggered functions depending on the transition. */
  if (state->control_states[c_clk])
  {
    /* Clock is currently high, so transition low. */
    state->control_states[c_clk] = bci_0;
    VFD_OFF(state->screen, REMOTE_C_VFD);
    CONTROL_OFF(state->screen, REMOTE_CLK_C);
    CONTROL_OFF(state->screen, REMOTE_CLK_L);
    CONTROL_OFF(state->screen, REMOTE_CLK_K);
    clock_low(state);
  }
  else
  {
    /* Clock is currently low, so transition high. */
    state->control_states[c_clk] = bci_1;
    VFD_ON(state->screen, REMOTE_C_VFD);
    CONTROL_ON(state->screen, REMOTE_CLK_C);
    CONTROL_ON(state->screen, REMOTE_CLK_L);
    CONTROL_ON(state->screen, REMOTE_CLK_K);
    clock_high(state);
  }
}

static int get_input(machine_state *state)
{
  int ch;
  int in_comment = 0;
  int end_comment = 0;

  /* If there is an input file, read from it as long as we're not in breakpoint
     mode. */
  if (state->in_file != NULL && !state->in_break)
  {
    /* Delay. */
    getch();

    /* Get a non-comment character. */
    do
    {
      /* If the end of comment was seen, we're out of the comment. */
      in_comment = in_comment ^ end_comment;

      /* Get the next character. */
      ch = fgetc(state->in_file);
      if (ch == EOF)
      {
        /* If it was an error, quit. */
        if (ferror(state->in_file))
        {
          state->error = "Error reading input file.";
          return 'q';
        }

        /* Close the file if not an error. */
        if (fclose(state->in_file) != 0)
        {
          state->error = "Error closing input file.";
          return 'q';
        }

        /* The input file is exhausted so switch back to interactive. */
        state->in_file = NULL;
        nocbreak();
        cbreak();
      }
      else if (in_comment)
      {
        /* Check if the end of the comment was found. */
        end_comment = ch == '\n';
      }
      else if (ch == ';')
      {
        /* Keep reading until a newline. */
        in_comment = 1;
        end_comment = 0;
      }
      else if (ch == '\r')
      {
        /* Treat carriage return like a single-character comment. */
        in_comment = 1;
        end_comment = 1;
      }
      else
      {
        /* If not EOF or error, return the charcter read. */
        return ch;
      }
    }
    while (in_comment);
  }

  /* Otherwise get the next character from curses. */
  return getch();
}

static void write_data(machine_state *state, unsigned bit)
{
  /* If there is no output file, do nothing. */
  if (state->out_file == NULL)
  {
    return;
  }

  /* Set the next bit in the byte. */
  state->curr_byte |= bit << state->bits_set;
  ++state->bits_set;

  /* If all bits are set in the byte, write it out. */
  if (state->bits_set == 8)
  {
    if (fputc(state->curr_byte, state->out_file) != state->curr_byte)
    {
      state->error = "Error writing output file.";
    }

    /* And reset to start the next. */
    state->curr_byte = 0;
    state->bits_set = 0;
  }
}

