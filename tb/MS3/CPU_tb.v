`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/06/2026 09:44:26 AM
// Design Name: 
// Module Name: CPU_tb
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


module RVPipeline_tb();
    reg clk, rst;
    wire halted;
    cpu_p uut(clk,rst, halted);
    initial begin
        clk = 0;
        forever #10 clk=~clk;
    end
    initial begin
        rst = 1;
        #50;    
        rst = 0;
    end
endmodule
