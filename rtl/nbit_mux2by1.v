`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/29/2026 03:01:17 PM
// Design Name: 
// Module Name: nbit_mux2by1
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


module nbit_mux2by1 #(parameter N = 32)(
        input [N-1:0] A,B, input sel,
        output [N-1:0] Out
    );
    
    genvar i;
    generate
        for(i = 0; i < N; i = i + 1) begin 
            mux2x1 mux(A[i],B[i],sel,Out[i]);        
        end
    endgenerate
endmodule
