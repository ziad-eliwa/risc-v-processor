`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2026 06:49:15 PM
// Design Name: 
// Module Name: dff_n
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


module dff_n(input clk, input rst, input D, output reg Q);
     always @ (negedge clk or posedge rst) begin // Asynchronous Reset
         if (rst)
         Q <= 1'b0;
         else
         Q <= D;
     end
endmodule
