`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/22/2026 07:42:12 AM
// Design Name: 
// Module Name: N_register
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


module nbit_register #(parameter N = 32) (
      input clk, load, rst, input [N-1:0] D, output [N-1:0] Q 
    );
    wire [N-1:0] Dmux;
    genvar i;
    generate
        for(i = 0; i<N; i=i+1) begin
            mux2x1 mux(Q[i], D[i], load, Dmux[i]);
            DFlipFlop dff(clk, rst, Dmux[i], Q[i]);
        end
    endgenerate
endmodule
