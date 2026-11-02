`timescale 1ns/1ps
// RV32I single-cycle CPU standalone test group 4.
// Compile ONLY ONE tb_*.v top-level testbench at a time.
module tb_branches_jumps();
    reg clk, rst;
    cpu uut (.clk(clk), .rst(rst));
    always #10 clk = ~clk;

    `include "tb_common.vh"

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


    initial begin
        clk = 0;
        rst = 1;
        total = 0;
        passed = 0;
        failed = 0;
        group4;
        $display("\n==================================================");
        $display(" %0d / %0d checks passed", passed, total);
        if (failed == 0) $display(" ALL TESTS PASSED");
        else             $display(" FAIL: %0d check(s) failed", failed);
        $display("==================================================");
        if (failed != 0) $fatal(1, "Test group 4 failed");
        $finish;
    end
endmodule
