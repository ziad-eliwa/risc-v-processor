`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2026 06:49:15 PM
// Design Name: 
// Module Name: memory
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


module single_ported_mem #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 6  // 64 words
)(
    input                 clk,
    input                  en,      // Write Enable (1 = Write, 0 = Read)
    input   [ADDR_W-1:0] addr,
    input   [DATA_W-1:0] din,
    output reg  [DATA_W-1:0] dout
);
    reg [DATA_W-1:0] mem [0:(2**ADDR_W)-1];

    always @(posedge clk) begin
        if (we[0]) mem[addr][ 7: 0] <= din[ 7: 0];
        if (we[1]) mem[addr][15: 8] <= din[15: 8];
        if (we[2]) mem[addr][23:16] <= din[23:16];
        if (we[3]) mem[addr][31:24] <= din[31:24];
            
        dout <= mem[addr];  // read-first mode (reads before writes take effect)
    end
  
//    initial begin
//        $readmemh("program.hex", mem);
//    end
endmodule
