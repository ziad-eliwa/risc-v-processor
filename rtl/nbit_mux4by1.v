`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/01/2026 03:34:19 PM
// Design Name: 
// Module Name: nbit_mux4by1
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


module nbit_mux4by1 #(parameter N = 32)(
    input [N-1:0] A, B, C, D,
    input [1:0] sel,
    output [N-1:0] Out
);
    wire [N-1:0] w1, w2;
    nbit_mux2by1 #(N) mux1(A, B, sel[0], w1);
    nbit_mux2by1 #(N) mux2(C, D, sel[0], w2);
    nbit_mux2by1 #(N) mux3(w1, w2, sel[1], Out);
endmodule
