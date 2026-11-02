`timescale 1ns/1ps
module control_unit_tb;
reg [6:0] opcode; reg bit20; wire Branch, Jump, MemRead, MemtoReg, MemWrite,ALUSrc1, RegWrite,PCSrc,Jalr,HaltSel; wire [2:0] ALUOp; wire [1:0] ALUSrc2; integer errors;
control_unit uut(.opcode(opcode),.bit20(bit20),.Branch(Branch),.Jump(Jump),.MemRead(MemRead),.MemtoReg(MemtoReg),.MemWrite(MemWrite),.ALUSrc1(ALUSrc1),.RegWrite(RegWrite),.PCSrc(PCSrc),.Jalr(Jalr),.HaltSel(HaltSel),.ALUOp(ALUOp),.ALUSrc2(ALUSrc2));
initial begin
    errors = 0;
    opcode=0;bit20=0;
    opcode=7'h33; bit20=0;
    #2;
    if (!(RegWrite && ALUOp==3'b010 && ALUSrc2==0 && !MemWrite)) begin $display("FAIL: R-type"); errors = errors + 1; end
    else $display("PASS: R-type");
    opcode=7'h13; bit20=0;
    #2;
    if (!(RegWrite && ALUOp==3'b011 && ALUSrc2==1)) begin $display("FAIL: I-type"); errors = errors + 1; end
    else $display("PASS: I-type");
    opcode=7'h03; bit20=0;
    #2;
    if (!(MemRead && MemtoReg && RegWrite && !MemWrite)) begin $display("FAIL: Load"); errors = errors + 1; end
    else $display("PASS: Load");
    opcode=7'h23; bit20=0;
    #2;
    if (!(MemWrite && !RegWrite && !MemRead)) begin $display("FAIL: Store"); errors = errors + 1; end
    else $display("PASS: Store");
    opcode=7'h63; bit20=0;
    #2;
    if (!(Branch && ALUOp==3'b001 && !RegWrite)) begin $display("FAIL: Branch"); errors = errors + 1; end
    else $display("PASS: Branch");
    opcode=7'h6F; bit20=0;
    #2;
    if (!(Jump && RegWrite && ALUSrc1 && ALUSrc2==2 && !PCSrc)) begin $display("FAIL: JAL"); errors = errors + 1; end
    else $display("PASS: JAL");
    opcode=7'h67; bit20=0;
    #2;
    if (!(Jump && Jalr && PCSrc && RegWrite)) begin $display("FAIL: JALR"); errors = errors + 1; end
    else $display("PASS: JALR");
    opcode=7'h37; bit20=0;
    #2;
    if (!(RegWrite && ALUOp==3'b100)) begin $display("FAIL: LUI"); errors = errors + 1; end
    else $display("PASS: LUI");
    opcode=7'h17; bit20=0;
    #2;
    if (!(RegWrite && ALUSrc1 && ALUSrc2==1)) begin $display("FAIL: AUIPC"); errors = errors + 1; end
    else $display("PASS: AUIPC");
    opcode=7'h73; bit20=0;
    #2;
    if (!(!HaltSel && !RegWrite)) begin $display("FAIL: ECALL"); errors = errors + 1; end
    else $display("PASS: ECALL");
    opcode=7'h73; bit20=1;
    #2;
    if (!(HaltSel && !RegWrite)) begin $display("FAIL: EBREAK"); errors = errors + 1; end
    else $display("PASS: EBREAK");
    opcode=7'h7F; bit20=0;
    #2;
    if (!(!RegWrite && !MemRead && !MemWrite && !Branch && !Jump)) begin $display("FAIL: unknown opcode"); errors = errors + 1; end
    else $display("PASS: unknown opcode");
    if (errors == 0) $display("ALL control_unit TESTS PASSED");
    else $display("control_unit: %0d FAILED", errors);
    $finish;
end
endmodule
