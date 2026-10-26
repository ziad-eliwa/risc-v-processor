`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/26/2026 02:10:42 PM
// Design Name: 
// Module Name: shifter
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


module tb_cpu();
    reg clk, rst;

    cpu uut (
        .clk(clk),
        .rst(rst)
    );

    always #10 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;

        #10;
        rst = 0;

        #20;
        $display("TEST PASSED");
        $finish;
    end

endmodule