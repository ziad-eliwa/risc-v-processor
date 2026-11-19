`timescale 1ns/1ps
module mispredict_detector(
    input wire branch, jump, taken, PredT,
    input wire [31:0] target, PredTgt, PC,
    output wire mispredict,
    output wire update_en, updateT,
    output wire [31:0] updateTgt, updatePC
);
    wire valid_cti = branch || jump;
    assign mispredict = valid_cti && ((taken != PredT) ||
                         (taken && PredT && target != PredTgt));
    assign update_en  = valid_cti;
    assign updateT    = taken;
    assign updateTgt  = target;
    assign updatePC   = PC;
endmodule
