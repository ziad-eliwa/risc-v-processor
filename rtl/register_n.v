`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2026 06:49:15 PM
// Design Name: 
// Module Name: register_n
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


module register_n #(parameter N = 32) (
      input clk, load, rst, input [N-1:0] D, output [N-1:0] Q 
);
    wire [N-1:0] Dmux;
    genvar i;
    generate
        for(i = 0; i<N; i=i+1) begin
            mux2x1 mux(Q[i], D[i], load, Dmux[i]);
            dff_n dff(clk, rst, Dmux[i], Q[i]);
        end
    endgenerate
endmodule
