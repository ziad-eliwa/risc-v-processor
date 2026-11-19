`timescale 1ns/1ps
// One physical 32-bit-wide word array, byte-addressed, with byte/half/word
// access modes. External arbitration guarantees at most one address per cycle.
// Asynchronous read + posedge write (distributed RAM/LUT implementation).
module single_ported_mem #(
    parameter DATA_WIDTH=32,
    parameter ADDR_WIDTH=10,
    parameter INIT_FILE=""
)(
    input wire clk, MemRead, MemWrite,
    input wire [2:0] funct3,
    input wire [31:0] addr,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);
    localparam WORDS = (1 << ADDR_WIDTH);
    localparam BYTES = (WORDS * 4);
    reg [DATA_WIDTH-1:0] mem[0:WORDS-1];
    wire address_valid = (addr < BYTES);
    wire [ADDR_WIDTH-1:0] word_addr = addr[ADDR_WIDTH+1:2];
    wire [1:0] off = addr[1:0];
    integer i;
    initial begin
        for (i=0; i<WORDS; i=i+1) mem[i] = 0;
        if (INIT_FILE != "") $readmemh(INIT_FILE, mem);
    end
    always @(posedge clk) begin
        if (MemWrite && address_valid) begin
            case (funct3)
                3'b000: begin
                    case (off)
                        2'd0: mem[word_addr][7:0]   <= data_in[7:0];
                        2'd1: mem[word_addr][15:8]  <= data_in[7:0];
                        2'd2: mem[word_addr][23:16] <= data_in[7:0];
                        2'd3: mem[word_addr][31:24] <= data_in[7:0];
                    endcase
                end
                3'b001: begin
                    if (off==0) mem[word_addr][15:0] <= data_in[15:0];
                    if (off==2) mem[word_addr][31:16] <= data_in[15:0];
                end
                3'b010: if (off==0) mem[word_addr] <= data_in;
                default: ;
            endcase
        end
    end
    reg [31:0] word_data;
    always @* begin
        word_data = 32'b0;
        data_out = 32'b0;
        if (MemRead && address_valid) begin
            word_data = mem[word_addr];
            case (funct3)
                3'b000: case(off)
                    0: data_out={{24{word_data[7]}},word_data[7:0]};
                    1: data_out={{24{word_data[15]}},word_data[15:8]};
                    2: data_out={{24{word_data[23]}},word_data[23:16]};
                    3: data_out={{24{word_data[31]}},word_data[31:24]};
                endcase
                3'b001: case(off)
                    0: data_out={{16{word_data[15]}},word_data[15:0]};
                    2: data_out={{16{word_data[31]}},word_data[31:16]};
                    default: ;
                endcase
                3'b010: if (off==0) data_out=word_data;
                3'b100: data_out=(word_data >> (8*off)) & 32'h000000ff;
                3'b101: case(off)
                    0: data_out={16'b0,word_data[15:0]};
                    2: data_out={16'b0,word_data[31:16]};
                    default: ;
                endcase
                default: ;
            endcase
        end
    end
endmodule
