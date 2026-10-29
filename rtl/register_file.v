`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/29/2026 02:44:52 PM
// Design Name: 
// Module Name: register_file
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


module register_file #(parameter N = 32)( 
    input clk, rst, 
    input [4:0] readreg1, readreg2, writereg, 
    input [N-1:0] writedata, 
    input regwrite,
    output [N-1:0] readdata1, readdata2
);
    wire [31:0] loads;
    Decoder5by32 dec(.in(writereg),.En(regwrite),.out(loads));
    
    wire [N-1:0] Q [31:0];    

    genvar i;
    generate 
        for(i=0; i<32; i=i+1) begin
            N_register #(N) register(.clk(clk),.load(loads[i]),
            .rst(rst),.D(writedata),.Q(Q[i]));
        end
    endgenerate
    
    assign readdata1 = Q[readreg1];
    assign readdata2 = Q[readreg2];    
endmodule 