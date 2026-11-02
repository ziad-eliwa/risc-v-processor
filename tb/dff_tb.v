`timescale 1ns/1ps
module dff_tb;
reg clk,rst,D; wire Q; integer errors;
dff uut(.clk(clk),.rst(rst),.D(D),.Q(Q));
always #5 clk=~clk;
initial begin
 errors=0;clk=0;rst=1;D=0;
 #2; if(Q !== 0) begin $display("FAIL reset");errors=errors+1;end
 rst=0;D=1;
 @(posedge clk); #1; if(Q !== 1) begin $display("FAIL store 1");errors=errors+1;end
 D=0;
 @(posedge clk); #1; if(Q !== 0) begin $display("FAIL store 0");errors=errors+1;end
 D=1; #1; if(Q !== 0) begin $display("FAIL hold before clock");errors=errors+1;end
 rst=1; #1; if(Q !== 0) begin $display("FAIL async reset");errors=errors+1;end
 if(errors==0) $display("ALL dff TESTS PASSED");else $display("dff FAILED: %0d",errors);
 $finish;
end
endmodule
