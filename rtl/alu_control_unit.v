`timescale 1ns/1ps
module alu_control_unit(
    input wire [2:0] ALUOp, funct3,
    input wire funct7b5,
    output reg [3:0] alucn
);
    always @* begin
        alucn = 4'b0000;
        case (ALUOp)
            3'b000: alucn = 4'b0000;  // ADD: address / AUIPC / link
            3'b001: alucn = 4'b0001;  // SUB for branches
            3'b100: alucn = 4'b0011;  // LUI: B
            3'b010, 3'b011: begin
                case (funct3)
                    3'b000: alucn = ALUOp == 3'b010 && funct7b5 ? 4'b0001 : 4'b0000;
                    3'b001: alucn = 4'b1000;
                    3'b010: alucn = 4'b1101;
                    3'b011: alucn = 4'b1111;
                    3'b100: alucn = 4'b0111;
                    3'b101: alucn = funct7b5 ? 4'b1010 : 4'b1001;
                    3'b110: alucn = 4'b0100;
                    3'b111: alucn = 4'b0101;
                    default: alucn = 4'b0000;
                endcase
            end
            default: alucn = 4'b0000;
        endcase
    end
endmodule
