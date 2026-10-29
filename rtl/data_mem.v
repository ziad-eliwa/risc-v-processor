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

module data_mem (
    input clk, input MemRead, input MemWrite,
    input [31:0] addr, input [31:0] data_in, output [31:0] data_out
);
    reg [31:0] mem [0:63];
    always @(posedge clk) begin
        if(MemWrite) begin
            mem[addr] = data_in;
        end    
    end 
    assign data_out = MemRead == 'b1 ? mem[addr] : 32'b0;
    
    initial begin
        mem[0]=32'd17;
        mem[1]=32'd9;
        mem[2]=32'd25;
    end 
endmodule
