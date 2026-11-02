`timescale 1ns/1ps
module shifter_tb;
reg [31:0] a; reg [4:0] shamt; reg [1:0] stype; wire [31:0] r; integer errors;
shifter uut(.a(a),.shamt(shamt),.stype(stype),.r(r));
initial begin
    errors = 0;
    a=32'h80000010; shamt=4; stype=0;
    stype=0;
    #2;
    if (!(r === 32'h00000100)) begin $display("FAIL: SLL"); errors = errors + 1; end
    else $display("PASS: SLL");
    stype=1;
    #2;
    if (!(r === 32'h08000001)) begin $display("FAIL: SRL"); errors = errors + 1; end
    else $display("PASS: SRL");
    stype=2;
    #2;
    if (!(r === 32'hF8000001)) begin $display("FAIL: SRA"); errors = errors + 1; end
    else $display("PASS: SRA");
    shamt=0; stype=0;
    #2;
    if (!(r === 32'h80000010)) begin $display("FAIL: zero shift"); errors = errors + 1; end
    else $display("PASS: zero shift");
    stype=3; shamt=5;
    #2;
    if (!(r === 32'h80000010)) begin $display("FAIL: reserved passes through"); errors = errors + 1; end
    else $display("PASS: reserved passes through");
    if (errors == 0) $display("ALL shifter TESTS PASSED");
    else $display("shifter: %0d FAILED", errors);
    $finish;
end
endmodule
