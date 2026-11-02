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
    wire Branch, MemRead, MemtoReg, MemWrite, ALUSrc1, RegWrite, Jump, PCSrc, PCJumpSel, Jalr, HaltSel;
    wire [1:0] ALUSrc2;
    wire [2:0] ALUOp;
    wire [3:0] ALUCtrl;
    wire [31:0] PCOut, PCplus4, PCJump, PCIn, readData1,readData2, WriteData, Immediate, ALUIn2, ALUResult, dataMemOut;
    wire cf, zf, vf, sf;     
    wire [31:0] ALUOper1, ALUOper2;
    wire [31:0] jalrOffset, branchOffset;            

    nbit_register #(32) PC(.clk(clk),.load(1),.rst(rst),.D(PCIn),.Q(PCOut));
    
    instr_mem iMem(.addr(PCOut),.data_out(instruction));
   
    register_file RF(.clk(clk),.rst(rst),.readreg1(instruction[19:15]),
        .readreg2(instruction[24:20]),.writereg(instruction[11:7])
        ,.writedata(WriteData),
        .regwrite(RegWrite),.readdata1(readData1),.readdata2(readData2));
        
    imm_generator immGen(.instr(instruction),.imm(Immediate));
    
    control_unit CU(.opcode(instruction[6:0]),.bit20(instruction[20]),.Branch(Branch),.Jump(Jump),
        .MemRead(MemRead),.MemtoReg(MemtoReg),.MemWrite(MemWrite),
        .ALUSrc1(ALUSrc1),.ALUSrc2(ALUSrc2),.RegWrite(RegWrite),
        .ALUOp(ALUOp),.PCSrc(PCSrc),.Jalr(Jalr),.HaltSel(HaltSel));

    alu_control_unit aluCU(.ALUOp(ALUOp),.funct3(instruction[14:12]),
        .funct7b5(instruction[30]),.alucn(ALUCtrl));

    nbit_mux2by1 muxReg1toALU(.A(readData1),.B(PCOut), 
        .sel(ALUSrc1),.Out(ALUOper1));
        
    nbit_mux4by1 muxReg2toALU(.A(readData2),.B(Immediate),.C(32'b0100),.D(32'b0),
        .sel(ALUSrc2),.Out(ALUOper2));
        
    prv32_ALU alu(.a(ALUOper1),.b(ALUOper2),.r(ALUResult),.cf(cf),.zf(zf),.vf(vf),.sf(sf),.alucn(ALUCtrl));
        
    data_mem dMem(.clk(clk),.addr(ALUResult),.funct3(instruction[14:12]),.MemRead(MemRead), 
         .MemWrite(MemWrite),.data_in(readData2),.data_out(dataMemOut)); 
            
    nbit_mux2by1 muxMemToReg(.A(ALUResult),.B(dataMemOut),
        .sel(MemtoReg),.Out(WriteData));
        	
    branch_cu branchCU(.branch(Branch),.jump(Jump),.zf(zf),.cf(cf),.vf(vf),.sf(sf),.funct3(instruction[14:12]),.PCJumpSel(PCJumpSel));

    nbit_mux2by1 mux1(.A('d4),.B(Immediate),
        .sel(PCJumpSel),.Out(branchOffset));
        
    nbit_mux2by1 mux2(.A(PCOut),.B(readData1),.sel(PCSrc),.Out(jalrOffset));
    wire [31:0] target_sum = jalrOffset + branchOffset;
    wire [31:0] AddRes = {target_sum[31:1], target_sum[0] & ~Jalr};  
    nbit_mux2by1 halt(.A(AddRes),.B(PCOut),.sel(HaltSel),.Out(PCIn));
endmodule
