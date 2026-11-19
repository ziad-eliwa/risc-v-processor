`timescale 1ns/1ps
module prv32_ALU(
    input wire [31:0] a, b,
    output reg [31:0] r,
    output wire cf, zf, vf, sf,
    input wire [3:0] alucn
);
    // Flags always describe a-b, so branch comparisons remain valid.
    wire [32:0] difference = {1'b0,a} + {1'b0,~b} + 33'd1;
    assign cf = difference[32];
    assign zf = difference[31:0] == 32'b0;
    assign sf = difference[31];
    assign vf = (a[31] != b[31]) && (difference[31] != a[31]);
    wire [31:0] shifted;
    shifter shift_unit(.a(a), .shamt(b[4:0]), .stype(alucn[1:0]), .r(shifted));
    always @* begin
        case (alucn)
            4'b0000: r = a + b;
            4'b0001: r = a - b;
            4'b0011: r = b;
            4'b0100: r = a | b;
            4'b0101: r = a & b;
            4'b0111: r = a ^ b;
            4'b1000, 4'b1001, 4'b1010: r = shifted;
            4'b1101: r = {31'b0, ($signed(a) < $signed(b))};
            4'b1111: r = {31'b0, (a < b)};
            default: r = 32'b0;
        endcase
    end
endmodule
