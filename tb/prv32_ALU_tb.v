`timescale 1ns/1ps
module prv32_ALU_tb;
reg [31:0] a,b; reg [3:0] alucn; wire [31:0] r; wire cf,zf,vf,sf; integer errors;
prv32_ALU uut(.a(a),.b(b),.alucn(alucn),.r(r),.cf(cf),.zf(zf),.vf(vf),.sf(sf));
initial begin
    errors = 0;
    a=0;b=0;alucn=0;
    a=32'h00000007; b=32'h00000005; alucn=4'h0;
    #2;
    if (!(r === 32'h0000000C)) begin $display("FAIL: ADD"); errors = errors + 1; end
    else $display("PASS: ADD");
    a=32'h00000007; b=32'h00000005; alucn=4'h1;
    #2;
    if (!(r === 32'h00000002)) begin $display("FAIL: SUB"); errors = errors + 1; end
    else $display("PASS: SUB");
    a=32'h00000007; b=32'h12345000; alucn=4'h3;
    #2;
    if (!(r === 32'h12345000)) begin $display("FAIL: LUI pass B"); errors = errors + 1; end
    else $display("PASS: LUI pass B");
    a=32'h000000F0; b=32'h0000000F; alucn=4'h4;
    #2;
    if (!(r === 32'h000000FF)) begin $display("FAIL: OR"); errors = errors + 1; end
    else $display("PASS: OR");
    a=32'h000000F0; b=32'h0000000F; alucn=4'h5;
    #2;
    if (!(r === 32'h00000000)) begin $display("FAIL: AND"); errors = errors + 1; end
    else $display("PASS: AND");
    a=32'h000000F0; b=32'h0000000F; alucn=4'h7;
    #2;
    if (!(r === 32'h000000FF)) begin $display("FAIL: XOR"); errors = errors + 1; end
    else $display("PASS: XOR");
    a=32'h00000003; b=32'h00000002; alucn=4'h8;
    #2;
    if (!(r === 32'h0000000C)) begin $display("FAIL: SLL"); errors = errors + 1; end
    else $display("PASS: SLL");
    a=32'h80000000; b=32'h00000002; alucn=4'h9;
    #2;
    if (!(r === 32'h20000000)) begin $display("FAIL: SRL"); errors = errors + 1; end
    else $display("PASS: SRL");
    a=32'h80000000; b=32'h00000002; alucn=4'hA;
    #2;
    if (!(r === 32'hE0000000)) begin $display("FAIL: SRA"); errors = errors + 1; end
    else $display("PASS: SRA");
    a=32'hFFFFFFFF; b=32'h00000001; alucn=4'hD;
    #2;
    if (!(r === 32'h00000001)) begin $display("FAIL: SLT signed"); errors = errors + 1; end
    else $display("PASS: SLT signed");
    a=32'hFFFFFFFF; b=32'h00000001; alucn=4'hF;
    #2;
    if (!(r === 32'h00000000)) begin $display("FAIL: SLTU unsigned"); errors = errors + 1; end
    else $display("PASS: SLTU unsigned");
    a=32'h00000001; b=32'h00000002; alucn=4'hF;
    #2;
    if (!(r === 32'h00000001)) begin $display("FAIL: SLTU true"); errors = errors + 1; end
    else $display("PASS: SLTU true");
    if (errors == 0) $display("ALL prv32_ALU TESTS PASSED");
    else $display("prv32_ALU: %0d FAILED", errors);
    $finish;
end
endmodule
