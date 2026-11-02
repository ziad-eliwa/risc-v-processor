`timescale 1ns/1ps
module nbit_register_tb;
reg clk,rst,load;reg [31:0] D;wire [31:0] Q;integer errors;
nbit_register uut(.clk(clk),.rst(rst),.load(load),.D(D),.Q(Q));
always #5 clk=~clk;
initial begin
 errors=0;clk=0;rst=1;load=0;D=0;
 #2; if(Q !== 0) begin $display("FAIL reset");errors=errors+1;end
 rst=0;load=1;D=32'h12345678;
 @(posedge clk);#1; if(Q !== 32'h12345678) begin $display("FAIL load");errors=errors+1;end
 load=0;D=32'hAABBCCDD;
 @(posedge clk);#1; if(Q !== 32'h12345678) begin $display("FAIL hold");errors=errors+1;end
 load=1;
 @(posedge clk);#1; if(Q !== 32'hAABBCCDD) begin $display("FAIL second load");errors=errors+1;end
 rst=1;#1; if(Q !== 0) begin $display("FAIL asynchronous reset");errors=errors+1;end
 if(errors==0) $display("ALL nbit_register TEST PASSED");else $display("nbit_register FAIL: %0d",errors);
 $finish;
end
endmodule
