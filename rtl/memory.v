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
    parameter ADDR_WIDTH = 10  // 1024 words
)(
    input  wire                  clk,
    input  wire                  we,      // Write Enable (1 = Write, 0 = Read)
    input  wire [ADDR_WIDTH-1:0] addr,    // Shared Instruction/Data Address
    input  wire [DATA_WIDTH-1:0] din,     // Data to write (from Register B)
    output reg  [DATA_WIDTH-1:0] dout     // Read data (to IR or MDR)
);

    reg [DATA_WIDTH-1:0] mem [0:(2**ADDR_WIDTH)-1];

    // Optional: Preload machine code for simulation/FPGA initialization
    initial begin
        $readmemh("program.hex", mem);
    end

    always @(posedge clk) begin
        if (we) begin
            mem[addr] <= din;
        end
        // Registered read ensures BRAM inference (1-cycle latency)
        dout <= mem[addr];
    end

endmodule