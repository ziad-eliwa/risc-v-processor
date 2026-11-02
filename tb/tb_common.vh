// Shared declarations, instruction encoders, and self-checking helpers.
// Include INSIDE the testbench module, after the CPU instance.
`ifndef IMEM
 `define IMEM uut.iMem.mem
`endif
`ifndef REGS
 `define REGS uut.RF.Q       // wire [N-1:0] Q [31:0]: read-only from the TB
`endif
`ifndef PC
 `define PC   uut.PCOut
`endif

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
