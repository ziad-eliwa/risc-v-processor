`timescale 1ns/1ps
module branch_cu(
    input wire branch,
    input wire [2:0] funct3,
    input wire jump, cf, sf, zf, vf,
    output wire PCJumpSel
);
    reg condition;
    always @* begin
        case (funct3)
            3'b000: condition = zf;
            3'b001: condition = !zf;
            3'b100: condition = sf != vf;
            3'b101: condition = sf == vf;
            3'b110: condition = !cf;
            3'b111: condition = cf;
            default: condition = 1'b0;
        endcase
    end
    assign PCJumpSel = (branch && condition) || jump;
endmodule
