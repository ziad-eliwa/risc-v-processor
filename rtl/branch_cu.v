`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/26/2026 02:10:42 PM
// Design Name: 
// Module Name: branch CU
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


module branch_cu(
    input branch,
    input [2:0] funct3,
    input jump, cf, sf, zf, vf,
    output PCJumpSel
); 
    reg Ctrl;
    always @(*) begin
        case (funct3)
                3'b000: Ctrl = zf;   // BEQ      
                3'b001: Ctrl = ~zf;  // BNE         
                3'b100: Ctrl = sf != vf;  // BLT  
                3'b101: Ctrl = sf == vf; // BGE
                3'b110: Ctrl = ~cf; // BLTU
                3'b111: Ctrl = cf; // BGEU
                default: Ctrl = 0;
        endcase
    end
    assign PCJumpSel = (Ctrl & branch) | jump;
endmodule
