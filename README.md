# MiniALU Core

A small 16-bit processor datapath written in Verilog. The core executes one
instruction per clock cycle and contains a four-register register file, an
ALU, a condition-flag register, and an output register.

## Features

- Four 16-bit general-purpose registers: `R0`–`R3`
- 16-bit ALU with arithmetic, logic, shift, compare, and data-movement operations
- Condition flags in `{V, N, C, Z}` order
- Active-low reset
- Self-checking testbench covering all defined operations, reserved opcodes,
  reset, flag behavior, and edge cases

## Instruction set

| Opcode | Operation | Description |
| --- | --- | --- |
| `0000` | `ADD` | `Rd = Rd + Rs` |
| `0001` | `SUB` | `Rd = Rd - Rs` |
| `0010` | `AND` | `Rd = Rd & Rs` |
| `0011` | `OR` | `Rd = Rd \| Rs` |
| `0100` | `XOR` | `Rd = Rd ^ Rs` |
| `0101` | `NOT` | `Rd = ~Rd` |
| `0110` | `SHL` | Shift `Rd` left by one bit |
| `0111` | `SHR` | Shift `Rd` right by one bit |
| `1000` | `INC` | Increment `Rd` |
| `1001` | `DEC` | Decrement `Rd` |
| `1010` | `CMP` | Compare `Rd` with `Rs`; update flags without changing `Rd` |
| `1011` | `MOV` | `Rd = Rs` |
| `1100` | `LDI` | Load a zero-extended 10-bit immediate into `Rd` |
| `1101` | `OUT` | Copy `Rd` to the output register |
| `1110` | Reserved | No operation |
| `1111` | Reserved | No operation |

The instruction word is 16 bits. The opcode occupies bits `[15:12]`, and the
destination register occupies `[11:10]`. Register-format instructions use
`[9:8]` for the source register; immediate-format instructions use `[9:0]` for
the immediate value.

## Source files

- `src/minialu_core_top.v` — top-level datapath and module connections
- `src/instruction_decode.v` — instruction fields and write enables
- `src/alu.v` — ALU results and next-flag calculation
- `src/register_file.v` — four 16-bit registers with two combinational read ports
- `src/flag_register.v` — condition-flag storage
- `src/out_register.v` — output-register storage
- `tb_minialu_core.v` — self-checking simulation testbench

## Run the testbench

Install [Icarus Verilog](https://steveicarus.github.io/iverilog/) and run these
commands from the repository root:

```sh
iverilog -g2012 -s tb_minialu_core -o simv tb_minialu_core.v src/*.v
vvp simv
```

The testbench prints individual checks and a final pass/fail summary. It also
writes `tb_minialu_core.vcd`, which can be opened in a waveform viewer such as
GTKWave.
