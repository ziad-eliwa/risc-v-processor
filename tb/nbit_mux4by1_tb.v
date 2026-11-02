`timescale 1ns/1ps
module nbit_mux4by1_tb;
reg [31:0] A,B,C,D; reg [1:0] sel; wire [31:0] Out; integer errors;
nbit_mux4by1 uut(.A(A),.B(B),.C(C),.D(D),.sel(sel),.Out(Out));
initial begin
    errors = 0;
    A=32'd11; B=32'd22; C=32'd33; D=32'd44; sel=0;
    sel=2'd0;
    #2;
    if (!(Out === 32'd11)) begin $display("FAIL: select A"); errors = errors + 1; end
    else $display("PASS: select A");
    sel=2'd1;
    #2;
    if (!(Out === 32'd22)) begin $display("FAIL: select B"); errors = errors + 1; end
    else $display("PASS: select B");
    sel=2'd2;
    #2;
    if (!(Out === 32'd33)) begin $display("FAIL: select C"); errors = errors + 1; end
    else $display("PASS: select C");
    sel=2'd3;
    #2;
    if (!(Out === 32'd44)) begin $display("FAIL: select D"); errors = errors + 1; end
    else $display("PASS: select D");
    if (errors == 0) $display("ALL nbit_mux4by1 TESTS PASSED");
    else $display("nbit_mux4by1: %0d FAILED", errors);
    $finish;
end
endmodule
