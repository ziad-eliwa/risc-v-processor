`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/22/2026 07:38:22 AM
// Design Name: 
// Module Name: DFlipFlop
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


module dff(input clk, input rst, input D, output reg Q);
     always @ (posedge clk or posedge rst) begin // Asynchronous Reset
         if (rst)
         Q <= 1'b0;
         else
         Q <= D;
     end
endmodule
