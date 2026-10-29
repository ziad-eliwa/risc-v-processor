`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/29/2026 07:43:04 AM
// Design Name: 
// Module Name: Decoder5by32
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


module decoder_5_by_32(
    input [4:0] in,
    input En,
    output reg [31:0] out
);

    always @(*) begin
        if (!En) begin
            out = 32'b0;        
        end else begin
            out = 32'b1 << in;       
        end
    end
endmodule
