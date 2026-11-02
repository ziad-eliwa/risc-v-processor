`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/29/2026 03:01:17 PM
// Design Name: 
// Module Name: control_unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//control_unit CU(.opcode(instruction[6:0]),.Branch(Branch),.Jump(Jump),
//        .MemRead(MemRead),.MemtoReg(MemtoReg),.MemWrite(MemWrite),
//        .ALUSrc1(ALUSrc1),.ALUSrc2(ALUSrc2),.RegWrite(RegWrite),.ALUOp(ALUOp),.PCSrc(PCSrc),.LUI(LUI))



module control_unit (
    input [6:0] opcode, input bit20,
    output reg Branch, Jump, MemRead, MemtoReg, MemWrite,
               ALUSrc1, RegWrite, PCSrc, Jalr, HaltSel,
    output reg [2:0] ALUOp,
    output reg [1:0] ALUSrc2
);

    always @(*) begin
        Branch   = 1'b0;
        Jump     = 1'b0;
        MemRead  = 1'b0;
        MemtoReg = 1'b0;
        MemWrite = 1'b0;
        ALUSrc1  = 1'b0;
        ALUSrc2  = 2'b00;
        RegWrite = 1'b0;
        PCSrc    = 1'b0;
        ALUOp    = 3'b000;
        Jalr     = 1'b0;
        HaltSel  = 1'b0;

        if (opcode[1:0] == 2'b11) begin
            if (opcode[6:2] == 5'b01100) begin
                // R-Type
                ALUSrc1  = 1'b0;
                ALUSrc2  = 2'b00;
                RegWrite = 1'b1;
                ALUOp    = 3'b010;

            end else if (opcode[6:2] == 5'b00100) begin
                // I-Type arithmetic
                ALUSrc1  = 1'b0;
                ALUSrc2  = 2'b01;
                RegWrite = 1'b1;
                ALUOp    = 3'b011;

            end else if (opcode[6:2] == 5'b00000) begin
                // Load
                MemRead  = 1'b1;
                MemtoReg = 1'b1;
                ALUSrc1  = 1'b0;
                ALUSrc2  = 2'b01;
                RegWrite = 1'b1;
                ALUOp    = 3'b000;

            end else if (opcode[6:2] == 5'b01000) begin
                // Store
                MemWrite = 1'b1;
                ALUSrc1  = 1'b0;
                ALUSrc2  = 2'b01;
                ALUOp    = 3'b000;

            end else if (opcode[6:2] == 5'b11000) begin
                // Branch
                Branch   = 1'b1;
                ALUSrc1  = 1'b0;
                ALUSrc2  = 2'b00;
                ALUOp    = 3'b001;

            end else if (opcode[6:2] == 5'b11011) begin
                // JAL
                Jump     = 1'b1;
                PCSrc    = 1'b0;
                ALUSrc1  = 1'b1;
                ALUSrc2  = 2'b10;
                RegWrite = 1'b1;
                ALUOp    = 3'b000;

            end else if (opcode[6:2] == 5'b11001) begin
                // JALR
                Jump     = 1'b1;
                PCSrc    = 1'b1;
                ALUSrc1  = 1'b1;
                ALUSrc2  = 2'b10;
                RegWrite = 1'b1;
                ALUOp    = 3'b000;
                Jalr     = 1'b1;

            end else if (opcode[6:2] == 5'b01101) begin
                // LUI
                ALUSrc1  = 1'b0;
                ALUSrc2  = 2'b01;
                RegWrite = 1'b1;
                ALUOp    = 3'b100;

            end else if (opcode[6:2] == 5'b00101) begin
                // AUIPC
                ALUSrc2  = 2'b01;
                ALUSrc1  = 1'b1;
                RegWrite = 1'b1;
                ALUOp    = 3'b000;

            end else if (opcode[6:2] == 5'b11100) begin
                // EBREAk
                HaltSel = bit20;
            end
        end
    end
endmodule
