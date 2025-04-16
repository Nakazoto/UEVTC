/* UE14500 assembler.

   License: Public Domain

   Build and run instructions (there are many ways - use these as a guide):

   Linux:
     - Ensure GCC is installed.
     - gcc -o ue14500-asm ue14500-asm.c
     - ./ue14500-asm ... (see below)

   Mac:
     - Ensure Xcode is installed.
     - clang -o ue14500-asm ue14500-asm.c
     - ./ue14500-asm ... (see below)

   Windows:
     - Install MSYS2 (https://www.msys2.org) including the base dev package.
     - gcc -o ue14500-asm ue14500-asm.c -lpdcurses
     - ./ue14500-asm.exe ... (see below)

   Input file format (* = 0 or more, + = 1 or more, ? = 0 or 1):
     FILE := LINE*
     LINE := COMMENT_LINE | DIRECTIVE | LABEL | INSTRUCTION
     COMMENT := ';' NON_NEWLINE*
     COMMENT_LINE := COMMENT? CR? '\n'
     DIRECTIVE := '.' ALPHA ALPHANUM* WS+ ALPHANUM+ WS* COMMENT? CR? '\n'
     LABEL := NUMERIC_LABEL | NAMED_LABEL
     NUMERIC_LABEL := DIGIT+ ':' WS* COMMENT? CR? '\n'
     NAMED_LABEL := ALPHA ALPHANUM* ':' WS* COMMENT? CR? '\n'
     INSTRUCTION := WS+ INSTR WS* COMMENT? CR? '\n'
     INSTR := NOP0 | LD | ADD | SUB | ONE | NAND | OR | XOR |
              STO | STOC | IEN | OEN | JMP | RTN | SKZ | NOPF
     WS := space | tab
     CR := carriage return
     DIGIT := Decimal digit (0-9)
     ALPHA := Uppercase or lowercase English letter (A-Z, a-z)
     ALPHANUM := ALPHA | DIGIT
     NON_NEWLINE := Any character other than '\n'
   Directives, labels, and instructions are all case-insensitive. Numeric labels
   need not be unique, but named labels must be. Labels are currently ignored
   other than validating them.

   Lines should not exceed 80 characters, and will result in errors if over a
   predefined length. This is to keep the assembler simple and portable.

   The raw output format is simply the machine code packed in to bytes (two
   instructions per byte) in little endian order, so the first instruction is
   in the lower 4 bits of the first byte and the second instruction is in the
   upper 4 bits of the first byte and so on. If there are an odd number of
   instructions, the final byte has NOP0 in the upper half.

   The emulator output format generates the required input file to run in the
   emulator. Various command line options and directives control the details of
   this output as well as allowing data to be embedded.

   Directives:
     .outfmt = sets the output format. Allowed values are "raw" and "emu". This
               must be the first line in the file.
     .delay = sets the emulator delay value. This must be the second line in
              the file if the output format is "emu". Ignored for raw output.
     .init = sets the initialization values for the emulator startup. The value
             is 10 characters. Defaults to 10 '0's. This must be the third line
             in the file if the output format is "emu". Ignored for raw output.
     .fixedlen = if "inst" or "data", emulator output is generated such that
                 every instruction uses the same number of emulator commands in
                 order to effect a constant execution speed. If "off", the
                 optimal set of commands is produced to generate the smallest
                 file. The value "inst" means instructions only; the value
                 "data" includes commands to set the data for each instruction
                 and should be used when embedding data. Defaults to "off".
                 This must be specified before the first instruction or data.
                 Ignored for raw output.
     .comments = if "on", transfer all comments to the emulator output file, as
                 well as adding comments documenting each machine instruction
                 generated. If "off", strip all comments. Defaults to "off".
                 Ignored for raw output. This directive can appear multiple
                 times to turn the feature on and off at will.
     .quit = if "on", the emulator quit command is appended to the assembled
             output. If "off" it is not. Defaults to "off". Ignored for raw
             output.
     .data = Specify the value of the data input as 0 or 1. Defaults to 0.
             Ignored for raw output. This directive can appear multiple times to
             specify different values at different points in the code.
     .emu = Literal command string to pass to emulator. No whitespace is
            allowed. Ignored for raw output. This directive can appear any
            number of times to insert commands. This directive can facilitate
            debugging if the breakpoint command is inserted.

   Command line:
     ue14500-asm [OPTIONS] [INFILE] [OUTFILE]

     The OPTIONS override same-named directives if present. See the directive
     documentation. The options are:
       -outfmt <raw|emu>

     The INFILE specifies the input file. If omitted or "-", stdin is read.

     The OUTFILE specifies the output file. If omitted or "-", stdout is
     written. If an OUTFILE is specified, an INFILE must be (can be "-").

   Tip: to run the emulator at a particular clock rate, figure out the delay to
   achieve that rate, then divide by 5 or 6, depending on whether you embed
   data, and use that as the .delay value while setting .fixedlen to inst. The
   fixed-length output format always generates exactly 5 commands to the
   emulator for each instruction if there is no embedded data or 6 commands to
   the emulator for each instruction if there is embedded data. Example: 10 Hz
   with embeddded data, so the base delay is 100 (milliseconds), divided by 6
   is ~17. Setting 17 for the delay gives an actual speed of 9.8 Hz then. This
   of course does not account for the actual time the emulator needs to run the
   instruction, but it is assumed that is negligible in comparison to the clock
   rate.
*/
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Output format. */
typedef enum output_format_
{
  of_raw,
  of_emu,

  num_output_format
} output_format;
static const char *output_formats[num_output_format] =
{
  "raw",
  "emu"
};

/* Fixed-length setting. */
typedef enum fixedlen_setting_
{
  fs_off,
  fs_inst,
  fs_data,

  num_fixedlen_setting
} fixedlen_setting;
static const char *fixedlen_settings[num_fixedlen_setting] =
{
  "off",
  "inst",
  "data"
};

/* The state of the assembler. */
typedef struct asm_state_
{
  /* Input and output files. */
  FILE *in_file;
  FILE *out_file;

  /* Line number. */
  unsigned line;

  /* Output accumulator for raw output. Previous instruction for emu output. */
  unsigned curr_byte;
  unsigned bits_set;

  /* Output format. */
  output_format outfmt;

  /* Type of instructions to emit for the emulator. */
  fixedlen_setting emu_fixedlen;

  /* Emit comments for the emulator? */
  int emu_comments;

  /* Quit settings for the emulator. */
  int emu_quit;

  /* Current data line value for the emulator. */
  int emu_data;
} asm_state;

/* Helpers. */
static int read_int(const char *str);
static int read_digit(const char *str);
static int read_boolean(const char *str);
static output_format read_output_format(const char *str);
static fixedlen_setting read_fixedlen_setting(const char *str);
static int process_line(asm_state *state, char *line);

int main(int argc, char **argv)
{
  int i;
  char line[128];

  /* Initialize the state. Set the output format to unspecified. */
  asm_state state = { 0 };
  state.outfmt = num_output_format;

  /* Read the command line arguments. */
  for (i = 1; i < argc; ++i)
  {
    if (strcmp(argv[i], "-outfmt") == 0)
    {
      ++i;
      if (i < argc)
      {
        state.outfmt = read_output_format(argv[i]);
        if (state.outfmt == num_output_format)
        {
          fputs("Invalid output format.\n", stderr);
          return 1;
        }
      }
      else
      {
        fputs("Missing output format.\n", stderr);
        return 1;
      }
    }
    else if (state.in_file == NULL)
    {
      if (strcmp(argv[i], "-") == 0)
      {
        state.in_file = stdin;
      }
      else
      {
        state.in_file = fopen(argv[i], "rb");
        if (state.in_file == NULL)
        {
          fprintf(stderr, "Unable to open input file: %s\n", argv[i]);
          return 1;
        }
      }
    }
    else if (state.out_file == NULL)
    {
      if (strcmp(argv[i], "-") == 0)
      {
        state.out_file = stdout;
      }
      else
      {
        state.out_file = fopen(argv[i], "wb");
        if (state.out_file == NULL)
        {
          fprintf(stderr, "Unable to open output file: %s\n", argv[i]);
          return 1;
        }
      }
    }
    else
    {
      fprintf(stderr, "Unexpected argument: %s\n", argv[i]);
      return 1;
    }
  }

  /* Default input/output files if not specified. */
  if (state.in_file == NULL)
  {
    state.in_file = stdin;
  }
  if (state.out_file == NULL)
  {
    state.out_file = stdout;
  }

  /* Read and process each line. */
  while (1)
  {
    /* Get the line. */
    ++state.line;
    if (fgets(line, sizeof(line), state.in_file) == NULL)
    {
      if (feof(state.in_file))
      {
        break;
      }
      fputs("Error reading input file.\n", stderr);
      return 1;
    }
    if (line[strlen(line) - 1] != '\n')
    {
      fprintf(stderr, "Line too long: %s\n", line);
      return 1;
    }

    /* Process it. */
    i = process_line(&state, line);
    if (i != 0)
    {
      return i;
    }
  }

  /* Flush any accumulated bits. */
  if (state.bits_set != 0)
  {
    if (fputc(state.curr_byte, state.out_file) == EOF)
    {
      fputs("Error writing output file.\n", stderr);
      return 1;
    }
  }

  /* Emit quit command if desired. */
  if (state.outfmt == of_emu && state.emu_quit)
  {
    if (fputc('q', state.out_file) == EOF)
    {
      fputs("Error writing output file.\n", stderr);
      return 1;
    }
  }

  /* Close open files. */
  if (state.in_file != NULL && state.in_file != stdin)
  {
    if (fclose(state.in_file) != 0)
    {
      fputs("Error closing input file.\n", stderr);
      return 1;
    }
  }
  if (state.out_file != NULL && state.out_file != stdin)
  {
    if (fclose(state.out_file) != 0)
    {
      fputs("Error closing output file.\n", stderr);
      return 1;
    }
  }

  /* Success. */
  return 0;
}

static int read_int(const char *str)
{
  char *end;
  int i = (int)strtol(str, &end, 10);
  if (end == NULL || *end != '\0')
  {
    i = -1;
  }
  return i;
}

static int read_digit(const char *str)
{
  int i = -1;
  if (str[1] == '\0')
  {
    if (str[0] == '0')
    {
      i = 0;
    }
    else if (str[0] == '1')
    {
      i = 1;
    }
  }
  return i;
}

static int read_boolean(const char *str)
{
  int i = -1;
  if (strcasecmp(str, "off") == 0)
  {
    i = 0;
  }
  else if (strcasecmp(str, "on") == 0)
  {
    i = 1;
  }
  return i;
}

static output_format read_output_format(const char *str)
{
  int i;
  for (i = 0; i < num_output_format; ++i)
  {
    if (strcasecmp(str, output_formats[i]) == 0)
    {
      break;
    }
  }
  return (output_format)i;
}

static fixedlen_setting read_fixedlen_setting(const char *str)
{
  int i;
  for (i = 0; i < num_fixedlen_setting; ++i)
  {
    if (strcasecmp(str, fixedlen_settings[i]) == 0)
    {
      break;
    }
  }
  return (fixedlen_setting)i;
}

/* Process helpers. */
static int process_comment(const asm_state *state, const char *line);
static int process_directive(asm_state *state, char *line);
static int process_label(asm_state *state, char *line);
static int process_instruction(asm_state *state, char *line);

static int process_line(asm_state *state, char *line)
{
  int i;

  /* Process the line based on the type of line. */
  switch (line[0])
  {
    case ';':
      /* Comment line. */
      i = process_comment(state, line);
      break;

    case '.':
      /* Directive line. */
      i = process_directive(state, line);
      break;

    case ' ':
    case '\t':
      /* Instruction line. */
      i = process_instruction(state, line);
      break;

    case '\r':
    case '\n':
      /* Empty line. */
      i = 0;
      break;

    default:
      /* Label line. */
      i = process_label(state, line);
      break;
  }

  return i;
}

static int process_comment(const asm_state *state, const char *line)
{
  /* If emitting comments, copy it to the output. */
  if (state->emu_comments && state->outfmt == of_emu)
  {
    if (fputs(line, state->out_file) == EOF)
    {
      fputs("Error writing output file.", stderr);
      return 1;
    }
  }

  /* Success. */
  return 0;
}

static int process_directive(asm_state *state, char *line)
{
  int i;
  char dend;
  char *value;
  size_t index;
  size_t line_bytes = strlen(line);

  /* Find and mark the end of the directive. */
  index = strcspn(line, " \t");
  if (index == line_bytes)
  {
    fprintf(stderr,
            "Could not find end of directive on line %u.\n", state->line);
    return 1;
  }
  line[index] = '\0';

  /* Find the beginning of the value. */
  value = line + index + 1;
  line_bytes -= index + 1;
  index = strspn(value, " \t");
  if (index == line_bytes)
  {
    fprintf(stderr,
            "Could not find directive value on line %u.\n", state->line);
    return 1;
  }
  value += index;

  /* Find the end of the value. */
  index = strcspn(value, " \r\t\n;");
  dend = value[index];
  value[index] = '\0';

  /* Handle each directive type. */
  if (strcasecmp(line, ".outfmt") == 0)
  {
    /* The format is only updated if not set on the command line. */
    if (state->outfmt == num_output_format)
    {
      state->outfmt = read_output_format(value);
      if (state->line != 1 || state->outfmt == num_output_format)
      {
        fprintf(stderr,
                "Invalid output format directive on line %u.\n", state->line);
        return 1;
      }
    }
  }
  else if (strcasecmp(line, ".delay") == 0)
  {
    i = read_int(value);
    if (i <= 0 || state->line != 2)
    {
      fprintf(stderr, "Invalid delay directive on line %u.\n", state->line);
      return 1;
    }
    if (state->outfmt == of_emu)
    {
      if (fputs(value, state->out_file) == EOF ||
          fputc('\n', state->out_file) == EOF)
      {
        fputs("Error writing output file.\n", stderr);
        return 1;
      }
    }
  }
  else if (strcasecmp(line, ".init") == 0)
  {
    if (strlen(value) == 10 && state->line == 3)
    {
      if (state->outfmt == of_emu)
      {
        if (fputs(value, state->out_file) == EOF ||
            fputc('\n', state->out_file) == EOF)
        {
          fputs("Error writing output file.\n", stderr);
          return 1;
        }
      }
    }
    else
    {
      fprintf(stderr, "Invalid init directive on line %u.\n", state->line);
      return 1;
    }
  }
  else if (strcasecmp(line, ".fixedlen") == 0)
  {
    state->emu_fixedlen = read_fixedlen_setting(value);
    if (state->emu_fixedlen == num_fixedlen_setting)
    {
      fprintf(stderr, "Invalid fixedlen directive on line %u.\n", state->line);
      return 1;
    }
  }
  else if (strcasecmp(line, ".comments") == 0)
  {
    state->emu_comments = read_boolean(value);
    if (state->emu_comments < 0)
    {
      fprintf(stderr, "Invalid comments directive on line %u.\n", state->line);
      return 1;
    }
  }
  else if (strcasecmp(line, ".quit") == 0)
  {
    state->emu_quit = read_boolean(value);
    if (state->emu_quit < 0)
    {
      fprintf(stderr, "Invalid quit directive on line %u.\n", state->line);
      return 1;
    }
  }
  else if (strcasecmp(line, ".data") == 0)
  {
    /* Get the new data value. */
    state->emu_data = read_digit(value);
    if (state->emu_data < 0)
    {
      fprintf(stderr, "Invalid data directive on line %u.\n", state->line);
      return 1;
    }

    /* If emulator output and not data fixed-length, emit the command to set
       the data value now. */
    if (state->outfmt == of_emu && state->emu_fixedlen != fs_data)
    {
      if (fputc(state->emu_data ? 'D' : 'd', state->out_file) == EOF)
      {
        fputs("Error writing output file.\n", stderr);
        return 1;
      }

      /* Emit an empty comment if comments are on. */
      if (state->emu_comments)
      {
        if (fputs(";\n", state->out_file) == EOF)
        {
          fputs("Error writing output file.\n", stderr);
          return 1;
        }
      }
    }
  }
  else if (strcasecmp(line, ".emu") == 0)
  {
    /* Emit the value if emulator output. */
    if (state->outfmt == of_emu)
    {
      if (fputs(value, state->out_file) == EOF)
      {
        fputs("Error writing output file.", stderr);
        return 1;
      }
    }

    /* Emit an empty comment if comments are on. */
    if (state->emu_comments)
    {
      if (fputs(";\n", state->out_file) == EOF)
      {
        fputs("Error writing output file.\n", stderr);
        return 1;
      }
    }
  }

  /* Process the rest of the line. */
  value[index] = dend;
  line = value + index;
  index = strspn(line, " \t\r\n");
  line += index;
  if (line[0] == ';')
  {
    return process_comment(state, line);
  }
  else if (line[0] != '\0')
  {
    fprintf(stderr,
            "Unexpected text after directive on line %u.\n", state->line);
    return 1;
  }

  /* Success. */
  return 0;
}

static int process_label(asm_state *state, char *line)
{
  size_t index;

  /* Find the end of the label. */
  char *lend = strchr(line, ':');
  if (lend == NULL)
  {
    fprintf(stderr, "Invalid label on line %u.\n", state->line);
    return 1;
  }
  *lend = '\0';

  /* Verify the numeric label if it starts with a decimal digit. */
  if (isdigit(line[0]))
  {
    for (index = 1; line[index] != '\0'; ++index)
    {
      if (!isdigit(line[index]))
      {
        fprintf(stderr, "Invalid label on line %u.\n", state->line);
        return 1;
      }
    }
  }
  else if (isalpha(line[0]))
  {
    /* Ensure alphanumeric for named labels. */
    for (index = 1; line[index] != '\0'; ++index)
    {
      if (!isalnum(line[index]))
      {
        fprintf(stderr, "Invalid label on line %u.\n", state->line);
        return 1;
      }
    }
  }
  else
  {
    fprintf(stderr, "Invalid label on line %u.\n", state->line);
    return 1;
  }

  /* Process the rest of the line. */
  line = lend + 1;
  index = strspn(line, " \t\r\n");
  line += index;
  if (line[0] == ';')
  {
    return process_comment(state, line);
  }
  else if (line[0] != '\0')
  {
    fprintf(stderr,
            "Unexpected text after label on line %u.\n", state->line);
    return 1;
  }

  /* Success. */
  return 0;
}

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
  i_nopf, /* 1111: NOPF = No change in registers. RR -> RR. FLGF high. */

  num_instructions
} instruction;
static const char *instructions[num_instructions] =
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
static const char *emu_commands[num_instructions] =
{
  "3210",
  "3214",
  "3250",
  "3254",
  "3610",
  "3614",
  "3650",
  "3654",
  "7210",
  "7214",
  "7250",
  "7254",
  "7610",
  "7614",
  "7650",
  "7654"
};

static int process_instruction(asm_state *state, char *line)
{
  unsigned i;
  char iend;
  size_t index;
  instruction instr = num_instructions;

  /* Skip leading whitespace. */
  line += strspn(line, " \t");

  /* Find and mark the end of the instruction mnemonic. */
  index = strcspn(line, " \t\r\n;");
  iend = line[index];
  line[index] = '\0';

  /* Look up the instruction. */
  for (i = 0; i < num_instructions; ++i)
  {
    if (strcasecmp(line, instructions[i]) == 0)
    {
      instr = (instruction)i;
      break;
    }
  }
  if (i == num_instructions)
  {
    fprintf(stderr, "Invalid instruction on line %u.\n", state->line);
    return 1;
  }

  /* Emit the instruction. */
  switch (state->outfmt)
  {
    case of_raw:
      /* Add to the accumulator. */
      state->curr_byte |= instr << state->bits_set;
      state->bits_set += 4;

      /* Emit if the accumulator is full. */
      if (state->bits_set == 8)
      {
        if (fputc(state->curr_byte, state->out_file) == EOF)
        {
          fputs("Error writing output file.\n", stderr);
          return 1;
        }
        state->curr_byte = 0;
        state->bits_set = 0;
      }
      break;

    case of_emu:
      /* Output for the emulator according to mode. */
      switch (state->emu_fixedlen)
      {
        case fs_off:
          /* Toggle differences in each instruction line from the previous
             instruction. */
          i = instr & 0x8;
          if (i != (state->curr_byte & 0x8))
          {
            if (fputc(i ? '7' : '3', state->out_file) == EOF)
            {
              fputs("Error writing output file.\n", stderr);
              return 1;
            }
          }

          i = instr & 0x4;
          if (i != (state->curr_byte & 0x4))
          {
            if (fputc(i ? '6' : '2', state->out_file) == EOF)
            {
              fputs("Error writing output file.\n", stderr);
              return 1;
            }
          }

          i = instr & 0x2;
          if (i != (state->curr_byte & 0x2))
          {
            if (fputc(i ? '5' : '1', state->out_file) == EOF)
            {
              fputs("Error writing output file.\n", stderr);
              return 1;
            }
          }

          i = instr & 0x1;
          if (i != (state->curr_byte & 0x1))
          {
            if (fputc(i ? '4' : '0', state->out_file) == EOF)
            {
              fputs("Error writing output file.\n", stderr);
              return 1;
            }
          }

          /* Clock pulse. */
          if (fputc('k', state->out_file) == EOF)
          {
            fputs("Error writing output file.\n", stderr);
            return 1;
          }
          break;

        case fs_inst:
          /* Emit the full instruction and a clock pulse. */
          if (fputs(emu_commands[instr], state->out_file) == EOF ||
              fputc('k', state->out_file) == EOF)
          {
            fputs("Error writing output file.\n", stderr);
            return 1;
          }
          break;

        case fs_data:
          /* Emit the full instruction, data, and a clock pulse. */
          if (fputs(emu_commands[instr], state->out_file) == EOF ||
              fputc(state->emu_data ? 'D' : 'd', state->out_file) == EOF ||
              fputc('k', state->out_file) == EOF)
          {
            fputs("Error writing output file.\n", stderr);
            return 1;
          }
          break;

        case num_fixedlen_setting:
          return 1;
      }

      /* If comments are on, emit a comment as well. */
      if (state->emu_comments)
      {
        if (fputs("; ", state->out_file) == EOF ||
            fputs(instructions[instr], state->out_file) == EOF ||
            fputc('\n', state->out_file) == EOF)
        {
          fputs("Error writing output file.\n", stderr);
          return 1;
        }
      }

      /* Save this instruction for next time. */
      state->curr_byte = instr;
      break;

    case num_output_format:
      return 1;
  }

  /* Process the rest of the line. */
  line[index] = iend;
  line += index;
  index = strspn(line, " \t\r\n");
  line += index;
  if (line[0] == ';')
  {
    return process_comment(state, line);
  }
  else if (line[0] != '\0')
  {
    fprintf(stderr,
            "Unexpected text after instruction on line %u.\n", state->line);
    return 1;
  }

  /* Success. */
  return 0;
}

