# Single-Cycle RISC-V Processor

A 32-bit single-cycle RISC-V processor written in Verilog for **CSCE 3301 — Computer Architecture, Project 1** at the American University in Cairo. The project connects a complete RV32I integer datapath and verifies it with component tests and instruction-level simulations.

**Authors:** Ziad Eliwa and Mostafa Abdelwahed.

## Architecture

The top-level module, [`cpu`](rtl/cpu.v), takes two inputs: `clk` and `rst`. Reset is active-high and asynchronous; it clears the program counter and register file to zero. The CPU has no external data or status ports, so the testbenches inspect its internal registers, memories, and PC.

- **Single-cycle execution:** instruction fetch, decode, execution, memory access, and writeback use one datapath cycle, without pipelining.
- **Register file:** 32 registers of 32 bits, two combinational read ports, and a rising-edge write port. Writes to `x0` are disabled, keeping it zero after reset.
- **ALU:** arithmetic, bitwise logic, signed and unsigned comparisons, and logical and arithmetic shifts. Zero, carry, sign, and overflow flags feed branch decisions.
- **Control:** separate main, ALU, and branch control units, with an immediate generator for instruction constants and offsets.
- **PC selection:** advances by four bytes, selects branch/jump targets, or holds at an `EBREAK`. `JAL` and `JALR` write `PC + 4` to the destination register; `JALR` clears target bit 0.
- **Separate memories:** instruction and data memories each contain 64 words (256 bytes). Instruction fetches and data reads are combinational; data writes occur on the rising clock edge.

![Single-cycle RISC-V datapath](docs/datapath/RISCV%20Single%20Cycle%20Datapath.png)

## Implemented Instructions

| Group | Instructions |
| --- | --- |
| Register arithmetic and logic | `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND` |
| Immediate arithmetic and logic | `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI` |
| Upper immediates | `LUI`, `AUIPC` |
| Loads | `LB`, `LH`, `LW`, `LBU`, `LHU` |
| Stores | `SB`, `SH`, `SW` |
| Conditional branches | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` |
| Jumps | `JAL`, `JALR` |
| Simplified system and fence behavior | `FENCE`, `FENCE.TSO`, `PAUSE`, and `ECALL` act as no-ops; `EBREAK` holds the PC |

The system behavior is specific to this educational implementation. It does not implement architectural traps, privileged execution, or CSRs. Multiplication/division and compressed instructions are also outside the design's scope.

## Repository Layout

```text
.
├── rtl/                    # CPU and supporting Verilog modules
├── tb/                     # 20 testbenches and shared instruction helpers
├── scripts/run_tests.sh    # Test runner with logs and pass/fail summary
├── constraints/            # FPGA pin constraints for clk and rst
├── docs/
│   ├── MS2_Report.pdf      # Milestone II design and verification report
│   ├── datapath/           # Processor datapath diagram
│   └── sim_results/        # Saved simulation screenshots
├── sw/                     # Reserved for software programs
├── .github/workflows/     # Verilator lint and simulation CI
├── Makefile                # Lint, simulation, and cleanup targets
└── LICENSE                 # MIT license
```

The main RTL modules are:

| Files in `rtl/` | Role |
| --- | --- |
| `cpu.v` | Connects the processor datapath |
| `control_unit.v`, `alu_control_unit.v`, `branch_cu.v` | Decode instructions and select ALU operations and branch outcomes |
| `prv32_ALU.v`, `shifter.v` | Execute arithmetic, logic, comparisons, and shifts |
| `imm_generator.v`, `defines.v` | Extract immediates and define shared instruction fields/constants |
| `register_file.v`, `decoder_5_by_32.v` | Store registers and select register writes |
| `instr_mem.v`, `data_mem.v` | Provide instruction and data storage |
| `dff.v`, `nbit_register.v`, `mux2x1.v`, `nbit_mux2by1.v`, `nbit_mux4by1.v` | Provide storage and datapath selection primitives |

## Getting Started

Install **Verilator**, **GNU Make**, and a **C++ compiler**. The shell test runner additionally uses Bash and standard Unix utilities, including `timeout`.

For Ubuntu/Debian:

```bash
sudo apt-get update
sudo apt-get install -y verilator build-essential
```

Run the following commands from the repository root:

```bash
# Lint the complete CPU hierarchy
make lint

# Compile and run all testbenches
make test

# Run a single testbench (omit the .v extension)
make test TB=branches_jumps_tb
```

The Makefile builds each simulation under `build/sim/obj_<testbench>/` and runs its `V<testbench>` executable. To remove the generated `build/` directory, run `make clean`.

For saved logs and an aggregate pass/fail summary, use the shell runner:

```bash
# Run the entire suite
bash scripts/run_tests.sh

# Run selected testbenches
bash scripts/run_tests.sh prv32_ALU_tb branches_jumps_tb
```

The runner saves compilation logs to `build/sim/<testbench>.compile.log` and simulation output to `build/sim/<testbench>.log`. It checks simulator exit status, rejects output containing `FAIL`, and requires a `TEST PASSED` or `TESTS PASSED` message. It continues through the selected tests and returns a nonzero status if any fail.

By default, the runner stores compiled simulation objects under `/tmp/riscv-processor-sim-<uid>/` and limits each simulation run to 120 seconds. Override these with `SIM_OBJ_DIR` and `SIM_TIMEOUT`, respectively. `make clean` removes `build/`; the runner's temporary object directory remains available for reuse.

## Verification

There are **15 component testbenches** for the ALU, shifter, control units, immediate generator, memories, register file, decoder, multiplexers, register, and flip-flop. Another **five testbenches** execute programs on the integrated CPU:

| Testbench | Coverage |
| --- | --- |
| `u_i_alu_tb` | Upper-immediate and immediate ALU instructions |
| `r_alu_tb` | Register-register arithmetic, logic, shifts, and comparisons |
| `loads_stores_tb` | Byte, halfword, and word accesses, including signed and unsigned loads |
| `branches_jumps_tb` | Taken and not-taken branches, a backward loop, and jump/link behavior |
| `system_fence_tb` | Fence/system no-ops and the `EBREAK` PC hold |

See [`tb/README.md`](tb/README.md) for the testbench inventory. Each testbench is compiled as a separate top-level module; [`common_tb.vh`](tb/common_tb.vh) is a shared include, not a standalone testbench. When compiling manually, supply both `-Irtl` and `-Itb` for the include files.

GitHub Actions runs `make lint` and `make test` on pushes to `main` and on pull requests. Simulation build outputs are uploaded as the `sim-output` artifact with a seven-day retention period. The shell runner's additional log-based checks apply when running `scripts/run_tests.sh`; the Makefile relies on simulator exit status.

## Loading Programs

Instruction memory starts filled with `NOP` (`ADDI x0, x0, 0`, encoding `0x00000013`). CPU testbenches load machine instructions directly into `uut.iMem.mem`; no assembler or executable loader is required by the supplied tests.

The shared testbench include provides mnemonic encoders such as `ADDI`, `ADD`, `LW`, and `BEQ`, plus helpers to assemble and execute small programs. Inside an existing CPU testbench, a program can be built with:

```verilog
new_prog;
emit(ADDI(1, 0, 10));  // x1 = 10
emit(ADDI(2, 0, 20));  // x2 = 20
emit(ADD(3, 1, 2));    // x3 = 30
end_prog;              // Emit JAL x0, 0 to stay in a self-loop
run_prog;              // Load instructions, reset, and run 100 cycles
chk(3, 32'd30, "addition");
```

These helpers assume a CPU instance named `uut` with `clk` and `rst` driven by the testbench. Programs must fit within the 64-word instruction memory. To add a test, use a filename ending in `_tb.v` or `_tb.sv` and give its top module the same name as the file without its extension. Both test entry points discover these files automatically.

## Memory Behavior and Limits

- Instruction memory indexes only `PC[7:2]`, so addresses outside its 256-byte window alias back into the array. Keep program targets within the allocated range and use word-aligned instruction addresses.
- Data memory accepts byte addresses `0` through `255` and uses little-endian byte lanes. Halfword accesses require two-byte alignment; word accesses require four-byte alignment.
- Misaligned halfword/word loads and out-of-range data reads return zero. Corresponding stores are ignored; no exception is raised.
- Reset clears the PC and registers. It does not clear either memory, and data memory has no explicit initialization; programs should store values before loading them.
- The FPGA constraints assign pins for `clk` and `rst`. Check the pin assignments against your target board before using them.

## Documentation

- [Milestone II report](docs/MS2_Report.pdf)
- [Datapath diagram](docs/datapath/RISCV%20Single%20Cycle%20Datapath.png)
- [Simulation screenshots](docs/sim_results/)
- [Ziad Eliwa's milestone journal](docs/Ziad_Eliwa_Journal_MS2.pdf)
- [Mostafa Abdelwahed's milestone journal](docs/Mostafa_Abdelwahed_Journal_MS2.pdf)

## License

This project is available under the [MIT License](LICENSE).
