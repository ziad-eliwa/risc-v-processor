`timescale 1ns/1ps
// RV32I single-cycle CPU standalone test group 3.
// Compile ONLY ONE *_tb.v top-level testbench at a time.
module loads_stores_tb();
    reg clk, rst;
    cpu uut (.clk(clk), .rst(rst));
    always #10 clk = ~clk;

    `include "common_tb.vh"

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


    initial begin
        clk = 0;
        rst = 1;
        total = 0;
        passed = 0;
        failed = 0;
        group3;
        $display("\n==================================================");
        $display(" %0d / %0d checks passed", passed, total);
        if (failed == 0) $display(" ALL TESTS PASSED");
        else             $display(" FAIL: %0d check(s) failed", failed);
        $display("==================================================");
        if (failed != 0) $fatal(1, "Test group 3 failed");
        $finish;
    end
endmodule
