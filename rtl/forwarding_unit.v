`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2026 06:49:15 PM
// Design Name: 
// Module Name: forwarding_unit
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


module forwarding_unit(
    output reg [1:0] forwardA, forwardB,
    input [4:0] ID_EX_RegisterRs1, ID_EX_RegisterRs2, EX_MEM_RegisterRd, MEM_WB_RegisterRd,
    input EX_MEM_RegWrite, MEM_WB_RegWrite
);
    always @(*) begin 
        forwardA = 00;
        forwardB = 00;
        if (EX_MEM_RegWrite && (EX_MEM_RegisterRd != 5'b0) && (EX_MEM_RegisterRd == ID_EX_RegisterRs1))
            forwardA = 10; 
        if (EX_MEM_RegWrite && (EX_MEM_RegisterRd != 5'b0) && (EX_MEM_RegisterRd == ID_EX_RegisterRs2))
            forwardB = 10;   
        if ((MEM_WB_RegWrite && (MEM_WB_RegisterRd != 5'b0) && (MEM_WB_RegisterRd == ID_EX_RegisterRs1)) && (~(EX_MEM_RegWrite && (EX_MEM_RegisterRd != 5'b0) && (EX_MEM_RegisterRd == ID_EX_RegisterRs1))))
            forwardA = 01;
        if ((MEM_WB_RegWrite && (MEM_WB_RegisterRd != 5'b0) && (MEM_WB_RegisterRd == ID_EX_RegisterRs2)) && (~(EX_MEM_RegWrite && (EX_MEM_RegisterRd != 5'b0) && (EX_MEM_RegisterRd == ID_EX_RegisterRs2))))
            forwardB = 01;     
    end
endmodule
