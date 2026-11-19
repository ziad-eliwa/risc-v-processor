`timescale 1ns/1ps
// RV32I single-cycle CPU standalone test group 5.
// Compile ONLY ONE tb_*.v top-level testbench at a time.
module system_fence_tb();
    reg clk, rst;
    cpu uut (.clk(clk), .rst(rst));
    always #10 clk = ~clk;

    `include "common_tb.vh"

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


    initial begin
        clk = 0;
        rst = 1;
        total = 0;
        passed = 0;
        failed = 0;
        group5;
        $display("\n==================================================");
        $display(" %0d / %0d checks passed", passed, total);
        if (failed == 0) $display(" ALL TEST PASSED");
        else             $display(" FAIL: %0d check(s) failed", failed);
        $display("==================================================");
        if (failed != 0) $fatal(1, "Test group 5 failed");
        $finish;
    end
endmodule
