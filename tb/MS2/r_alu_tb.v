`timescale 1ns/1ps
// RV32I single-cycle CPU standalone test group 2.
// Compile ONLY ONE tb_*.v top-level testbench at a time.
module r_alu_tb();
    reg clk, rst;
    cpu uut (.clk(clk), .rst(rst));
    always #10 clk = ~clk;

    `include "common_tb.vh"

    // ================================================================ GROUP 2
    // ADD SUB SLL SLT SLTU XOR SRL SRA OR AND
    
task group2;
    begin
        $display("\n== Group 2: R-type ALU ==");
        new_prog;

        // Initialize registers
        emit(ADDI(1, 0, 10));    // x1 = 10
        emit(ADDI(2, 0, 5));     // x2 = 5
        emit(ADDI(3, 0, 2));     // x3 = 2 (shift amount)
        emit(ADDI(17, 0, -8));   // x17 = -8

        // Arithmetic
        emit(ADD(4, 1, 2));     // 10 + 5 = 15
        emit(SUB(5, 1, 2));     // 10 - 5 = 5
        emit(SUB(6, 2, 1));     // 5 - 10 = -5

        // Left shift
        emit(SLL(7, 1, 3));     // 10 << 2 = 40

        // Signed and unsigned comparisons
        emit(SLT(8, 17, 2));    // -8 < 5 = 1 (signed)
        emit(SLTU(9, 17, 2));   // unsigned -8 < 5 = 0

        // Bitwise operations
        emit(XOR(10, 1, 2));    // 10 XOR 5 = 15
        emit(OR(13, 1, 2));     // 10 OR 5 = 15
        emit(AND(14, 1, 2));    // 10 AND 5 = 0

        // Right shifts
        emit(SRL(11, 1, 3));    // 10 >> 2 = 2
        emit(SRA(12, 17, 3));   // -8 >>> 2 = -2
        emit(SRL(18, 17, 3));   // Logical shift of -8

        // Reversed comparisons
        emit(SLT(15, 2, 17));   // 5 < -8 = 0 (signed)
        emit(SLTU(16, 2, 17));  // 5 < unsigned -8 = 1

        end_prog;
        run_prog;

        // Check results
        chk(4,  32'd15,       "ADD");
        chk(5,  32'd5,        "SUB");
        chk(6,  32'hFFFFFFFB, "SUB negative");

        chk(7,  32'd40,       "SLL");

        chk(8,  32'd1,        "SLT signed");
        chk(9,  32'd0,        "SLTU unsigned");

        chk(10, 32'd15,       "XOR");
        chk(13, 32'd15,       "OR");
        chk(14, 32'd0,        "AND");

        chk(11, 32'd2,        "SRL");
        chk(12, 32'hFFFFFFFE, "SRA negative");
        chk(18, 32'h3FFFFFFE, "SRL negative");

        chk(15, 32'd0,        "SLT reversed");
        chk(16, 32'd1,        "SLTU reversed");
    end
endtask



    initial begin
        clk = 0;
        rst = 1;
        total = 0;
        passed = 0;
        failed = 0;
        group2;
        $display("\n==================================================");
        $display(" %0d / %0d checks passed", passed, total);
        if (failed == 0) $display(" ALL TEST PASSED");
        else             $display(" FAIL: %0d check(s) failed", failed);
        $display("==================================================");
        if (failed != 0) $fatal(1, "Test group 2 failed");
        $finish;
    end
endmodule
