`timescale 1ns/1ps


module cpu_p #(
    parameter MEM_ADDR_WIDTH = 10,               // 1024 x 32-bit words
    parameter [31:0] RESET_PC = 32'h00000000,
    parameter MEM_INIT_FILE = "btb_alias.mem",
    parameter BTB_INDEX_BITS = 5
)(
    input wire clk, rst,
    output wire halted
);
    localparam [31:0] NOP    = 32'h00000013;      // addi x0,x0,0
    localparam [31:0] EBREAK = 32'h00100073;
    localparam IFID_WIDTH = 98;
    localparam IDEX_WIDTH = 227;
    localparam EXMEM_WIDTH = 77;
    localparam MEMWB_WIDTH = 72;

    // =====================================================================
    // IF: program counter, predictor and explicit 4-way next-PC mux
    // =====================================================================
    wire [31:0] PCOut, PCIn;
    wire [31:0] PCplus4 = PCOut + 32'd4;
    wire predT;
    wire [31:0] predTgt;
    wire [1:0] PCSel;
    wire mispredict;
    wire [31:0] redirectPC;
    wire bp_update_en, bp_update_taken;
    wire [31:0] bp_update_target, bp_update_pc;
    wire PCWrite, IFIDWrite, IFIDFlush, IDEXFlush;
    // Declared before their use in the predictor and arbitration network.
    wire ID_EX_valid, ID_EX_Jump;
    wire halt_pending;

    // Added optional RESET_VALUE to register_p/dff_p so RESET_PC=4 also works.
    register_p #(.N(32), .RESET_VALUE(RESET_PC)) PC_register (
        .clk(clk), .rst(rst), .load(PCWrite), .D(PCIn), .Q(PCOut)
    );
    branch_predictor #(.INDEX_BITS(BTB_INDEX_BITS)) branchp (
        .clk(clk), .rst(rst), .PC(PCOut), .predT(predT), .predTgt(predTgt),
        .update_en(bp_update_en), .updateT(bp_update_taken),
        .update_jump(ID_EX_valid && ID_EX_Jump),
        .updatePC(bp_update_pc), .updateTgt(bp_update_target)
    );
    pc_selector pcsel(.mispredict(mispredict), .predT(predT), .PCSel(PCSel));
    // 00 PC+4, 01 BTB target, 10 EX redirect, 11 safe fallback.
    nbit_mux4by1 #(.N(32)) muxPC (
        .A(PCplus4), .B(predTgt), .C(redirectPC), .D(PCplus4),
        .sel(PCSel), .Out(PCIn)
    );

    // =====================================================================
    // IF/ID: 98-bit positive-edge register with flush and hold (stall)
    // =====================================================================
    wire IF_ID_valid, IF_ID_PredT;
    wire [31:0] IF_ID_PCOut, IF_ID_Inst, IF_ID_PredTgt;
    wire [31:0] Mem_out;
    wire [IFID_WIDTH-1:0] IF_ID_D, IF_ID_Q;
    wire [IFID_WIDTH-1:0] IF_ID_fetch =
        {1'b1, PCOut, Mem_out, predT, predTgt};
    wire [IFID_WIDTH-1:0] IF_ID_bubble =
        {1'b0, 32'b0, NOP, 1'b0, 32'b0};
    // Flush must win even if the IF/ID write-enable is low.
    nbit_mux2by1 #(.N(IFID_WIDTH)) muxIFIDFlush (
        .A(IF_ID_fetch), .B(IF_ID_bubble), .sel(IFIDFlush), .Out(IF_ID_D)
    );
    register_p #(.N(IFID_WIDTH)) IF_ID (
        .clk(clk), .rst(rst), .load(IFIDWrite | IFIDFlush),
        .D(IF_ID_D), .Q(IF_ID_Q)
    );
    assign {IF_ID_valid, IF_ID_PCOut, IF_ID_Inst,
            IF_ID_PredT, IF_ID_PredTgt} = IF_ID_Q;

    wire [4:0] Rs1 = IF_ID_Inst[19:15];
    wire [4:0] Rs2 = IF_ID_Inst[24:20];
    wire [4:0] Rd = IF_ID_Inst[11:7];
    wire [6:0] Opcode = IF_ID_Inst[6:0];
    wire [3:0] Func = {IF_ID_Inst[14:12], IF_ID_Inst[30]};
    wire UsesRs1 = IF_ID_valid && (Opcode == 7'b0110011 ||
        Opcode == 7'b0010011 || Opcode == 7'b0000011 ||
        Opcode == 7'b0100011 || Opcode == 7'b1100011 ||
        Opcode == 7'b1100111);
    wire UsesRs2 = IF_ID_valid && (Opcode == 7'b0110011 ||
        Opcode == 7'b0100011 || Opcode == 7'b1100011);

    // =====================================================================
    // ID: falling-edge architectural register file, control and immediate
    // =====================================================================
    wire [31:0] RegR1, RegR2, Imm, WriteData;
    wire Branch, Jump, MemRead, MemtoReg, MemWrite;
    wire ALUSrc1, RegWrite, PCSrc, Jalr, HaltSel;
    wire [1:0] ALUSrc2;
    wire [2:0] ALUOp;
    wire [4:0] MEM_WB_Rd;
    wire MEM_WB_RegWrite, MEM_WB_valid;
    wire regfile_we = MEM_WB_valid && MEM_WB_RegWrite && (MEM_WB_Rd != 0);

    register_file registers (
        .clk(clk), .rst(rst), .readreg1(Rs1), .readreg2(Rs2),
        .writereg(MEM_WB_Rd), .writedata(WriteData),
        .regwrite(regfile_we), .readdata1(RegR1), .readdata2(RegR2)
    );
    imm_generator immgen(.instr(IF_ID_Inst), .imm(Imm));
    control_unit cu (
        .opcode(Opcode), .bit20(IF_ID_Inst[20]), .Branch(Branch),
        .Jump(Jump), .MemRead(MemRead), .MemtoReg(MemtoReg),
        .MemWrite(MemWrite), .ALUSrc1(ALUSrc1), .ALUSrc2(ALUSrc2),
        .RegWrite(RegWrite), .PCSrc(PCSrc), .Jalr(Jalr),
        .HaltSel(HaltSel), .ALUOp(ALUOp)
    );

    // =====================================================================
    // ID/EX: 227-bit positive-edge pipeline register (bubble on hazard)
    // =====================================================================
    wire [31:0] ID_EX_PCOut, ID_EX_Inst, ID_EX_RegR1, ID_EX_RegR2;
    wire [31:0] ID_EX_Imm, ID_EX_PredTgt;
    wire [4:0] ID_EX_Rs1, ID_EX_Rs2, ID_EX_Rd;
    wire [3:0] ID_EX_Func;
    wire [2:0] ID_EX_ALUOp;
    wire [1:0] ID_EX_ALUSrc2;
    wire ID_EX_ALUSrc1, ID_EX_RegWrite, ID_EX_MemtoReg;
    wire ID_EX_MemRead, ID_EX_MemWrite, ID_EX_Branch;
    wire ID_EX_Jalr, ID_EX_Halt, ID_EX_PredT;
    wire [IDEX_WIDTH-1:0] ID_EX_D, ID_EX_Q;
    wire [IDEX_WIDTH-1:0] ID_EX_decode = {
        IF_ID_valid, IF_ID_PCOut, IF_ID_Inst, RegR1, RegR2, Imm,
        Rs1, Rs2, Rd, Func, ALUOp, ALUSrc2,
        ALUSrc1, RegWrite, MemtoReg, MemRead, MemWrite, Branch, Jump,
        Jalr, (IF_ID_Inst == EBREAK), IF_ID_PredT, IF_ID_PredTgt
    };
    // IDEXFlush OR invalid IF/ID means one bubble advances to EX.
    wire ID_EX_insert_bubble = IDEXFlush || !IF_ID_valid;
    nbit_mux2by1 #(.N(IDEX_WIDTH)) muxIDEXBubble (
        .A(ID_EX_decode), .B({IDEX_WIDTH{1'b0}}),
        .sel(ID_EX_insert_bubble), .Out(ID_EX_D)
    );
    register_p #(.N(IDEX_WIDTH)) ID_EX (
        .clk(clk), .rst(rst), .load(1'b1), .D(ID_EX_D), .Q(ID_EX_Q)
    );
    assign {ID_EX_valid, ID_EX_PCOut, ID_EX_Inst, ID_EX_RegR1,
            ID_EX_RegR2, ID_EX_Imm, ID_EX_Rs1, ID_EX_Rs2, ID_EX_Rd,
            ID_EX_Func, ID_EX_ALUOp, ID_EX_ALUSrc2, ID_EX_ALUSrc1,
            ID_EX_RegWrite, ID_EX_MemtoReg, ID_EX_MemRead,
            ID_EX_MemWrite, ID_EX_Branch, ID_EX_Jump, ID_EX_Jalr,
            ID_EX_Halt, ID_EX_PredT, ID_EX_PredTgt} = ID_EX_Q;

    // =====================================================================
    // EX: explicit mux4 forwarding, mux2/mux4 ALU operands, branch checks
    // =====================================================================
    wire [1:0] ForwardA, ForwardB;
    wire [31:0] ForwardedRs1, ForwardedRs2;
    wire [31:0] ALUIn1, ALUIn2, ALU_out;
    wire [3:0] ALUsel;
    wire cf, zf, vf, sf;
    wire PCJumpSel;
    wire [31:0] BranchTarget = ID_EX_PCOut + ID_EX_Imm;
    wire [31:0] JALRTarget = (ForwardedRs1 + ID_EX_Imm) & 32'hfffffffe;
    wire [31:0] ActualTarget;
    wire taken = ID_EX_valid && PCJumpSel;
    wire ex_ebreak = ID_EX_valid && ID_EX_Halt;
    wire [31:0] SeqAfterBranch = ID_EX_PCOut + 32'd4;

    wire EX_MEM_valid, EX_MEM_RegWrite, EX_MEM_MemRead;
    wire [4:0] EX_MEM_Rd;
    wire [31:0] EX_MEM_ALU_out;
    forwarding_unit fu (
        .forwardA(ForwardA), .forwardB(ForwardB),
        .ID_EX_RegisterRs1(ID_EX_Rs1), .ID_EX_RegisterRs2(ID_EX_Rs2),
        .EX_MEM_RegisterRd(EX_MEM_Rd), .MEM_WB_RegisterRd(MEM_WB_Rd),
        .EX_MEM_RegWrite(EX_MEM_valid && EX_MEM_RegWrite),
        .MEM_WB_RegWrite(MEM_WB_valid && MEM_WB_RegWrite),
        .EX_MEM_MemRead(EX_MEM_MemRead)
    );
    // 00: ID/EX value; 01: WB; 10: EX/MEM ALU; 11: reserved (0).
    nbit_mux4by1 #(.N(32)) muxForwardA (
        .A(ID_EX_RegR1), .B(WriteData), .C(EX_MEM_ALU_out),
        .D(32'b0), .sel(ForwardA), .Out(ForwardedRs1)
    );
    nbit_mux4by1 #(.N(32)) muxForwardB (
        .A(ID_EX_RegR2), .B(WriteData), .C(EX_MEM_ALU_out),
        .D(32'b0), .sel(ForwardB), .Out(ForwardedRs2)
    );
    nbit_mux2by1 #(.N(32)) muxALUSrc1 (
        .A(ForwardedRs1), .B(ID_EX_PCOut), .sel(ID_EX_ALUSrc1),
        .Out(ALUIn1)
    );
    // 00: rs2; 01: immediate; 10: 4; 11: reserved (0).
    nbit_mux4by1 #(.N(32)) muxALUSrc2 (
        .A(ForwardedRs2), .B(ID_EX_Imm), .C(32'd4), .D(32'b0),
        .sel(ID_EX_ALUSrc2), .Out(ALUIn2)
    );
    alu_control_unit alucu (
        .ALUOp(ID_EX_ALUOp), .funct3(ID_EX_Func[3:1]),
        .funct7b5(ID_EX_Func[0]), .alucn(ALUsel)
    );
    prv32_ALU alu (
        .a(ALUIn1), .b(ALUIn2), .r(ALU_out),
        .cf(cf), .zf(zf), .vf(vf), .sf(sf), .alucn(ALUsel)
    );
    branch_cu bcu (
        .branch(ID_EX_valid && ID_EX_Branch),
        .funct3(ID_EX_Func[3:1]), .jump(ID_EX_valid && ID_EX_Jump),
        .cf(cf), .sf(sf), .zf(zf), .vf(vf), .PCJumpSel(PCJumpSel)
    );
    // JALR clears target bit 0; B-type / JAL target is PC + immediate.
    nbit_mux2by1 #(.N(32)) muxActualTarget (
        .A(BranchTarget), .B(JALRTarget), .sel(ID_EX_Jalr),
        .Out(ActualTarget)
    );
    nbit_mux2by1 #(.N(32)) muxRedirectPC (
        .A(SeqAfterBranch), .B(ActualTarget), .sel(taken),
        .Out(redirectPC)
    );
    mispredict_detector mdet (
        .branch(ID_EX_valid && ID_EX_Branch),
        .jump(ID_EX_valid && ID_EX_Jump),
        .taken(taken), .PredT(ID_EX_PredT), .target(ActualTarget),
        .PredTgt(ID_EX_PredTgt), .PC(ID_EX_PCOut),
        .mispredict(mispredict), .update_en(bp_update_en),
        .updateT(bp_update_taken), .updateTgt(bp_update_target),
        .updatePC(bp_update_pc)
    );

    // =====================================================================
    // EX/MEM: 77-bit positive-edge pipeline register
    // =====================================================================
    wire [31:0] EX_MEM_ALU_out_r, EX_MEM_RegR2;
    wire [4:0] EX_MEM_Rd_r;
    wire [2:0] EX_MEM_Func3;
    wire EX_MEM_valid_r, EX_MEM_RegWrite_r, EX_MEM_MemRead_r;
    wire EX_MEM_MemWrite, EX_MEM_MemtoReg;
    wire [EXMEM_WIDTH-1:0] EX_MEM_D, EX_MEM_Q;
    assign EX_MEM_D = {
        (ID_EX_valid && !ID_EX_Halt), ALU_out, ForwardedRs2,
        ID_EX_Rd, ID_EX_Func[3:1],
        (ID_EX_valid && ID_EX_RegWrite && !ID_EX_Halt),
        (ID_EX_valid && ID_EX_MemRead && !ID_EX_Halt),
        (ID_EX_valid && ID_EX_MemWrite && !ID_EX_Halt),
        ID_EX_MemtoReg
    };
    register_p #(.N(EXMEM_WIDTH)) EX_MEM (
        .clk(clk), .rst(rst), .load(1'b1), .D(EX_MEM_D), .Q(EX_MEM_Q)
    );
    assign {EX_MEM_valid_r, EX_MEM_ALU_out_r, EX_MEM_RegR2,
            EX_MEM_Rd_r, EX_MEM_Func3, EX_MEM_RegWrite_r,
            EX_MEM_MemRead_r, EX_MEM_MemWrite, EX_MEM_MemtoReg} = EX_MEM_Q;
    assign EX_MEM_valid = EX_MEM_valid_r;
    assign EX_MEM_RegWrite = EX_MEM_RegWrite_r;
    assign EX_MEM_MemRead = EX_MEM_MemRead_r;
    assign EX_MEM_ALU_out = EX_MEM_ALU_out_r;
    assign EX_MEM_Rd = EX_MEM_Rd_r;

    // =====================================================================
    // MEM: MEM-priority arbitration with physical 2-way address/funct muxes
    // =====================================================================
    wire mem_busy = EX_MEM_valid && (EX_MEM_MemRead || EX_MEM_MemWrite);
    wire [31:0] mem_address;
    wire [2:0] mem_funct3;
    wire mem_read_en = (mem_busy && EX_MEM_MemRead) ||
                       (!mem_busy && !halt_pending && !halted);
    wire mem_write_en = mem_busy && EX_MEM_MemWrite;
    nbit_mux2by1 #(.N(32)) muxMemAddress (
        .A(PCOut), .B(EX_MEM_ALU_out), .sel(mem_busy),
        .Out(mem_address)
    );
    nbit_mux2by1 #(.N(3)) muxMemFunct3 (
        .A(3'b010), .B(EX_MEM_Func3), .sel(mem_busy),
        .Out(mem_funct3)
    );
    single_ported_mem #(.ADDR_WIDTH(MEM_ADDR_WIDTH),
                        .INIT_FILE(MEM_INIT_FILE)) mem (
        .clk(clk), .MemRead(mem_read_en), .MemWrite(mem_write_en),
        .funct3(mem_funct3), .addr(mem_address),
        .data_in(EX_MEM_RegR2), .data_out(Mem_out)
    );

    // =====================================================================
    // MEM/WB: 72-bit positive-edge register, explicit 2-way WB mux
    // =====================================================================
    wire MEM_WB_valid_r, MEM_WB_RegWrite_r, MEM_WB_MemtoReg;
    wire [31:0] MEM_WB_Mem_out, MEM_WB_ALU_out;
    wire [4:0] MEM_WB_Rd_r;
    wire [MEMWB_WIDTH-1:0] MEM_WB_D, MEM_WB_Q;
    assign MEM_WB_D = {
        EX_MEM_valid, Mem_out, EX_MEM_ALU_out, EX_MEM_Rd,
        (EX_MEM_valid && EX_MEM_RegWrite), EX_MEM_MemtoReg
    };
    register_p #(.N(MEMWB_WIDTH)) MEM_WB (
        .clk(clk), .rst(rst), .load(1'b1), .D(MEM_WB_D), .Q(MEM_WB_Q)
    );
    assign {MEM_WB_valid_r, MEM_WB_Mem_out, MEM_WB_ALU_out,
            MEM_WB_Rd_r, MEM_WB_RegWrite_r, MEM_WB_MemtoReg} = MEM_WB_Q;
    assign MEM_WB_Rd = MEM_WB_Rd_r;
    assign MEM_WB_RegWrite = MEM_WB_RegWrite_r;
    assign MEM_WB_valid = MEM_WB_valid_r;
    nbit_mux2by1 #(.N(32)) muxWriteback (
        .A(MEM_WB_ALU_out), .B(MEM_WB_Mem_out),
        .sel(MEM_WB_MemtoReg), .Out(WriteData)
    );

    // =====================================================================
    // Hazard handling + EBREAK drain. halt state uses supplied register_p.
    // =====================================================================
    wire load_stall, mem_stall;
    hazard_detection_unit hdu (
        .ID_EX_MemRead(ID_EX_valid && ID_EX_MemRead),
        .ID_EX_RegisterRd(ID_EX_Rd),
        .IF_ID_RegisterRs1(Rs1), .IF_ID_RegisterRs2(Rs2),
        .IF_ID_UsesRs1(UsesRs1), .IF_ID_UsesRs2(UsesRs2),
        .EX_MEM_MemRead(EX_MEM_valid && EX_MEM_MemRead),
        .EX_MEM_MemWrite(EX_MEM_valid && EX_MEM_MemWrite),
        .mispredict(mispredict), .ebreak(ex_ebreak),
        .halt_pending(halt_pending || halted),
        .PCWrite(PCWrite), .IFIDWrite(IFIDWrite),
        .IFIDFlush(IFIDFlush), .IDEXFlush(IDEXFlush),
        .load_stall(load_stall), .mem_stall(mem_stall)
    );
    // Sticky flags are stored in register_p with OR feedback: no monolithic
    // always block in the top-level datapath.
    wire halt_pending_next = halt_pending || ex_ebreak;
    wire halted_next = halted ||
        (halt_pending && !EX_MEM_valid && !MEM_WB_valid);
    register_p #(.N(1)) halt_pending_register (
        .clk(clk), .rst(rst), .load(1'b1),
        .D(halt_pending_next), .Q(halt_pending)
    );
    register_p #(.N(1)) halted_register (
        .clk(clk), .rst(rst), .load(1'b1),
        .D(halted_next), .Q(halted)
    );
endmodule
