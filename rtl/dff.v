`timescale 1ns/1ps
// Compatibility primitive used by the supplied nbit_register module.
module dff(input wire clk, rst, D, output reg Q);
    always @(posedge clk or posedge rst)
        if (rst) Q <= 1'b0;
        else Q <= D;
endmodule
