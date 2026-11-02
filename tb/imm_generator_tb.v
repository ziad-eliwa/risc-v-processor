`timescale 1ns/1ps
module imm_generator_tb;
reg [31:0] instr; wire [31:0] imm; integer errors;
imm_generator uut(.instr(instr),.imm(imm));
initial begin
    errors = 0;
    instr=0;
    instr=32'h07B00013;
    #2;
    if (!(imm === 32'h0000007B)) begin $display("FAIL: ADDI positive"); errors = errors + 1; end
    else $display("PASS: ADDI positive");
    instr=32'hFFC00013;
    #2;
    if (!(imm === 32'hFFFFFFFC)) begin $display("FAIL: ADDI negative"); errors = errors + 1; end
    else $display("PASS: ADDI negative");
    instr=32'hFF800003;
    #2;
    if (!(imm === 32'hFFFFFFF8)) begin $display("FAIL: load default I"); errors = errors + 1; end
    else $display("PASS: load default I");
    instr=32'hFE000A23;
    #2;
    if (!(imm === 32'hFFFFFFF4)) begin $display("FAIL: store negative"); errors = errors + 1; end
    else $display("PASS: store negative");
    instr=32'h00000863;
    #2;
    if (!(imm === 32'h00000010)) begin $display("FAIL: branch positive"); errors = errors + 1; end
    else $display("PASS: branch positive");
    instr=32'hFE000CE3;
    #2;
    if (!(imm === 32'hFFFFFFF8)) begin $display("FAIL: branch negative"); errors = errors + 1; end
    else $display("PASS: branch negative");
    instr=32'h12345037;
    #2;
    if (!(imm === 32'h12345000)) begin $display("FAIL: LUI"); errors = errors + 1; end
    else $display("PASS: LUI");
    instr=32'hABCDE017;
    #2;
    if (!(imm === 32'hABCDE000)) begin $display("FAIL: AUIPC"); errors = errors + 1; end
    else $display("PASS: AUIPC");
    instr=32'h0200006F;
    #2;
    if (!(imm === 32'h00000020)) begin $display("FAIL: JAL positive"); errors = errors + 1; end
    else $display("PASS: JAL positive");
    instr=32'hFF1FF06F;
    #2;
    if (!(imm === 32'hFFFFFFF0)) begin $display("FAIL: JAL negative"); errors = errors + 1; end
    else $display("PASS: JAL negative");
    instr=32'hFE800067;
    #2;
    if (!(imm === 32'hFFFFFFE8)) begin $display("FAIL: JALR negative"); errors = errors + 1; end
    else $display("PASS: JALR negative");
    if (errors == 0) $display("ALL imm_generator TESTS PASSED");
    else $display("imm_generator: %0d FAILED", errors);
    $finish;
end
endmodule
