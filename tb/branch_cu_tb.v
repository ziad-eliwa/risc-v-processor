`timescale 1ns/1ps
module branch_cu_tb;
reg branch,jump,cf,sf,zf,vf; reg [2:0] funct3; wire PCJumpSel; integer errors;
branch_cu uut(.branch(branch),.funct3(funct3),.jump(jump),.cf(cf),.sf(sf),.zf(zf),.vf(vf),.PCJumpSel(PCJumpSel));
initial begin
    errors = 0;
    branch=1; jump=0; cf=0; sf=0; zf=0; vf=0;
    funct3=3'b000; zf=1; sf=0; vf=0; cf=0; branch=1; jump=0;
    #2;
    if (!(PCJumpSel === 1'b1)) begin $display("FAIL: BEQ taken"); errors = errors + 1; end
    else $display("PASS: BEQ taken");
    funct3=3'b000; zf=0; sf=0; vf=0; cf=0; branch=1; jump=0;
    #2;
    if (!(PCJumpSel === 1'b0)) begin $display("FAIL: BEQ not taken"); errors = errors + 1; end
    else $display("PASS: BEQ not taken");
    funct3=3'b001; zf=0; sf=0; vf=0; cf=0; branch=1; jump=0;
    #2;
    if (!(PCJumpSel === 1'b1)) begin $display("FAIL: BNE taken"); errors = errors + 1; end
    else $display("PASS: BNE taken");
    funct3=3'b001; zf=1; sf=0; vf=0; cf=0; branch=1; jump=0;
    #2;
    if (!(PCJumpSel === 1'b0)) begin $display("FAIL: BNE not taken"); errors = errors + 1; end
    else $display("PASS: BNE not taken");
    funct3=3'b100; zf=0; sf=1; vf=0; cf=0; branch=1; jump=0;
    #2;
    if (!(PCJumpSel === 1'b1)) begin $display("FAIL: BLT signed"); errors = errors + 1; end
    else $display("PASS: BLT signed");
    funct3=3'b101; zf=0; sf=1; vf=1; cf=0; branch=1; jump=0;
    #2;
    if (!(PCJumpSel === 1'b1)) begin $display("FAIL: BGE signed"); errors = errors + 1; end
    else $display("PASS: BGE signed");
    funct3=3'b110; zf=0; sf=0; vf=0; cf=0; branch=1; jump=0;
    #2;
    if (!(PCJumpSel === 1'b1)) begin $display("FAIL: BLTU unsigned"); errors = errors + 1; end
    else $display("PASS: BLTU unsigned");
    funct3=3'b111; zf=0; sf=0; vf=0; cf=1; branch=1; jump=0;
    #2;
    if (!(PCJumpSel === 1'b1)) begin $display("FAIL: BGEU unsigned"); errors = errors + 1; end
    else $display("PASS: BGEU unsigned");
    funct3=3'b000; zf=1; sf=0; vf=0; cf=0; branch=0; jump=0;
    #2;
    if (!(PCJumpSel === 1'b0)) begin $display("FAIL: branch disabled"); errors = errors + 1; end
    else $display("PASS: branch disabled");
    funct3=3'b000; zf=0; sf=0; vf=0; cf=0; branch=0; jump=1;
    #2;
    if (!(PCJumpSel === 1'b1)) begin $display("FAIL: jump unconditional"); errors = errors + 1; end
    else $display("PASS: jump unconditional");
    if (errors == 0) $display("ALL branch_cu TESTS PASSED");
    else $display("branch_cu: %0d FAILED", errors);
    $finish;
end
endmodule
