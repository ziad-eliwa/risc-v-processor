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
    input clk,
    input MemRead,
    input MemWrite,
    input [2:0] funct3,
    input [31:0] addr,
    input [31:0] data_in,
    output reg [31:0] data_out
);
    reg [31:0] mem [0:63];
    wire [5:0] word_addr = addr[7:2];
    wire [1:0] byte_offset = addr[1:0];
    reg [31:0] word_data;

    // Synchronous write
    always @(posedge clk) begin
        if (MemWrite && addr < 256) begin
            case (funct3)
                3'b000: begin // SB
                    case (byte_offset)
                        2'b00: mem[word_addr][7:0]   <= data_in[7:0];
                        2'b01: mem[word_addr][15:8]  <= data_in[7:0];
                        2'b10: mem[word_addr][23:16] <= data_in[7:0];
                        2'b11: mem[word_addr][31:24] <= data_in[7:0];
                    endcase
                end

                3'b001: begin // SH
                    if (byte_offset == 2'b00)
                        mem[word_addr][15:0] <= data_in[15:0];
                    else if (byte_offset == 2'b10)
                        mem[word_addr][31:16] <= data_in[15:0];
                end

                3'b010: begin // SW
                    if (byte_offset == 2'b00)
                        mem[word_addr] <= data_in;
                end

                default: ;
            endcase
        end
    end

    // Asynchronous read
    always @(*) begin
        data_out = 32'b0;
        word_data = 32'b0;

        if (MemRead && addr < 256) begin
            word_data = mem[word_addr];

            case (funct3)
                3'b000: begin // LB
                    case (byte_offset)
                        2'b00: data_out = {{24{word_data[7]}}, word_data[7:0]};
                        2'b01: data_out = {{24{word_data[15]}}, word_data[15:8]};
                        2'b10: data_out = {{24{word_data[23]}}, word_data[23:16]};
                        2'b11: data_out = {{24{word_data[31]}}, word_data[31:24]};
                    endcase
                end

                3'b001: begin // LH
                    if (byte_offset == 2'b00)
                        data_out = {{16{word_data[15]}}, word_data[15:0]};
                    else if (byte_offset == 2'b10)
                        data_out = {{16{word_data[31]}}, word_data[31:16]};
                end

                3'b010: begin // LW
                    if (byte_offset == 2'b00)
                        data_out = word_data;
                end

                3'b100: begin // LBU
                    case (byte_offset)
                        2'b00: data_out = {24'b0, word_data[7:0]};
                        2'b01: data_out = {24'b0, word_data[15:8]};
                        2'b10: data_out = {24'b0, word_data[23:16]};
                        2'b11: data_out = {24'b0, word_data[31:24]};
                    endcase
                end

                3'b101: begin // LHU
                    if (byte_offset == 2'b00)
                        data_out = {16'b0, word_data[15:0]};
                    else if (byte_offset == 2'b10)
                        data_out = {16'b0, word_data[31:16]};
                end

                default: data_out = 32'b0;
            endcase
        end
    end

    initial begin
        mem[0] = 32'd17;
        mem[1] = 32'd9;
        mem[2] = 32'd25;
    end

endmodule
