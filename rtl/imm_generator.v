`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/26/2026 02:10:42 PM
// Design Name: 
// Module Name: shifter
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


`include "defines.v"

module imm_generator (
    input  wire [31:0]  instr,
    output reg  [31:0]  imm
);
    always @(*) begin
        case (`OPCODE)
            `OPCODE_Arith_I   : 	imm = { {21{instr[31]}}, instr[30:25], instr[24:21], instr[20] };
            `OPCODE_Store     :     imm = { {21{instr[31]}}, instr[30:25], instr[11:8], instr[7] };
            `OPCODE_LUI       :     imm = { instr[31], instr[30:20], instr[19:12], 12'b0 };
            `OPCODE_AUIPC     :     imm = { instr[31], instr[30:20], instr[19:12], 12'b0 };
            `OPCODE_JAL       : 	imm = { {12{instr[31]}}, instr[19:12], instr[20], instr[30:25], instr[24:21], 1'b0 };
            `OPCODE_JALR      : 	imm = { {21{instr[31]}}, instr[30:25], instr[24:21], instr[20] };
            `OPCODE_Branch    : 	imm = { {20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            default           : 	imm = { {21{instr[31]}}, instr[30:25], instr[24:21], instr[20] }; // IMM_I
        endcase 
    end
endmodule
