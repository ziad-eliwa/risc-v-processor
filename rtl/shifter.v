`timescale 1ns/1ps
module shifter(input wire [31:0] a, input wire [4:0] shamt,
               input wire [1:0] stype, output reg [31:0] r);
    always @* begin
        case (stype)
            2'b00: r = a << shamt;                 // SLL
            2'b01: r = a >> shamt;                 // SRL
            2'b10: r = $signed(a) >>> shamt;       // SRA
            default: r = 32'b0;
        endcase
    end
endmodule
