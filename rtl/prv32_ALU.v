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


module prv32_ALU(
	input   wire [31:0] a, b,
	output  reg  [31:0] r,
	output  wire        cf, zf, vf, sf,
	input   wire [3:0]  alucn
);

    wire [31:0] add, op_b;
    
    assign op_b = (~b);
    
    assign {cf, add} = alucn[0] ? (a + op_b + 1'b1) : (a + b);
    
    assign zf = (add == 0);
    assign sf = add[31];
    assign vf = (a[31] ^ (op_b[31]) ^ add[31] ^ cf);
    
    wire[31:0] sh;
    shifter shifter0(.a(a), .shamt(b[4:0]), .stype(alucn[1:0]),  .r(sh));
    
    always @ * begin
        r = 0;
        (* parallel_case *)
        case (alucn)
            // arithmetic
            4'b00_00 : r = add; //add, addi, lw, lh, lhu, lb, lbu, sw. sh, sb, jal, jalr, auipc
            4'b00_01 : r = add; //sub, beq, bne, blt, bge, bltu, bgeu
            4'b00_11 : r = b;   //lui
            // logic
            4'b01_00:  r = a | b; //or, ori
            4'b01_01:  r = a & b; //and, andi
            4'b01_11:  r = a ^ b; //xor, xori
            // shift
            4'b10_00:  r=sh; //sll, slli
            4'b10_01:  r=sh; //srl, srli
            4'b10_10:  r=sh; //sra, srai
            // slt & sltu
            4'b11_01:  r = {31'b0,(sf != vf)}; //slt, slti
            4'b11_11:  r = {31'b0,(~cf)}; //sltu, sltiu
        endcase
    end
endmodule
