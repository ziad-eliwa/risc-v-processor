`timescale 1ns/1ps
module data_mem_tb;
reg clk,MemRead,MemWrite;reg [2:0] funct3;reg [31:0] addr,data_in;wire [31:0] data_out;integer errors;
data_mem uut(.clk(clk),.MemRead(MemRead),.MemWrite(MemWrite),.funct3(funct3),.addr(addr),.data_in(data_in),.data_out(data_out));
always #5 clk=~clk;
initial begin
 errors=0;clk=0;MemRead=0;MemWrite=0;funct3=0;addr=32'd16;data_in=0;
 MemWrite=1;funct3=3'b010;data_in=32'h80A2B3C4;
 @(posedge clk);#1;MemWrite=0;MemRead=1;
 #2;if(data_out !== 32'h80A2B3C4) begin $display("FAIL SW/LW");errors=errors+1;end
 funct3=3'b000;addr=16;
 #2;if(data_out !== 32'hFFFFFFC4) begin $display("FAIL LB sign extend");errors=errors+1;end
 funct3=3'b100;
 #2;if(data_out !== 32'h000000C4) begin $display("FAIL LBU");errors=errors+1;end
 addr=18;funct3=3'b001;
 #2;if(data_out !== 32'hFFFF80A2) begin $display("FAIL LH");errors=errors+1;end
 funct3=3'b101;
 #2;if(data_out !== 32'h000080A2) begin $display("FAIL LHU");errors=errors+1;end
 MemRead=0;MemWrite=1;funct3=3'b000;addr=17;data_in=32'h00000055;
 @(posedge clk);#1;MemWrite=0;MemRead=1;funct3=3'b010;addr=16;
 #2;if(data_out !== 32'h80A255C4) begin $display("FAIL SB byte lane");errors=errors+1;end
 MemRead=0;MemWrite=1;funct3=3'b001;addr=18;data_in=32'h00001234;
 @(posedge clk);#1;MemWrite=0;MemRead=1;funct3=3'b010;addr=16;
 #2;if(data_out !== 32'h123455C4) begin $display("FAIL SH upper half");errors=errors+1;end
 MemRead=0;#2;if(data_out !== 0) begin $display("FAIL read disabled");errors=errors+1;end
 if(errors==0) $display("ALL data_mem TEST PASSED");else $display("data_mem FAIL: %0d",errors);
 $finish;
end
endmodule
