`timescale 1ns/1ps
module nbit_mux2by1_tb;
reg [31:0] A,B; reg sel; wire [31:0] Out; integer errors;
nbit_mux2by1 uut(.A(A),.B(B),.sel(sel),.Out(Out));
initial begin
    errors = 0;
    A=32'h12345678; B=32'hABCDEF01; sel=0;
    sel=0;
    #2;
    if (!(Out === 32'h12345678)) begin $display("FAIL: select A"); errors = errors + 1; end
    else $display("PASS: select A");
    sel=1;
    #2;
    if (!(Out === 32'hABCDEF01)) begin $display("FAIL: select B"); errors = errors + 1; end
    else $display("PASS: select B");
    B=32'hFFFFFFFF;
    #2;
    if (!(Out === 32'hFFFFFFFF)) begin $display("FAIL: new input"); errors = errors + 1; end
    else $display("PASS: new input");
    if (errors == 0) $display("ALL nbit_mux2by1 TEST PASSED");
    else $display("nbit_mux2by1: %0d FAIL", errors);
    $finish;
end
endmodule
