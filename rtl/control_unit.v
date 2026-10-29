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

module control_unit (
    input [6:0] opcode,
    output reg Branch,MemRead,MemtoReg,MemWrite,ALUSrc,RegWrite,
    output reg [1:0] ALUOp
);
    always@(*) begin
        if(opcode[6:2] == 5'b01100) begin
            {Branch,MemRead,MemtoReg,ALUOp,MemWrite,ALUSrc,RegWrite} = 8'b00010001;
        end else if(opcode[6:2] == 5'b00000) begin
            {Branch,MemRead,MemtoReg,ALUOp,MemWrite,ALUSrc,RegWrite} = 8'b01100011;
        end else if(opcode[6:2] == 5'b01000) begin
            {Branch,MemRead,MemtoReg,ALUOp,MemWrite,ALUSrc,RegWrite} = 8'b00000110;
        end else if(opcode[6:2] == 5'b11000) begin
            {Branch,MemRead,MemtoReg,ALUOp,MemWrite,ALUSrc,RegWrite} = 8'b10001000;
        end else 
            {Branch,MemRead,MemtoReg,ALUOp,MemWrite,ALUSrc,RegWrite} = 8'b00000000;
    end
endmodule
