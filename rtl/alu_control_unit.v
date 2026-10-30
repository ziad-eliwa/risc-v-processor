`timescale 1ns / 1ps
/*******************************************************************
*
* Module: prv32_ALU.v
* Project: risc-v-processor
* Author: Ziad Eliwa ziadeliwa@aucegypt.end
          Mostafa Abdelwahed mostafabahaa@aucegypt.edu
* Description: put your description here
*
* Change history: 29/10/26 – Added module from past labs - Ziad Eliwa
* 30/10/26 – Added aluops and alucn signals for all instructions - Mostafa Abdelwahed
*
**********************************************************************/


module alu_control_unit(
    input  wire [2:0] ALUOp,
    input  wire [2:0] funct3,
    input  wire       funct7b5,    // instruction bit 30
    output reg  [3:0] alucn
);
    always @* begin
        case (ALUOp)
            3'b000: alucn = 4'b0000;           // add
            3'b001: alucn = 4'b0001;           // sub (branches)
            3'b100: alucn = 4'b0011;           // lui: pass B
            3'b010, 3'b011: begin              // R-type / I-type
                case (funct3)
                    3'b000: alucn = (ALUOp == 3'b010 && funct7b5) ? 4'b0001 : 4'b0000;
                    3'b001: alucn = 4'b1000;
                    3'b010: alucn = 4'b1101;
                    3'b011: alucn = 4'b1111;
                    3'b100: alucn = 4'b0111;
                    3'b101: alucn = funct7b5 ? 4'b1010 : 4'b1001;
                    3'b110: alucn = 4'b0100;
                    3'b111: alucn = 4'b0101;
                endcase
            end
            default: alucn = 4'b0000;
        endcase
    end
endmodule