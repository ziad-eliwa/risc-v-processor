`timescale 1ns/1ps
module register_file_tb;
reg clk,rst,regwrite;reg [4:0] readreg1,readreg2,writereg;reg [31:0] writedata;wire [31:0] readdata1,readdata2;integer errors;
register_file uut(.clk(clk),.rst(rst),.readreg1(readreg1),.readreg2(readreg2),.writereg(writereg),.writedata(writedata),.regwrite(regwrite),.readdata1(readdata1),.readdata2(readdata2));
always #5 clk=~clk;
initial begin
 errors=0;clk=0;rst=1;regwrite=0;readreg1=0;readreg2=1;writereg=0;writedata=0;
 #2;rst=0;
 regwrite=1;writereg=5'd1;writedata=32'h12345678;
 @(posedge clk);#1; if(readdata2 !== 32'h12345678) begin $display("FAIL write x1");errors=errors+1;end
 writereg=5'd2;writedata=32'hAABBCCDD;readreg1=5'd2;
 @(posedge clk);#1; if(readdata1 !== 32'hAABBCCDD) begin $display("FAIL write x2");errors=errors+1;end
 writereg=0;writedata=32'hFFFFFFFF;readreg1=0;
 @(posedge clk);#1; if(readdata1 !== 0) begin $display("FAIL x0 should be zero");errors=errors+1;end
 regwrite=0;writereg=1;writedata=0;readreg1=1;
 @(posedge clk);#1; if(readdata1 !== 32'h12345678) begin $display("FAIL no write");errors=errors+1;end
 rst=1;#1; if(readdata1 !== 0 || readdata2 !== 0) begin $display("FAIL reset");errors=errors+1;end
 if(errors==0) $display("ALL register_file TEST PASSED");else $display("register_file FAIL: %0d",errors);
 $finish;
end
endmodule
