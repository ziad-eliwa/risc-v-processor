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


module shifter (
    input  wire [31:0] a,
    input  wire [4:0]  shamt,
    input  wire [1:0]  type,  
    output reg  [31:0] r
);
    always @* begin
        case (type)
            2'b00:   r = a << shamt;            // SLL
            2'b01:   r = a >> shamt;            // SRL
            2'b10:   r = $signed(a) >>> shamt;  // SRA
            default: r = a;
        endcase
    end
endmodule
