`timescale 1ns/1ps
// RV32I single-cycle CPU standalone test group 1.
// Compile ONLY ONE tb_*.v top-level testbench at a time.
module u_i_alu_tb();
    reg clk, rst;
    cpu uut (.clk(clk), .rst(rst));
    always #10 clk = ~clk;

    `include "common_tb.vh"

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


    initial begin
        clk = 0;
        rst = 1;
        total = 0;
        passed = 0;
        failed = 0;
        group1;
        $display("\n==================================================");
        $display(" %0d / %0d checks passed", passed, total);
        if (failed == 0) $display(" ALL TEST PASSED");
        else             $display(" FAIL: %0d check(s) failed", failed);
        $display("==================================================");
        if (failed != 0) $fatal(1, "Test group 1 failed");
        $finish;
    end
endmodule
