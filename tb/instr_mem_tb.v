`timescale 1ns/1ps
module instr_mem_tb;
reg [31:0] addr;wire [31:0] data_out;integer errors;
instr_mem uut(.addr(addr),.data_out(data_out));
initial begin
 errors=0;
 addr=0;#2;if(data_out !== 32'b0000000_00000_00000_000_00000_0110011) begin $display("FAIL address 0");errors=errors+1;end
 addr=4;#2;if(data_out !== 32'b000000000000_00000_010_00001_0000011) begin $display("FAIL address 4");errors=errors+1;end
 addr=8;#2;if(data_out !== 32'b000000000100_00000_010_00010_0000011) begin $display("FAIL address 8");errors=errors+1;end
 uut.mem[20]=32'hDEADBEEF;
 addr=80;#2;if(data_out !== 32'hDEADBEEF) begin $display("FAIL custom instruction");errors=errors+1;end
 addr=83;#2;if(data_out !== 32'hDEADBEEF) begin $display("FAIL word addressing");errors=errors+1;end
 if(errors==0) $display("ALL instr_mem TESTS PASSED");else $display("instr_mem FAILED: %0d",errors);
 $finish;
end
endmodule
