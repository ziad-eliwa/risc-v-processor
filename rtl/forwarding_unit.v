`timescale 1ns/1ps
// 00=register-file value, 10=EX/MEM ALU result, 01=MEM/WB result.
// EX/MEM forwarding is inhibited for loads (load result not yet available).
module forwarding_unit(
    output reg [1:0] forwardA, forwardB,
    input wire [4:0] ID_EX_RegisterRs1, ID_EX_RegisterRs2,
    input wire [4:0] EX_MEM_RegisterRd, MEM_WB_RegisterRd,
    input wire EX_MEM_RegWrite, MEM_WB_RegWrite,
    input wire EX_MEM_MemRead
);
    always @* begin
        forwardA = 2'b00;
        forwardB = 2'b00;
        if (EX_MEM_RegWrite && !EX_MEM_MemRead && EX_MEM_RegisterRd != 0 &&
            EX_MEM_RegisterRd == ID_EX_RegisterRs1)
            forwardA = 2'b10;
        else if (MEM_WB_RegWrite && MEM_WB_RegisterRd != 0 &&
                 MEM_WB_RegisterRd == ID_EX_RegisterRs1)
            forwardA = 2'b01;

        if (EX_MEM_RegWrite && !EX_MEM_MemRead && EX_MEM_RegisterRd != 0 &&
            EX_MEM_RegisterRd == ID_EX_RegisterRs2)
            forwardB = 2'b10;
        else if (MEM_WB_RegWrite && MEM_WB_RegisterRd != 0 &&
                 MEM_WB_RegisterRd == ID_EX_RegisterRs2)
            forwardB = 2'b01;
    end
endmodule
