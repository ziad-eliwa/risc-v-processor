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

        // LUI and AUIPC
        emit(LUI(1, 1));               // x1 = 4096
        a_auipc = pi * 4;
        emit(AUIPC(2, 1));             // x2 = PC + 4096

        // ADDI
        emit(ADDI(3, 0, 10));          // x3 = 10
        emit(ADDI(4, 0, 20));          // x4 = 20
        emit(ADDI(5, 3, 5));           // x5 = 15
        emit(ADDI(6, 0, -5));          // x6 = -5

        // Signed and unsigned comparisons
        emit(SLTI(7, 3, 15));          // 10 < 15 = 1
        emit(SLTI(8, 4, 15));          // 20 < 15 = 0
        emit(SLTIU(9, 3, 15));         // 10 < 15 = 1
        emit(SLTIU(10, 6, 1));         // unsigned -5 < 1 = 0

        // Bitwise operations
        emit(XORI(11, 3, 5));          // 10 XOR 5 = 15
        emit(ORI(12, 3, 5));           // 10 OR 5 = 15
        emit(ANDI(13, 3, 6));          // 10 AND 6 = 2

        // Shift operations
        emit(SLLI(14, 3, 2));          // 10 << 2 = 40
        emit(SRLI(15, 4, 2));          // 20 >> 2 = 5
        emit(SRAI(16, 4, 2));          // 20 >>> 2 = 5
        emit(SRAI(17, 6, 1));          // -5 >>> 1 = -3
        emit(SRLI(18, 6, 1));          // Logical right shift

        // x0 must remain zero
        emit(ADDI(0, 0, 10));

        end_prog;
        run_prog;

        // Check results
        chk(1,  32'd4096,          "LUI");
        chk(2,  a_auipc + 4096,   "AUIPC");

        chk(3,  32'd10,           "ADDI");
        chk(4,  32'd20,           "ADDI");
        chk(5,  32'd15,           "ADDI addition");
        chk(6,  32'hFFFFFFFB,     "ADDI negative");

        chk(7,  32'd1,            "SLTI true");
        chk(8,  32'd0,            "SLTI false");
        chk(9,  32'd1,            "SLTIU true");
        chk(10, 32'd0,            "SLTIU false");

        chk(11, 32'd15,           "XORI");
        chk(12, 32'd15,           "ORI");
        chk(13, 32'd2,            "ANDI");

        chk(14, 32'd40,           "SLLI");
        chk(15, 32'd5,            "SRLI");
        chk(16, 32'd5,            "SRAI positive");
        chk(17, 32'hFFFFFFFD,     "SRAI negative");
        chk(18, 32'h7FFFFFFD,     "SRLI negative");

        chk(0,  32'd0,            "x0 unchanged");
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
