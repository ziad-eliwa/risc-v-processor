`timescale 1ns/1ps
// ALUSrc1 selects PC vs rs1. ALUSrc2: 00=rs2, 01=immediate, 10=4.
// EBREAK recognition is exact in cpu_p (full instruction comparison).
module control_unit (
    input wire [6:0] opcode, input wire bit20,
    output reg Branch, Jump, MemRead, MemtoReg, MemWrite,
               ALUSrc1, RegWrite, PCSrc, Jalr, HaltSel,
    output reg [2:0] ALUOp,
    output reg [1:0] ALUSrc2
);
    always @* begin
        Branch=0; Jump=0; MemRead=0; MemtoReg=0; MemWrite=0;
        ALUSrc1=0; RegWrite=0; PCSrc=0; Jalr=0; HaltSel=0;
        ALUOp=3'b000; ALUSrc2=2'b00;
        case(opcode)
            7'b0110011: begin RegWrite=1; ALUOp=3'b010; end
            7'b0010011: begin RegWrite=1; ALUOp=3'b011; ALUSrc2=2'b01; end
            7'b0000011: begin RegWrite=1; MemRead=1; MemtoReg=1; ALUSrc2=2'b01; end
            7'b0100011: begin MemWrite=1; ALUSrc2=2'b01; end
            7'b1100011: begin Branch=1; ALUOp=3'b001; end
            7'b1101111: begin Jump=1; RegWrite=1; ALUSrc1=1; ALUSrc2=2'b10; end
            7'b1100111: begin Jump=1; Jalr=1; PCSrc=1; RegWrite=1;
                                  ALUSrc1=1; ALUSrc2=2'b10; end
            7'b0110111: begin RegWrite=1; ALUSrc2=2'b01; ALUOp=3'b100; end
            7'b0010111: begin RegWrite=1; ALUSrc1=1; ALUSrc2=2'b01; end
            7'b1110011: begin HaltSel=bit20; end
            default: ; // FENCE, FENCE.TSO, PAUSE, ECALL and illegal opcodes = NOP
        endcase
    end
endmodule
