# Pipelined RISC-V Processor

A 32-bit, five-stage pipelined RISC-V processor written in Verilog for **CSCE 3301 — Computer Architecture, Project 1 (Milestone III)** at the American University in Cairo. This milestone extends our previous single-cycle RV32I processor by adding pipeline registers, forwarding, hazard detection, branch prediction, and a shared memory for instructions and data.

**Authors:** Ziad Eliwa and Mostafa Abdelwahed.

## Architecture

The top-level module, [`cpu_p`](Verilog/cpu_p.v), has two inputs, `clk` and `rst`, and one output, `halted`. Reset is active-high and asynchronous. The default starting PC is `0x00000000`, and the testbenches inspect internal registers, memory, and pipeline signals.

- **Five pipeline stages:** Instruction Fetch (IF), Instruction Decode (ID), Execute (EX), Memory Access (MEM), and Writeback (WB).
- **Pipeline registers:** `IF/ID`, `ID/EX`, `EX/MEM`, and `MEM/WB` carry instructions, data, and control signals between stages. They are built using the reusable `register_p` module and update on rising clock edges.
- **Register file:** 32 registers of 32 bits, two combinational read ports, and falling-edge writes using `register_n`. Register `x0` remains zero.
- **ALU and control:** Support arithmetic, bitwise operations, shifts, comparisons, load/store address calculations, branches, and jumps.
- **Forwarding:** Results from EX/MEM and MEM/WB can be forwarded to the ALU operands when a newer instruction depends on an older result.
- **Hazard detection:** Load-use dependencies stall the PC and IF/ID register while inserting a bubble into ID/EX. Incorrectly predicted branches flush younger instructions.
- **Unified memory:** Instructions and data use one single-ported, byte-addressable memory. The default size is **1,024 words (4 KiB)**.
- **Halting:** `EBREAK` stops new instructions from entering the pipeline, allows older instructions to finish, and then asserts `halted`.

![Five-stage pipelined RV32I datapath](docs/MS3/RV32i%20Pipelined%20Datapath.png)

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
| Simplified system and fence behavior | `FENCE`, `FENCE.TSO`, `PAUSE`, and `ECALL` act as no-ops; `EBREAK` halts execution |

The instruction behavior follows the educational requirements of this project. Compressed instructions, multiplication/division, privileged operations, CSRs, and normal trap handling are not included.

## Bonus Features

### Bonus 1: 2-Bit Dynamic Branch Prediction

The processor uses a **Branch Target Buffer (BTB)** with a two-bit saturating counter for each entry. The default BTB has 32 entries. Each entry stores a valid bit, the branch PC tag, the predicted target address, and the counter.

The counter has four states: strongly not taken (`00`), weakly not taken (`01`), weakly taken (`10`), and strongly taken (`11`). New entries start in a not-taken state. The predictor uses the saved target when it predicts taken. Branches and jumps are checked in the EX stage; if the direction or target is wrong, the processor corrects the PC and flushes younger instructions. The predictor is then updated using the actual result.

The [`branch_predictor.v`](Verilog/branch_predictor.v), [`mispredict_detector.v`](Verilog/mispredict_detector.v), and [`pc_selector.v`](Verilog/pc_selector.v) modules handle this behavior.

### Bonus 2: Priority Arbitration with Pipeline Stalling

Because instructions and data use one memory port, instruction fetch and a MEM-stage load/store cannot access memory at the same time. Instead of fetching one instruction every two clock cycles, the processor gives **priority to the MEM stage** whenever a load or store needs the port.

When this happens, the PC is held and an instruction-fetch bubble is inserted. The older instructions in the pipeline can continue. Instruction fetching resumes as soon as the port is free. This avoids a fixed fetch delay on cycles without data-memory operations.

The memory selection multiplexers are connected in [`cpu_p.v`](Verilog/cpu_p.v), and the stall logic is in [`hazard_detection_unit.v`](Verilog/hazard_detection_unit.v).

## RTL Implementation

The CPU uses separate modules to make the design easier to inspect and debug. Pipeline storage uses `register_p`, and the datapath uses the supplied `nbit_mux4by1` and `nbit_mux2by1` modules for operand and address selection.

| Files in `Verilog/` | Role |
| --- | --- |
| `cpu_p.v` | Connects the full five-stage datapath |
| `control_unit.v`, `alu_control_unit.v`, `branch_cu.v` | Decode instructions and select ALU and branch behavior |
| `prv32_ALU.v`, `shifter.v` | Arithmetic, logic, comparisons, and shifts |
| `imm_generator.v`, `defines.v` | Immediate values and shared definitions |
| `register_file.v`, `decoder_5_by_32.v` | Architectural registers and register write selection |
| `register_p.v`, `register_n.v`, `dff_p.v`, `dff_n.v` | Rising-edge and falling-edge storage |
| `nbit_mux2by1.v`, `nbit_mux4by1.v`, `mux2x1.v` | Datapath selection |
| `forwarding_unit.v` | Forward values from later pipeline stages |
| `hazard_detection_unit.v` | Generate stalls and pipeline flushes |
| `branch_predictor.v`, `mispredict_detector.v`, `pc_selector.v` | Predict branches and recover from mispredictions |
| `single_ported_mem.v` | Shared instruction and data memory |

The pipeline registers update on the rising edge. Architectural register writes use the falling edge, so values written during WB can be read before the next rising edge. The shared memory has asynchronous reads and rising-edge writes.

## Repository Layout

```text
.
├── Verilog/                         # Working RTL modules, including cpu_p.v
├── test/
│   ├── programs/                   # Eight .hex programs and expected results
│   ├── tb_cpu_p.sv                  # Full processor testbench
│   ├── tb_branch_predictor.sv       # Predictor testbench
│   ├── tb_datapath_primitives.sv    # Register and mux testbench
│   ├── generate_tests.py           # Test images and expected states
│   ├── run_tests.py                # Icarus Verilog test runner
│   ├── check_modularity.py         # Static module/width checks
│   └── check_pipeline_schedule.py  # Independent Python pipeline model
├── docs/                            # Datapath, report, and debugging guide
├── journal/                         # Team journal files
├── reference_original/              # Original supplied Verilog files
├── Makefile
└── README.md
```

This layout matches the modular project package. If the files are moved into the earlier repository's `rtl/` and `tb/` folders, update the paths in the commands and test runner accordingly.

## Testing and Verification

The full-processor testbench runs these eight programs:

| Program | Main checks |
| --- | --- |
| `alu_all.mem` | Arithmetic, logic, shifts, upper immediates, and simplified system instructions |
| `loads_stores.mem` | Byte, halfword, and word loads/stores, including sign extension |
| `data_hazards.mem` | Forwarding, load-use stalls, store-data dependencies, and branch dependencies |
| `control_transfers.mem` | Conditional branches, `JAL`, `JALR`, and wrong-path flushing |
| `branch_training.mem` | Repeated branch outcomes and predictor training |
| `mem_arbitration.mem` | Repeated loads/stores and shared-memory port conflicts |
| `signed_boundaries.mem` | Signed versus unsigned comparisons and right shifts |
| `btb_alias.mem` | Two control transfers sharing a BTB index |

Each program has an expected register file image and an expected final memory image. The full-processor testbench compares these with the results at `EBREAK` and also checks for important stall and prediction events.

**Verification status:** The static modularity check and independent Python pipeline model pass all eight programs. These checks do **not** prove that the Verilog or FPGA implementation works. RTL simulations, Vivado synthesis, timing analysis, and board testing should be completed and recorded separately before submission.

## Loading Programs

The shared memory is initialized using `$readmemh`. Program images contain one 32-bit hexadecimal word per line; the first word is at byte address `0x00000000`. With the default `MEM_ADDR_WIDTH=10`, the memory holds 1,024 words (4 KiB).

To initialize a program in a testbench:

```verilog
cpu_p #(
    .MEM_ADDR_WIDTH(10),
    .MEM_INIT_FILE("program.mem")
) dut (
    .clk(clk),
    .rst(rst),
    .halted(halted)
);
```

In Vivado, add `program.mem` as a memory initialization source and make sure its filename or path matches `MEM_INIT_FILE`. The default reset PC is zero. Instruction addresses must be word-aligned. Programs and data share the same address space, so a program must not accidentally overwrite its own instructions.

The included directed tests use `.hex` files in `test/programs/`; these are also compatible with `$readmemh`. The optional greenhouse monitoring program is a larger demonstration that processes temperature readings and writes statistics and alarms to memory.

## Memory Behavior and Limits

- The default memory size is 4 KiB, shared by instructions and data. The size can be changed with `MEM_ADDR_WIDTH`.
- Memory is little-endian and supports bytes, halfwords, and words. Halfwords must be two-byte aligned and words must be four-byte aligned.
- Misaligned halfword/word reads return zero, while misaligned stores are ignored. No misalignment exception is generated.
- Reads outside the configured memory range return zero, and stores outside the range are ignored.
- Reset clears the PC, pipeline registers, and register file; it does not clear the memory contents.
- Memory reads are asynchronous. On an FPGA this may infer distributed memory rather than block RAM, depending on synthesis.
- Register file writes use the falling clock edge, which requires timing checks when targeting the FPGA.
- No interrupt controller, CSR file, privileged mode, or exception-handling system is implemented.

## Documentation

- [Datapath diagram](docs/MS3/RV32i%20Pipelined%20Datapath.png)
- [Design and implementation report](docs/MS3/CSCE_3301___Computer_Architecture_Project_1_Report_MS3.pdf)
- [Testing guide](tests/README.md)
- Milestone III individual journals for Ziad Eliwa and Mostafa Abdelwahed (add the completed files to `journal/` before submission)

## License

The Milestone II repository used the MIT License. Keep its `LICENSE` file when moving this milestone into the same repository.