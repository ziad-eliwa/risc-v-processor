`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2026 06:49:15 PM
// Design Name: 
// Module Name: dff_p
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


module dff_p #(
    parameter RESET_VALUE = 1'b0
)(input clk, input rst, input D, output reg Q);
     always @ (posedge clk or posedge rst) begin // Asynchronous Reset
         if (rst)
         Q <= RESET_VALUE;
         else
         Q <= D;
     end
endmodule     
