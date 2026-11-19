`timescale 1ns/1ps


module branch_predictor #(
    parameter INDEX_BITS = 5
) (
    input wire clk, rst,
    input wire [31:0] PC,
    output wire predT,
    output wire [31:0] predTgt,
    input wire update_en, updateT, update_jump,
    input wire [31:0] updatePC, updateTgt
);
    localparam ENTRIES = (1 << INDEX_BITS);
    reg valid [0:ENTRIES-1];
    reg [29:0] tag [0:ENTRIES-1];
    reg [31:0] target [0:ENTRIES-1];
    reg [1:0] counter [0:ENTRIES-1];
    wire [INDEX_BITS-1:0] rindex = PC[INDEX_BITS+1:2];
    wire [INDEX_BITS-1:0] windex = updatePC[INDEX_BITS+1:2];
    wire hit = valid[rindex] && (tag[rindex] == PC[31:2]);
    assign predT = hit && counter[rindex][1];
    assign predTgt = hit ? target[rindex] : 32'b0;

    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < ENTRIES; i = i + 1) begin
                valid[i]   <= 1'b0;
                tag[i]     <= 30'b0;
                target[i]  <= 32'b0;
                counter[i] <= 2'b01;
            end
        end else if (update_en) begin
            valid[windex]  <= 1'b1;
            tag[windex]    <= updatePC[31:2];
            target[windex] <= updateTgt;
            if (update_jump)
                counter[windex] <= 2'b11;  // unconditional control transfer
            else if (!valid[windex] || tag[windex] != updatePC[31:2])
                counter[windex] <= updateT ? 2'b10 : 2'b01;
            else if (updateT && counter[windex] != 2'b11)
                counter[windex] <= counter[windex] + 2'b01;
            else if (!updateT && counter[windex] != 2'b00)
                counter[windex] <= counter[windex] - 2'b01;
        end
    end
endmodule
