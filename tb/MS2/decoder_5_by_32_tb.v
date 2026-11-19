`timescale 1ns/1ps
module decoder_5_by_32_tb;
reg [4:0] in; reg En; wire [31:0] out; integer errors;
decoder_5_by_32 uut(.in(in),.En(En),.out(out));
initial begin
    errors = 0;
    in=0; En=0;
    in=5'd10; En=0;
    #2;
    if (!(out === 32'h00000000)) begin $display("FAIL: disabled"); errors = errors + 1; end
    else $display("PASS: disabled");
    in=5'd0; En=1;
    #2;
    if (!(out === 32'h00000001)) begin $display("FAIL: x0"); errors = errors + 1; end
    else $display("PASS: x0");
    in=5'd1; En=1;
    #2;
    if (!(out === 32'h00000002)) begin $display("FAIL: x1"); errors = errors + 1; end
    else $display("PASS: x1");
    in=5'd15; En=1;
    #2;
    if (!(out === 32'h00008000)) begin $display("FAIL: x15"); errors = errors + 1; end
    else $display("PASS: x15");
    in=5'd31; En=1;
    #2;
    if (!(out === 32'h80000000)) begin $display("FAIL: x31"); errors = errors + 1; end
    else $display("PASS: x31");
    in=5'd31; En=0;
    #2;
    if (!(out === 32'h00000000)) begin $display("FAIL: disabled again"); errors = errors + 1; end
    else $display("PASS: disabled again");
    if (errors == 0) $display("ALL decoder_5_by_32 TEST PASSED");
    else $display("decoder_5_by_32: %0d FAIL", errors);
    $finish;
end
endmodule
