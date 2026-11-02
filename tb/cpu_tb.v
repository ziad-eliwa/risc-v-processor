`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/26/2026 02:10:42 PM
// Design Name: 
// Module Name: shifter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns/1ps
// ============================================================================
//  Self-checking testbench for a RISC-V CPU (42 instructions)
//
//  LUI AUIPC JAL JALR BEQ BNE BLT BGE BLTU BGEU LB LH LW LBU LHU SB SH SW
//  ADDI SLTI SLTIU XORI ORI ANDI SLLI SRLI SRAI ADD SUB SLL SLT SLTU XOR SRL
//  SRA OR AND FENCE FENCE.TSO PAUSE ECALL EBREAK
//
//  HOW IT WORKS
//   * Programs are assembled inside the testbench (encoder functions below),
//     so no .hex files are needed.
//   * Each test group: load program -> reset -> run -> compare register file
//     (and data memory results, read back through LW) against expected values.
//
//  HIERARCHICAL PATHS (matched to cpu.v instance names iMem / RF / PCOut):
//     IMEM : instruction-memory array inside instr_mem   -> uut.iMem.<array>
//     REGS : register-file array inside register_file    -> uut.RF.<array>
//     PC   : program counter output wire                 -> uut.PCOut
//  Matched to instr_mem (reg [31:0] mem [0:63]) and register_file (Q[31:0]).
//  Registers are cleared by the reset pulse, not by the testbench, because
//  Q is a wire array and cannot be assigned from here.
//  If instr_mem is ever changed to a BYTE array define BYTE_IMEM.
//
//  ASSUMPTIONS: reset is active-high, PC starts at 0 after reset, and the data
//  memory is reachable at DATA_BASE (change it if your dmem is smaller/larger).
// ============================================================================

`ifndef IMEM
 `define IMEM uut.iMem.mem
`endif
`ifndef REGS
 `define REGS uut.RF.Q       // wire [N-1:0] Q [31:0]: read-only from the TB
`endif
`ifndef PC
 `define PC   uut.PCOut
`endif

module cpu_tb();
    reg clk, rst;

    cpu uut (
        .clk(clk),
        .rst(rst)
    );

    always #10 clk = ~clk;

    // ------------------------------------------------------------------ knobs
    localparam PROG_WORDS = 64;       // size of instr_mem (words)
    localparam RUN_CYCLES = 600;      // increase for multi-cycle / deep pipelines
    localparam DATA_BASE  = 12'h000;  // tests touch DATA_BASE .. DATA_BASE+63; must fit in data_mem
    localparam [31:0] NOP       = 32'h00000013;
    localparam [31:0] FENCE     = 32'h0FF0000F;  // fence iorw,iorw
    localparam [31:0] FENCE_TSO = 32'h8330000F;
    localparam [31:0] PAUSE     = 32'h0100000F;
    localparam [31:0] ECALL     = 32'h00000073;
    localparam [31:0] EBREAK    = 32'h00100073;

    // -------------------------------------------------------------- encoders
    function [31:0] enc_r; input integer f7, rs2, rs1, f3, rd, op;
        enc_r = ((f7&127)<<25) | ((rs2&31)<<20) | ((rs1&31)<<15) |
                ((f3&7)<<12)   | ((rd&31)<<7)   | (op&127);
    endfunction
    function [31:0] enc_i; input integer imm, rs1, f3, rd, op;
        enc_i = ((imm&32'hFFF)<<20) | ((rs1&31)<<15) | ((f3&7)<<12) |
                ((rd&31)<<7) | (op&127);
    endfunction
    function [31:0] enc_s; input integer imm, rs2, rs1, f3;
        enc_s = (((imm>>5)&127)<<25) | ((rs2&31)<<20) | ((rs1&31)<<15) |
                ((f3&7)<<12) | ((imm&31)<<7) | 7'h23;
    endfunction
    function [31:0] enc_b; input integer off, rs2, rs1, f3;
        enc_b = (((off>>12)&1)<<31) | (((off>>5)&63)<<25) | ((rs2&31)<<20) |
                ((rs1&31)<<15) | ((f3&7)<<12) | (((off>>1)&15)<<8) |
                (((off>>11)&1)<<7) | 7'h63;
    endfunction
    function [31:0] enc_u; input integer imm20, rd, op;
        enc_u = ((imm20&32'hFFFFF)<<12) | ((rd&31)<<7) | (op&127);
    endfunction
    function [31:0] enc_j; input integer off, rd;
        enc_j = (((off>>20)&1)<<31) | (((off>>1)&1023)<<21) |
                (((off>>11)&1)<<20) | (((off>>12)&255)<<12) |
                ((rd&31)<<7) | 7'h6F;
    endfunction

    // ---------------------------------------------------- mnemonic functions
    // asm-style argument order: rd, rs1, rs2/imm   (stores: rs2, imm, rs1)
    function [31:0] LUI;   input integer rd, imm20;       LUI   = enc_u(imm20, rd, 7'h37); endfunction
    function [31:0] AUIPC; input integer rd, imm20;       AUIPC = enc_u(imm20, rd, 7'h17); endfunction
    function [31:0] JAL;   input integer rd, off;         JAL   = enc_j(off, rd);          endfunction
    function [31:0] JALR;  input integer rd, rs1, imm;    JALR  = enc_i(imm, rs1, 0, rd, 7'h67); endfunction

    function [31:0] BEQ;   input integer rs1, rs2, off;   BEQ  = enc_b(off, rs2, rs1, 0); endfunction
    function [31:0] BNE;   input integer rs1, rs2, off;   BNE  = enc_b(off, rs2, rs1, 1); endfunction
    function [31:0] BLT;   input integer rs1, rs2, off;   BLT  = enc_b(off, rs2, rs1, 4); endfunction
    function [31:0] BGE;   input integer rs1, rs2, off;   BGE  = enc_b(off, rs2, rs1, 5); endfunction
    function [31:0] BLTU;  input integer rs1, rs2, off;   BLTU = enc_b(off, rs2, rs1, 6); endfunction
    function [31:0] BGEU;  input integer rs1, rs2, off;   BGEU = enc_b(off, rs2, rs1, 7); endfunction

    function [31:0] LB;    input integer rd, imm, rs1;     LB  = enc_i(imm, rs1, 0, rd, 7'h03); endfunction
    function [31:0] LH;    input integer rd, imm, rs1;     LH  = enc_i(imm, rs1, 1, rd, 7'h03); endfunction
    function [31:0] LW;    input integer rd, imm, rs1;     LW  = enc_i(imm, rs1, 2, rd, 7'h03); endfunction
    function [31:0] LBU;   input integer rd, imm, rs1;     LBU = enc_i(imm, rs1, 4, rd, 7'h03); endfunction
    function [31:0] LHU;   input integer rd, imm, rs1;     LHU = enc_i(imm, rs1, 5, rd, 7'h03); endfunction
    function [31:0] SB;    input integer rs2, imm, rs1;    SB  = enc_s(imm, rs2, rs1, 0); endfunction
    function [31:0] SH;    input integer rs2, imm, rs1;    SH  = enc_s(imm, rs2, rs1, 1); endfunction
    function [31:0] SW;    input integer rs2, imm, rs1;    SW  = enc_s(imm, rs2, rs1, 2); endfunction

    function [31:0] ADDI;  input integer rd, rs1, imm;     ADDI  = enc_i(imm, rs1, 0, rd, 7'h13); endfunction
    function [31:0] SLTI;  input integer rd, rs1, imm;     SLTI  = enc_i(imm, rs1, 2, rd, 7'h13); endfunction
    function [31:0] SLTIU; input integer rd, rs1, imm;     SLTIU = enc_i(imm, rs1, 3, rd, 7'h13); endfunction
    function [31:0] XORI;  input integer rd, rs1, imm;     XORI  = enc_i(imm, rs1, 4, rd, 7'h13); endfunction
    function [31:0] ORI;   input integer rd, rs1, imm;     ORI   = enc_i(imm, rs1, 6, rd, 7'h13); endfunction
    function [31:0] ANDI;  input integer rd, rs1, imm;     ANDI  = enc_i(imm, rs1, 7, rd, 7'h13); endfunction
    function [31:0] SLLI;  input integer rd, rs1, sh;      SLLI  = enc_i(sh&31,          rs1, 1, rd, 7'h13); endfunction
    function [31:0] SRLI;  input integer rd, rs1, sh;      SRLI  = enc_i(sh&31,          rs1, 5, rd, 7'h13); endfunction
    function [31:0] SRAI;  input integer rd, rs1, sh;      SRAI  = enc_i(12'h400|(sh&31), rs1, 5, rd, 7'h13); endfunction

    function [31:0] ADD;   input integer rd, rs1, rs2;     ADD  = enc_r(7'h00, rs2, rs1, 0, rd, 7'h33); endfunction
    function [31:0] SUB;   input integer rd, rs1, rs2;     SUB  = enc_r(7'h20, rs2, rs1, 0, rd, 7'h33); endfunction
    function [31:0] SLL;   input integer rd, rs1, rs2;     SLL  = enc_r(7'h00, rs2, rs1, 1, rd, 7'h33); endfunction
    function [31:0] SLT;   input integer rd, rs1, rs2;     SLT  = enc_r(7'h00, rs2, rs1, 2, rd, 7'h33); endfunction
    function [31:0] SLTU;  input integer rd, rs1, rs2;     SLTU = enc_r(7'h00, rs2, rs1, 3, rd, 7'h33); endfunction
    function [31:0] XOR;   input integer rd, rs1, rs2;     XOR  = enc_r(7'h00, rs2, rs1, 4, rd, 7'h33); endfunction
    function [31:0] SRL;   input integer rd, rs1, rs2;     SRL  = enc_r(7'h00, rs2, rs1, 5, rd, 7'h33); endfunction
    function [31:0] SRA;   input integer rd, rs1, rs2;     SRA  = enc_r(7'h20, rs2, rs1, 5, rd, 7'h33); endfunction
    function [31:0] OR;    input integer rd, rs1, rs2;     OR   = enc_r(7'h00, rs2, rs1, 6, rd, 7'h33); endfunction
    function [31:0] AND;   input integer rd, rs1, rs2;     AND  = enc_r(7'h00, rs2, rs1, 7, rd, 7'h33); endfunction

    // ------------------------------------------------- program build helpers
    reg [31:0] prog [0:PROG_WORDS-1];
    integer pi, k;
    integer total, passed, failed;

    task new_prog;
        begin
            for (k = 0; k < PROG_WORDS; k = k + 1) prog[k] = NOP;
            pi = 0;
        end
    endtask

    task emit; input [31:0] w;
        begin prog[pi] = w; pi = pi + 1; end
    endtask

    // load 32-bit constant (LUI + ADDI, with the +0x800 carry fix)
    task li; input integer rd; input [31:0] val;
        begin
            emit(LUI (rd, (val + 32'h800) >> 12));
            emit(ADDI(rd, rd, val & 32'hFFF));
        end
    endtask

    task end_prog;                       // park the CPU in a self-loop
        begin emit(JAL(0, 0)); end
    endtask

    // single place to change if your imem layout differs
    task write_instr; input integer idx; input [31:0] w;
        begin
`ifdef BYTE_IMEM
            `IMEM[4*idx+0] = w[7:0];
            `IMEM[4*idx+1] = w[15:8];
            `IMEM[4*idx+2] = w[23:16];
            `IMEM[4*idx+3] = w[31:24];
`else
            `IMEM[idx] = w;
`endif
        end
    endtask

    task run_prog;
        begin
            rst = 1;
            for (k = 0; k < PROG_WORDS; k = k + 1) write_instr(k, prog[k]);
`ifdef CLEAR_REGS   // only if your regfile is a assignable reg array
            for (k = 0; k < 32; k = k + 1)         `REGS[k] = 32'h0;
`endif
            repeat (3) @(posedge clk);
            @(negedge clk) rst = 0;
            repeat (RUN_CYCLES) @(posedge clk);
            #1;
        end
    endtask

    task chk; input integer r; input [31:0] exp; input [8*26-1:0] name;
        reg [31:0] got;
        begin
            got   = `REGS[r];
            total = total + 1;
            if (got === exp) begin
                passed = passed + 1;
                $display("TEST PASSED: %0s (x%0d = %h)", name, r, got);
            end else begin
                failed = failed + 1;
                $display("FAIL: %0s (x%0d = %h, expected %h)", name, r, got, exp);
            end
        end
    endtask

    // ================================================================ GROUP 1
    // LUI AUIPC ADDI SLTI SLTIU XORI ORI ANDI SLLI SRLI SRAI
    integer a_auipc;
    task group1;
        begin
            $display("\n== Group 1: U-type and I-type ALU ==");
            new_prog;
            emit(LUI(1, 20'h12345));
            a_auipc = pi * 4;
            emit(AUIPC(2, 20'h00001));
            emit(ADDI(3, 0, -5));
            li(5, 32'hF0F01234);
            emit(ADDI (7, 5, 1));
            emit(SLTI (8, 3, 1));        // -5 < 1 signed      -> 1
            emit(SLTIU(9, 3, 1));        // 0xFFFFFFFB < 1 u   -> 0
            emit(SLTIU(10, 0, 1));       // 0 < 1 u            -> 1
            emit(SLTI (29, 3, -6));      // -5 < -6            -> 0 (sign-ext imm)
            emit(XORI (12, 5, -1));
            emit(ORI  (13, 5, 12'h0F0));
            emit(ANDI (14, 5, 12'h7F0));
            emit(SLLI (15, 5, 4));
            emit(SRLI (16, 5, 4));
            emit(SRAI (17, 5, 4));
            emit(SRAI (18, 5, 31));
            emit(SRLI (19, 5, 31));
            emit(ANDI (20, 5, -16));
            emit(ADDI (0, 0, 5));        // writes to x0 must be ignored
            end_prog;
            run_prog;

            chk(1,  32'h12345000,        "LUI");
            chk(2,  a_auipc + 32'h1000,  "AUIPC");
            chk(3,  32'hFFFFFFFB,        "ADDI (negative imm)");
            chk(5,  32'hF0F01234,        "LUI+ADDI constant");
            chk(7,  32'hF0F01235,        "ADDI");
            chk(8,  32'h1,               "SLTI");
            chk(9,  32'h0,               "SLTIU (unsigned compare)");
            chk(10, 32'h1,               "SLTIU (seqz)");
            chk(29, 32'h0,               "SLTI (imm sign-extend)");
            chk(12, 32'h0F0FEDCB,        "XORI -1");
            chk(13, 32'hF0F012F4,        "ORI");
            chk(14, 32'h00000230,        "ANDI");
            chk(15, 32'h0F012340,        "SLLI");
            chk(16, 32'h0F0F0123,        "SRLI");
            chk(17, 32'hFF0F0123,        "SRAI");
            chk(18, 32'hFFFFFFFF,        "SRAI by 31");
            chk(19, 32'h00000001,        "SRLI by 31");
            chk(20, 32'hF0F01230,        "ANDI negative imm");
            chk(0,  32'h0,               "x0 hardwired zero");
        end
    endtask

    // ================================================================ GROUP 2
    // ADD SUB SLL SLT SLTU XOR SRL SRA OR AND
    task group2;
        begin
            $display("\n== Group 2: R-type ALU ==");
            new_prog;
            li(1, 32'h87654321);
            li(2, 32'h0F0F0F0F);
            emit(ADDI(3, 0, 36));        // shift amount; only low 5 bits (=4) count
            emit(ADD (4,  1, 2));
            emit(SUB (5,  1, 2));
            emit(SUB (6,  2, 1));
            emit(SLL (7,  1, 3));
            emit(SLT (8,  1, 2));
            emit(SLTU(9,  1, 2));
            emit(XOR (10, 1, 2));
            emit(SRL (11, 1, 3));
            emit(SRA (12, 1, 3));
            emit(OR  (13, 1, 2));
            emit(AND (14, 1, 2));
            emit(SLT (15, 2, 1));
            emit(SLTU(16, 2, 1));
            end_prog;
            run_prog;

            chk(4,  32'h96745230, "ADD");
            chk(5,  32'h78563412, "SUB");
            chk(6,  32'h87A9CBEE, "SUB (negative result)");
            chk(7,  32'h76543210, "SLL (rs2[4:0])");
            chk(8,  32'h1,        "SLT  (signed)");
            chk(9,  32'h0,        "SLTU (unsigned)");
            chk(10, 32'h886A4C2E, "XOR");
            chk(11, 32'h08765432, "SRL");
            chk(12, 32'hF8765432, "SRA");
            chk(13, 32'h8F6F4F2F, "OR");
            chk(14, 32'h07050301, "AND");
            chk(15, 32'h0,        "SLT  (reversed)");
            chk(16, 32'h1,        "SLTU (reversed)");
        end
    endtask

    // ================================================================ GROUP 3
    // LB LH LW LBU LHU SB SH SW
    task group3;
        begin
            $display("\n== Group 3: Loads and stores ==");
            new_prog;
            emit(ADDI(10, 0, DATA_BASE));
            li(1,  32'h8091A2B3);
            li(20, 32'h7F6E5D4C);
            li(15, 32'h112233AB);
            emit(SW(1, 0, 10));
            emit(SW(20, 4, 10));
            emit(LW (2,  0, 10));
            emit(LB (3,  0, 10));
            emit(LBU(4,  0, 10));
            emit(LB (5,  3, 10));
            emit(LBU(6,  3, 10));
            emit(LB (7,  1, 10));
            emit(LH (8,  0, 10));
            emit(LHU(9,  0, 10));
            emit(LH (11, 2, 10));
            emit(LHU(12, 2, 10));
            emit(LB (13, 4, 10));        // positive byte
            emit(LH (14, 6, 10));        // positive half
            emit(SW (0, 8, 10));         // clear word, then partial stores
            emit(SB (15, 9, 10));
            emit(LW (16, 8, 10));
            emit(SW (0, 12, 10));
            emit(SH (15, 14, 10));
            emit(LW (17, 12, 10));
            emit(LW (18, 0, 10));        // untouched by SB/SH
            emit(LW (19, 4, 10));
            emit(ADDI(21, 10, 64));      // negative offsets in store and load
            emit(SW (1, -4, 21));
            emit(LW (22, 60, 10));
            emit(LW (23, -4, 21));
            end_prog;
            run_prog;

            chk(2,  32'h8091A2B3, "SW + LW");
            chk(3,  32'hFFFFFFB3, "LB  (sign-extend)");
            chk(4,  32'h000000B3, "LBU (zero-extend)");
            chk(5,  32'hFFFFFF80, "LB  offset 3");
            chk(6,  32'h00000080, "LBU offset 3");
            chk(7,  32'hFFFFFFA2, "LB  offset 1");
            chk(8,  32'hFFFFA2B3, "LH  (sign-extend)");
            chk(9,  32'h0000A2B3, "LHU (zero-extend)");
            chk(11, 32'hFFFF8091, "LH  offset 2");
            chk(12, 32'h00008091, "LHU offset 2");
            chk(13, 32'h0000004C, "LB  positive");
            chk(14, 32'h00007F6E, "LH  positive");
            chk(16, 32'h0000AB00, "SB  (byte lane 1 only)");
            chk(17, 32'h33AB0000, "SH  (upper half only)");
            chk(18, 32'h8091A2B3, "neighbours untouched");
            chk(19, 32'h7F6E5D4C, "SW at offset 4");
            chk(22, 32'h8091A2B3, "SW negative offset");
            chk(23, 32'h8091A2B3, "LW negative offset");
        end
    endtask

    // ================================================================ GROUP 4
    // BEQ BNE BLT BGE BLTU BGEU JAL JALR
    //   x27 : "branch wrongly NOT taken" mask  -> expected 0
    //   x28 : "branch correctly not taken" mask -> expected 8'hFF
    integer a_jal, a_jalr;
    task group4;
        begin
            $display("\n== Group 4: Branches and jumps ==");
            new_prog;
            emit(ADDI(27, 0, 0));
            emit(ADDI(28, 0, 0));
            emit(ADDI(26, 0, 0));
            emit(ADDI(1, 0, 5));
            emit(ADDI(2, 0, 5));
            emit(ADDI(3, 0, -1));
            emit(ADDI(4, 0, 1));

            // taken branches (+8 skips the "bad" instruction)
            emit(BEQ (1, 2, 8)); emit(ADDI(27, 27, 12'h001));
            emit(BNE (1, 4, 8)); emit(ADDI(27, 27, 12'h002));
            emit(BLT (3, 4, 8)); emit(ADDI(27, 27, 12'h004));
            emit(BGE (4, 3, 8)); emit(ADDI(27, 27, 12'h008));
            emit(BLTU(4, 3, 8)); emit(ADDI(27, 27, 12'h010));
            emit(BGEU(3, 4, 8)); emit(ADDI(27, 27, 12'h020));
            emit(BGE (1, 2, 8)); emit(ADDI(27, 27, 12'h040));   // equal
            emit(BGEU(1, 2, 8)); emit(ADDI(27, 27, 12'h080));   // equal

            // not-taken branches (good instruction executes only if NOT taken)
            emit(BEQ (1, 4, 8)); emit(ADDI(28, 28, 12'h001));
            emit(BNE (1, 2, 8)); emit(ADDI(28, 28, 12'h002));
            emit(BLT (4, 3, 8)); emit(ADDI(28, 28, 12'h004));
            emit(BGE (3, 4, 8)); emit(ADDI(28, 28, 12'h008));   // signed!
            emit(BLTU(3, 4, 8)); emit(ADDI(28, 28, 12'h010));
            emit(BGEU(4, 3, 8)); emit(ADDI(28, 28, 12'h020));
            emit(BLT (1, 2, 8)); emit(ADDI(28, 28, 12'h040));   // equal
            emit(BLTU(1, 2, 8)); emit(ADDI(28, 28, 12'h080));   // equal

            // backward branch: loop 3 times
            emit(ADDI(25, 0, 0));
            emit(ADDI(24, 0, 3));
            emit(ADDI(25, 25, 1));
            emit(BNE (25, 24, -4));

            // JAL: skip one instruction, link = address of next instruction
            a_jal = pi * 4;
            emit(JAL (20, 8));
            emit(ADDI(26, 26, 1));

            // JALR: target = (rs1 + imm) & ~1  -> odd imm tests the LSB clear
            a_jalr = pi * 4;
            emit(AUIPC(21, 0));
            emit(ADDI (21, 21, 17));
            emit(JALR (22, 21, 0));
            emit(ADDI (26, 26, 2));
            emit(AUIPC(23, 0));          // JALR target: records the PC we landed on
            end_prog;
            run_prog;

            chk(27, 32'h0,          "taken branches (fail mask)");
            chk(28, 32'h000000FF,   "not-taken branches");
            chk(25, 32'h3,          "backward branch loop");
            chk(20, a_jal + 4,      "JAL link");
            chk(22, a_jalr + 12,    "JALR link");
            chk(26, 32'h0,          "JAL/JALR skipped code");
            chk(23, a_jalr + 16,    "JALR clears target bit 0");
        end
    endtask

    // ================================================================ GROUP 5
    // FENCE FENCE.TSO PAUSE ECALL (NOPs) and EBREAK (halts PC)
    reg [31:0] pc_a, pc_b;
    integer a_ebreak;
    task group5;
        begin
            $display("\n== Group 5: FENCE / FENCE.TSO / PAUSE / ECALL / EBREAK ==");
            new_prog;
            emit(ADDI(1, 0, 12'h11));
            emit(FENCE);
            emit(ADDI(2, 0, 12'h22));
            emit(FENCE_TSO);
            emit(ADDI(3, 0, 12'h33));
            emit(PAUSE);
            emit(ADDI(4, 0, 12'h44));
            emit(ECALL);
            emit(ADDI(5, 0, 12'h55));
            a_ebreak = pi * 4;
            emit(EBREAK);
            emit(ADDI(6, 0, 12'h66));    // must NOT execute
            emit(ADDI(7, 0, 12'h77));    // must NOT execute
            run_prog;

            chk(1, 32'h11, "ran before FENCE");
            chk(2, 32'h22, "ran after FENCE (NOP)");
            chk(3, 32'h33, "ran after FENCE.TSO (NOP)");
            chk(4, 32'h44, "ran after PAUSE (NOP)");
            chk(5, 32'h55, "ran after ECALL (NOP)");
            chk(6, 32'h0,  "EBREAK blocks next instr");
            chk(7, 32'h0,  "EBREAK blocks 2nd next");

            // PC must be frozen
            pc_a = `PC;
            repeat (20) @(posedge clk);
            #1;
            pc_b = `PC;
            total = total + 1;
            if (pc_a === pc_b && pc_b === a_ebreak) begin
                passed = passed + 1;
                $display("TEST PASSED: EBREAK halts PC (pc = %h, stable)", pc_b);
            end else begin
                failed = failed + 1;
                $display("FAIL: EBREAK halts PC (pc %h -> %h, EBREAK is at %h)",
                         pc_a, pc_b, a_ebreak);
            end
        end
    endtask

    // ============================================================ TOP LEVEL
    initial begin
        clk = 0; rst = 1;
        total = 0; passed = 0; failed = 0;

        group1;
        group2;
        group3;
        group4;
        group5;

        $display("\n==================================================");
        $display(" %0d / %0d checks passed", passed, total);
        if (failed == 0) $display(" ALL TESTS PASSED");
        else             $display(" FAIL: %0d check(s) failed", failed);
        $display("==================================================");
        $finish;
    end

endmodule
