`timescale 1ns/1ps
module mux2x1_tb;
reg A,B,sel; wire out; integer errors;
mux2x1 uut(.A(A),.B(B),.sel(sel),.out(out));
initial begin
    errors = 0;
    A=0; B=0; sel=0;
    A=0; B=1; sel=0;
    #2;
    if (!(out === 1'b0)) begin $display("FAIL: select A zero"); errors = errors + 1; end
    else $display("PASS: select A zero");
    A=1; B=0; sel=0;
    #2;
    if (!(out === 1'b1)) begin $display("FAIL: select A one"); errors = errors + 1; end
    else $display("PASS: select A one");
    A=1; B=0; sel=1;
    #2;
    if (!(out === 1'b0)) begin $display("FAIL: select B zero"); errors = errors + 1; end
    else $display("PASS: select B zero");
    A=0; B=1; sel=1;
    #2;
    if (!(out === 1'b1)) begin $display("FAIL: select B one"); errors = errors + 1; end
    else $display("PASS: select B one");
    if (errors == 0) $display("ALL mux2x1 TESTS PASSED");
    else $display("mux2x1: %0d FAILED", errors);
    $finish;
end
endmodule
