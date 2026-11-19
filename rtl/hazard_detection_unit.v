`timescale 1ns/1ps
// With MEM-priority arbitration, a MEM load/store consumes the shared port.
// IF gets a bubble; ID may still advance. A true load-use RAW dependency
// instead retains IF/ID and PC and inserts a bubble into ID/EX.
module hazard_detection_unit(
    input wire ID_EX_MemRead,
    input wire [4:0] ID_EX_RegisterRd,
    input wire [4:0] IF_ID_RegisterRs1, IF_ID_RegisterRs2,
    input wire IF_ID_UsesRs1, IF_ID_UsesRs2,
    input wire EX_MEM_MemRead, EX_MEM_MemWrite,
    input wire mispredict, ebreak, halt_pending,
    output reg PCWrite, IFIDWrite, IFIDFlush, IDEXFlush,
    output wire load_stall, mem_stall
);
    assign load_stall = ID_EX_MemRead && ID_EX_RegisterRd != 5'd0 &&
       ((IF_ID_UsesRs1 && IF_ID_RegisterRs1 == ID_EX_RegisterRd) ||
        (IF_ID_UsesRs2 && IF_ID_RegisterRs2 == ID_EX_RegisterRd));
    assign mem_stall = EX_MEM_MemRead || EX_MEM_MemWrite;

    always @* begin
        PCWrite = 1'b1;
        IFIDWrite = 1'b1;
        IFIDFlush = 1'b0;
        IDEXFlush = 1'b0;
        if (mispredict) begin
            // Retire EX control-transfer and squash younger instructions.
            IFIDFlush = 1'b1;
            IDEXFlush = 1'b1;
        end else if (ebreak || halt_pending) begin
            PCWrite = 1'b0;
            IFIDFlush = 1'b1;
            IDEXFlush = 1'b1;
        end else if (load_stall) begin
            PCWrite = 1'b0;
            IFIDWrite = 1'b0;
            IDEXFlush = 1'b1;
        end else if (mem_stall) begin
            PCWrite = 1'b0;
            IFIDFlush = 1'b1;
        end
    end
endmodule
