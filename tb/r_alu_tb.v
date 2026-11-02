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
