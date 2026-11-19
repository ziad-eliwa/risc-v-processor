`timescale 1ns/1ps
module pc_selector(
    input wire mispredict, predT,
    output wire [1:0] PCSel
);
    // 00: PC+4; 01: BTB target; 10: EX correction (priority)
    assign PCSel[1] = mispredict;
    assign PCSel[0] = predT && !mispredict;
endmodule
