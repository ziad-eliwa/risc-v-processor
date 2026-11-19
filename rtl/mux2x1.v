`timescale 1ns/1ps
module mux2x1(input wire A, B, sel, output wire Out);
    assign Out = sel ? B : A;
endmodule
