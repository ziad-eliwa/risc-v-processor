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
    
            // Simple test values (0-255)
            emit(ADDI(1,  0, 100));
            emit(ADDI(20, 0, 200));
            emit(ADDI(15, 0, 150));
    
            // Store words
            emit(SW(1,  0, 10));
            emit(SW(20, 4, 10));
    
            // Load words
            emit(LW(2, 0, 10));
    
            // Load bytes
            emit(LB (3, 0, 10));
            emit(LBU(4, 0, 10));
            emit(LB (5, 4, 10));
            emit(LBU(6, 4, 10));
            emit(LB (7, 1, 10));
    
            // Load halfwords
            emit(LH (8, 0, 10));
            emit(LHU(9, 0, 10));
            emit(LH (11, 4, 10));
            emit(LHU(12, 4, 10));
    
            // Additional positive loads
            emit(LB(13, 0, 10));
            emit(LH(14, 4, 10));
    
            // Store byte
            emit(SW(0, 8, 10));
            emit(SB(15, 9, 10));
            emit(LW(16, 8, 10));
    
            // Store halfword
            emit(SW(0, 12, 10));
            emit(SH(15, 14, 10));
            emit(LW(17, 12, 10));
    
            // Verify previous words unchanged
            emit(LW(18, 0, 10));
            emit(LW(19, 4, 10));
    
            // Negative offset tests
            emit(ADDI(21, 10, 64));
            emit(SW(1, -4, 21));
            emit(LW(22, 60, 10));
            emit(LW(23, -4, 21));
    
            end_prog;
            run_prog;
    
            // Verify loads and stores
            chk(2,  32'd100, "SW + LW");
    
            chk(3,  32'd100, "LB");
            chk(4,  32'd100, "LBU");
            chk(5,  32'hFFFFFFC8, "LB sign extension");
            chk(6,  32'd200, "LBU zero extension");
            chk(7,  32'd0, "LB byte offset 1");
    
            chk(8,  32'd100, "LH");
            chk(9,  32'd100, "LHU");
            chk(11, 32'd200, "LH positive");
            chk(12, 32'd200, "LHU positive");
    
            chk(13, 32'd100, "LB positive");
            chk(14, 32'd200, "LH positive");
    
            chk(16, 32'd38400, "SB byte lane 1");
            chk(17, 32'h00960000, "SH upper half");
    
            chk(18, 32'd100, "Original word unchanged");
            chk(19, 32'd200, "Second word unchanged");
    
            chk(22, 32'd100, "SW negative offset");
            chk(23, 32'd100, "LW negative offset");
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
        if (failed == 0) $display(" ALL TEST PASSED");
        else             $display(" FAIL: %0d check(s) failed", failed);
        $display("==================================================");
        if (failed != 0) $fatal(1, "Test group 3 failed");
        $finish;
    end
endmodule
