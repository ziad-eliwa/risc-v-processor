# RV32I Single-Cycle Processor — Testbenches

This directory contains **20 Verilog testbenches** for testing the individual RTL components and RV32I instruction groups of a single-cycle RISC-V processor.

The testbenches use the naming convention `*_tb.v`. The shared include file, `common_tb.vh`, is **not** a standalone testbench.

## Testbench inventory

### 1. Module-level tests (15)

| Testbench | RTL module under test | Purpose |
|---|---|---|
| `alu_control_unit_tb.v` | `alu_control_unit` | ALU operation selection from instruction/control inputs |
| `branch_cu_tb.v` | `branch_cu` | Branch condition decisions from comparison/status flags |
| `control_unit_tb.v` | `control_unit` | Main control signals for instruction opcodes |
| `data_mem_tb.v` | `data_mem` | Data memory reads and writes |
| `decoder_5_by_32_tb.v` | `decoder_5_by_32` | Five-bit to 32-line decoding |
| `dff_tb.v` | `dff` | Flip-flop behavior, including clock/reset as implemented |
| `imm_generator_tb.v` | `imm_generator` | Immediate extraction and sign extension |
| `instr_mem_tb.v` | `instr_mem` | Instruction memory outputs |
| `mux2x1_tb.v` | `mux2x1` | Two-input multiplexer selection |
| `nbit_mux2by1_tb.v` | `nbit_mux2by1` | Parameterized-width two-input multiplexer |
| `nbit_mux4by1_tb.v` | `nbit_mux4by1` | Parameterized-width four-input multiplexer |
| `nbit_register_tb.v` | `nbit_register` | Parameterized register updates and reset behavior |
| `prv32_ALU_tb.v` | `prv32_ALU` | Arithmetic, logic, and status outputs |
| `register_file_tb.v` | `register_file` | Register reads, writes, and x0 behavior |
| `shifter_tb.v` | `shifter` | Shift operations |

### 2. RV32I instruction-group tests (5)

| Testbench | Coverage |
|---|---|
| `u_i_alu_tb.v` | U-type and immediate ALU instructions: LUI, AUIPC, ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI |
| `r_alu_tb.v` | Register-register ALU instructions: ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND |
| `loads_stores_tb.v` | Load/store instructions: LB, LH, LW, LBU, LHU, SB, SH, SW |
| `branches_jumps_tb.v` | Branch/jump instructions: BEQ, BNE, BLT, BGE, BLTU, BGEU, JAL, JALR |
| `system_fence_tb.v` | FENCE, FENCE.TSO, PAUSE, ECALL, EBREAK (according to the CPU implementation's expected behavior) |

### Shared testbench include

- `common_tb.vh` — shared instruction encoders, program-loading helpers, and checks used by the instruction-group testbenches. This is an include file, **not** a testbench to compile as a top-level module.

## Recommended repository layout

```text
project/
├── rtl/
│   ├── cpu.v
│   ├── alu_control_unit.v
│   ├── branch_cu.v
│   ├── control_unit.v
│   ├── defines.v
│   └── ... other RTL modules ...
├── tb/
│   ├── common_tb.vh
│   ├── alu_control_unit_tb.v
│   ├── branch_cu_tb.v
│   ├── branches_jumps_tb.v
│   ├── ... other *_tb.v files ...
│   └── README.md
├── scripts/
│   └── run_tests.sh
└── Makefile
```

**Requirements:** Verilator, `make`, a C++ compiler, and the RTL files for the modules being tested. The CPU-level tests additionally require `cpu.v` and the processor's connected RTL components. Keep `rtl/defines.v` available for modules that include it.

## Running tests

Run these commands from the **repository root**.

### Run all testbenches

```bash
make test
```

The existing test script discovers files matching `tb/*_tb.v` or `tb/*_tb.sv`, compiles each with Verilator, and runs them independently.

### Run one testbench

```bash
bash scripts/run_tests.sh alu_control_unit_tb
bash scripts/run_tests.sh branches_jumps_tb
```

Use the testbench filename **without** `.v`. To run several selected tests:

```bash
bash scripts/run_tests.sh prv32_ALU_tb branch_cu_tb r_alu_tb
```

### Compile directly with Verilator

```bash
verilator --binary --timing --Wno-fatal \
  -Irtl -Itb \
  --top-module branch_cu_tb \
  --Mdir build/sim/obj_branch_cu_tb \
  rtl/*.v tb/branch_cu_tb.v

./build/sim/obj_branch_cu_tb/Vbranch_cu_tb
```

Use the corresponding top-level module/file for a different testbench. The `-Itb` flag is essential for tests using:

```verilog
`include "common_tb.vh"
```

## Output and CI

The test runner writes simulation artifacts into `build/sim/`:

- `<name>.compile.log` — compilation output and errors
- `<name>.log` — simulation output for the testbench

The repository's GitHub Actions workflow runs `make test`; a nonzero exit status fails the simulation job.

**Important:** The current runner detects failures by searching for `FAIL` in the simulation output and requires a success message containing `TEST PASSED` or `TESTS PASSED` (depending on the runner version). Ensure each testbench prints a clear final success line only after its checks pass. For robust CI, a testbench should terminate unsuccessfully on a failed check (for example, using `$fatal`), rather than printing a failure and exiting successfully.

## Notes and assumptions

- The module-level tests exercise individual components; the five instruction-group tests exercise the integrated processor.
- Some CPU-level tests may refer to internal hierarchy such as `uut.iMem.mem`, `uut.RF.Q`, and `uut.PCOut`. These names must match the actual `cpu.v` hierarchy.
- Instruction-group tests may assume an active-high reset, PC initialization at address zero, an instruction-memory word array, and suitable data-memory capacity. Adjust the testbenches to your implementation if needed.
- The system/fence test reflects the behavior expected by the supplied testbench; ECALL and EBREAK behavior is implementation-dependent and should be checked against the project's CPU design.
- The testbench files listed here are documented by filename and intended coverage. This README is **not** a claim that all tests have passed on the current RTL version.

## Troubleshooting

| Symptom | What to check |
|---|---|
| `Cannot find include file: common_tb.vh` | Confirm `tb/common_tb.vh` exists, and compile with `-Itb` |
| `Cannot find include file: defines.v` | Confirm `rtl/defines.v` exists, and compile with `-Irtl` |
| `Cannot find top module` | Ensure the Verilog `module` name matches the filename without `.v` |
| Compilation fails | Open `build/sim/<name>.compile.log` |
| Simulation fails | Open `build/sim/<name>.log` and compare expected vs. actual values |
| CI says `no 'TEST PASSED' line` | Align the testbench's success message with the runner's success-string check |
| Hierarchical reference not found | Update the internal CPU path referenced by the testbench |

