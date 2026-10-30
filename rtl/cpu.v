`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/26/2026 02:10:42 PM
// Design Name: 
// Module Name: shifter
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

module cpu(
    input clk, rst
);
    wire [31:0] instruction;
    wire Branch, MemRead, MemtoReg, MemWrite, ALUSrc1, ALUSrc2, RegWrite, Jump, PCSrc, LUI;
    wire [2:0] ALUOp;
    wire [3:0] ALUCtrl;
    wire  ALUZero, PCJumpSel;
    wire [31:0] PCOut, PCplus4, PCJump, PCIn, readData1,readData2, WriteData, Immediate, ShiftOut, ALUIn2, ALUResult, dataMemOut;

    nbit_register #(32) PC(.clk(clk),.load(1),.rst(rst),.D(PCIn),.Q(PCOut));
    
    instr_mem iMem(.addr(PCOut[7:2]),.data_out(instruction)); // TODO: Check memory size
   
    register_file RF(.clk(clk),.rst(rst),.readreg1(instruction[19:15]),
        .readreg2(instruction[24:20]),.writereg(instruction[11:7])
        ,.writedata(WriteDataLUI),
        .regwrite(RegWrite),.readdata1(readData1),.readdata2(readData2));
        
    imm_generator immGen(.inst(instruction),.gen_out(Immediate)); // TODO
    
    control_unit CU(.opcode(instruction[6:0]),.Branch(Branch),.Jump(Jump),
        .MemRead(MemRead),.MemtoReg(MemtoReg),.MemWrite(MemWrite),
        .ALUSrc1(ALUSrc1),.ALUSrc2(ALUSrc2),.RegWrite(RegWrite),.ALUOp(ALUOp),.PCSrc(PCSrc),.LUI(LUI)); // TODO

    alu_control_unit aluCU(.ALUOp(ALUOp),.instr1(instruction[14:12]),
        .instr2(instruction[30]),.ALUCtrl(ALUCtrl)); // TODO
    
    wire [31:0] ALUOper1, ALUOper2;
    
    nbit_mux2by1 muxReg1toALU(.A(readData1),.B(PCOut), 
        .sel(ALUSrc1),.Out(ALUOper1));
        
    nbit_mux2by1 muxReg2toALU(.A(readData2),.B(Immediate),
        .sel(ALUSrc2),.Out(ALUOper2));
        
    prv32_ALU alu(.in1(ALUOper1),.in2(ALUOper2),.result(ALUresult), 
        .zero(ALUzero),.ALUCtrl(ALUCtrl)); // TODO
        
    data_mem dMem(.clk(clk),.addr(ALUresult[7:2]),.funct3(),.MemRead(MemRead), 
         .MemWrite(MemWrite),.data_in(readData2),.data_out(dataMemOut)); // TODO
    
    wire [31:0] WriteDataLUI;
    
    nbit_mux2by1 muxLUI(.A(WriteData),.B(Immediate),
        .sel(LUI),.Out(WriteDataLUI));    
        
    nbit_mux2by1 muxMemToReg(.A(ALUresult),.B(dataMemOut),
        .sel(MemtoReg),.Out(WriteData));
        
    assign PCJumpSel = (zero & Branch) | Jump;     
                     
    wire [31:0] jalrOffset, branchOffset;            
    nbit_mux2by1 mux1(.A('d4),.B(Immediate),
        .sel(PCJumpSel),.Out(branchOffset));
        
    nbit_mux2by1 mux2(.A(PCOut),.B(readData1),
        .sel(PCSrc),.Out(jalrOffset));
        
    assign PCIn = jalrOffset + branchOffset;    
endmodule