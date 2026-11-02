`timescale 1ns/1ps
module alu_control_unit_tb;
reg [2:0] ALUOp, funct3; reg funct7b5; wire [3:0] alucn; integer errors;
alu_control_unit uut(.ALUOp(ALUOp),.funct3(funct3),.funct7b5(funct7b5),.alucn(alucn));
initial begin
    errors = 0;
    ALUOp=0; funct3=0; funct7b5=0;
    ALUOp=3'b000; funct3=3'b000; funct7b5=0;
    #2;
    if (!(alucn === 4'h0)) begin $display("FAIL: ADD address"); errors = errors + 1; end
    else $display("PASS: ADD address");
    ALUOp=3'b001; funct3=3'b000; funct7b5=0;
    #2;
    if (!(alucn === 4'h1)) begin $display("FAIL: SUB branch"); errors = errors + 1; end
    else $display("PASS: SUB branch");
    ALUOp=3'b100; funct3=3'b000; funct7b5=0;
    #2;
    if (!(alucn === 4'h3)) begin $display("FAIL: LUI pass B"); errors = errors + 1; end
    else $display("PASS: LUI pass B");
    ALUOp=3'b010; funct3=3'b000; funct7b5=0;
    #2;
    if (!(alucn === 4'h0)) begin $display("FAIL: ADD"); errors = errors + 1; end
    else $display("PASS: ADD");
    ALUOp=3'b010; funct3=3'b000; funct7b5=1;
    #2;
    if (!(alucn === 4'h1)) begin $display("FAIL: SUB"); errors = errors + 1; end
    else $display("PASS: SUB");
    ALUOp=3'b010; funct3=3'b001; funct7b5=0;
    #2;
    if (!(alucn === 4'h8)) begin $display("FAIL: SLL"); errors = errors + 1; end
    else $display("PASS: SLL");
    ALUOp=3'b010; funct3=3'b010; funct7b5=0;
    #2;
    if (!(alucn === 4'hD)) begin $display("FAIL: SLT"); errors = errors + 1; end
    else $display("PASS: SLT");
    ALUOp=3'b010; funct3=3'b011; funct7b5=0;
    #2;
    if (!(alucn === 4'hF)) begin $display("FAIL: SLTU"); errors = errors + 1; end
    else $display("PASS: SLTU");
    ALUOp=3'b010; funct3=3'b100; funct7b5=0;
    #2;
    if (!(alucn === 4'h7)) begin $display("FAIL: XOR"); errors = errors + 1; end
    else $display("PASS: XOR");
    ALUOp=3'b010; funct3=3'b101; funct7b5=0;
    #2;
    if (!(alucn === 4'h9)) begin $display("FAIL: SRL"); errors = errors + 1; end
    else $display("PASS: SRL");
    ALUOp=3'b010; funct3=3'b101; funct7b5=1;
    #2;
    if (!(alucn === 4'hA)) begin $display("FAIL: SRA"); errors = errors + 1; end
    else $display("PASS: SRA");
    ALUOp=3'b010; funct3=3'b110; funct7b5=0;
    #2;
    if (!(alucn === 4'h4)) begin $display("FAIL: OR"); errors = errors + 1; end
    else $display("PASS: OR");
    ALUOp=3'b010; funct3=3'b111; funct7b5=0;
    #2;
    if (!(alucn === 4'h5)) begin $display("FAIL: AND"); errors = errors + 1; end
    else $display("PASS: AND");
    ALUOp=3'b011; funct3=3'b000; funct7b5=1;
    #2;
    if (!(alucn === 4'h0)) begin $display("FAIL: ADDI ignores bit30"); errors = errors + 1; end
    else $display("PASS: ADDI ignores bit30");
    ALUOp=3'b011; funct3=3'b101; funct7b5=1;
    #2;
    if (!(alucn === 4'hA)) begin $display("FAIL: SRAI"); errors = errors + 1; end
    else $display("PASS: SRAI");
    if (errors == 0) $display("ALL alu_control_unit TESTS PASSED");
    else $display("alu_control_unit: %0d FAILED", errors);
    $finish;
end
endmodule
