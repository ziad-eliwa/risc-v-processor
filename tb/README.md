# RV32I single-cycle CPU testbenches

This folder splits the supplied monolithic `cpu_tb` into five independent, self-checking Verilog testbenches. No test cases, expected values, or instruction encoders were changed.

| Testbench | Coverage |
|---|---|
| `tb_u_i_alu.v` | LUI, AUIPC and I-type arithmetic, logic and shifts, x0 |
| `tb_r_alu.v` | R-type arithmetic, comparisons, logic and shifts |
| `tb_loads_stores.v` | LB, LH, LW, LBU, LHU, SB, SH, SW; sign extension and byte lanes |
| `tb_branches_jumps.v` | BEQ, BNE, BLT, BGE, BLTU, BGEU, JAL, JALR, backward branch |
| `tb_system_fence.v` | FENCE, FENCE.TSO, PAUSE, ECALL, EBREAK, PC halt |

`tb_common.vh` contains all shared encoders and test helpers. Add it as an include file to your project; **do not compile it as a separate top-level module**.

## Run

Select and compile **one** of the five `tb_*.v` files as the simulation top-level along with your CPU RTL source files. Ensure `tb_common.vh` is in your simulator's include path.

For Icarus Verilog, from this directory (assuming RTL is under `../rtl/`):

```sh
iverilog -g2012 -I. -s tb_u_i_alu -o sim.vvp tb_u_i_alu.v ../rtl/*.v
vvp sim.vvp
```

Change the top-level name and file for the other testbenches. CPU RTL paths must be adapted to your project.

## Important assumptions retained from original

- `cpu` has ports `clk` and `rst`; reset is active-high.
- Instruction memory is `uut.iMem.mem[0:63]` (word addressed).
- Register file is observable at `uut.RF.Q[0:31]` and PC at `uut.PCOut`.
- `RUN_CYCLES = 600` per test. Each program ends in a self-loop, except the EBREAK test.
- Group 5 assumes FENCE/FENCE.TSO/PAUSE/ECALL execute as NOPs and EBREAK halts PC. Those behaviors depend on the professor's implementation (ECALL/EBREAK are normally environment/trap instructions in RISC-V).
- `DATA_BASE = 0` and test addresses through 63 must be accessible in data memory.
- Customize the `IMEM`, `REGS`, and `PC` macros or the `BYTE_IMEM` flag as explained in the original testbench if your instance hierarchy differs.
- If your register file is not reset by `rst`, repeated runs may require an RTL-compatible register reset mechanism.

The supplied tests check **instruction execution**, not compliance with exception-handling behavior beyond the original design assumptions.
