`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2026 06:44:42 PM
// Design Name: 
// Module Name: cpu_p
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cpu_p(
    input clk, rst
); 
     // wires declarations
     wire [31:0] Inst;
     wire [3:0] ALUsel;
     wire  Zero, PCSrc;
     wire [31:0] PCOut, PCplus4, BranchAddOut, PCIn, RegR1, RegR2, WriteData, Imm, shiftOut, ALUIn1, ALUIn2, ALU_out, Mem_out;
     wire RegWrite, MemtoReg, Branch, MemRead, MemWrite, ALUSrc;
     wire [1:0] ALUOp;
     wire [7:0] Ctrl = {ALUSrc, ALUOp, MemWrite, MemRead, Branch,MemtoReg, RegWrite};
     
     // IF_ID 
     wire [31:0] IF_ID_PCOut, IF_ID_Inst;
     register_p #(64) IF_ID (.clk(clk),.rst(rst),.load(1'b1),.D({PCOut,Inst}),.Q({IF_ID_PCOut,IF_ID_Inst})); 
      
     wire [4:0] Rs1 = IF_ID_Inst[19:15], Rs2 = IF_ID_Inst[24:20], Rd = IF_ID_Inst[11:7];
     wire [3:0] Func = {IF_ID_Inst[14:12],IF_ID_Inst[30]};
     wire [6:0] Opcode = IF_ID_Inst[6:0];

     // ID_EX     
     wire [31:0] ID_EX_PCOut, ID_EX_RegR1, ID_EX_RegR2, ID_EX_Imm; 
     wire [7:0] ID_EX_Ctrl; 
     wire [3:0] ID_EX_Func; 
     wire [4:0] ID_EX_Rs1, ID_EX_Rs2, ID_EX_Rd;  
     
     register_p #(155) ID_EX (clk,rst,1'b1,{Ctrl,IF_ID_PCOut,RegR1,RegR2,Imm,Func,Rs1,Rs2,Rd}, 
        {ID_EX_Ctrl,ID_EX_PCOut,ID_EX_RegR1,ID_EX_RegR2, ID_EX_Imm, ID_EX_Func,ID_EX_Rs1,ID_EX_Rs2,ID_EX_Rd}); 
     
     // EX_MEM
     wire [31:0] EX_MEM_BranchAddOut, EX_MEM_ALU_out, EX_MEM_RegR2; 
     wire [4:0] EX_MEM_Ctrl, EX_MEM_Rd; 
     wire EX_MEM_Zero;  
     
     register_p #(107) EX_MEM (clk,rst,1'b1,{ID_EX_Ctrl[4:0],BranchAddOut,Zero,ALU_out,ID_EX_RegR2,ID_EX_Rd}, 
                                  {EX_MEM_Ctrl,EX_MEM_BranchAddOut,EX_MEM_Zero,EX_MEM_ALU_out,EX_MEM_RegR2,EX_MEM_Rd}); 
       
     wire [31:0] MEM_WB_Mem_out, MEM_WB_ALU_out; 
     wire [1:0] MEM_WB_Ctrl; 
     wire [4:0] MEM_WB_Rd;   
     register_p #(71) MEM_WB (clk,rst,1'b1,{EX_MEM_Ctrl[1:0],Mem_out,EX_MEM_ALU_out,EX_MEM_Rd}, 
                                  {MEM_WB_Ctrl,MEM_WB_Mem_out, MEM_WB_ALU_out, MEM_WB_Rd}); 
            
     // all modules instantiations 
    register_p #(32) PC(.clk(clk),.load(1),.rst(rst),.D(PCIn),.Q(PCOut));
    
    register_file registers(.clk(clk),.rst(rst),.readreg1(Rs1),
        .readreg2(Rs2),.writereg(MEM_WB_Rd),.writedata(WriteData),
        .regwrite(MEM_WB_Ctrl[0]),.readdata1(RegR1),.readdata2(RegR2));
        
    imm_generator immgen(.inst(IF_ID_Inst),.gen_out(Imm));
    
    single_ported_mem #(32,6) memory(.clk(clk),.en(),.addr(),.din(),.dout());
    
    control_unit cu(.opcode(Opcode),.Branch(Branch),
        .MemRead(MemRead),.MemtoReg(MemtoReg),.MemWrite(MemWrite),
        .ALUSrc(ALUSrc),.RegWrite(RegWrite),.ALUOp(ALUOp));
    
    alu_control_unit alucu(.ALUOp(ID_EX_Ctrl[6:5]),.instr1(ID_EX_Func[3:1]),
        .instr2(ID_EX_Func[0]),.ALUsel(ALUsel));
    
    wire [1:0] ForwardA, ForwardB;
    forwarding_unit fu(.forwardA(ForwardA),.forwardB(ForwardB),.ID_EX_RegisterRs1(ID_EX_Rs1),.ID_EX_RegisterRs2(ID_EX_Rs2),
        .EX_MEM_RegisterRd(EX_MEM_Rd),.MEM_WB_RegisterRd(MEM_WB_Rd),.EX_MEM_RegWrite(EX_MEM_Ctrl[0]),.MEM_WB_RegWrite(MEM_WB_Ctrl[0]));
     
    wire [31:0] ALUImmMux;
    nbit_mux2by1 muxRegtoALU(.A(ID_EX_RegR2),.B(ID_EX_Imm),.sel(ID_EX_Ctrl[7]),.Out(ALUImmMux));
            
    nbit_mux4by1 mux1toALU(.A(ID_EX_RegR1),.B(WriteData),.C(EX_MEM_ALU_out),.D(0),.sel(ForwardA),.Out(ALUIn1));    
    nbit_mux4by1 mux2toALU(.A(ALUImmMux),.B(EX_MEM_ALU_out),.C(WriteData),.D(0),.sel(ForwardB),.Out(ALUIn2));    
        
    prv32_ALU alu(.in1(ALUIn1),.in2(ALUIn2),.result(ALU_out),
        .zero(Zero),.aluSel(ALUsel));
                
    nbit_mux2by1 muxDataMemtoWriteReg(.A(MEM_WB_ALU_out),.B(MEM_WB_Mem_out),.sel(MEM_WB_Ctrl[1]),.Out(WriteData));
        
    assign PCplus4 = PCOut + 32'd4;
    assign BranchAddOut = ID_EX_PCOut + shiftOut;
    assign PCSrc = EX_MEM_Zero & EX_MEM_Ctrl[2];
    
    nbit_mux2by1 muxPCJump(.A(PCplus4),.B(EX_MEM_BranchAddOut),.sel(PCSrc),.Out(PCIn));
endmodule