    lui x1, 0x12345
    auipc x2, 0x1
    addi x3, x0, -17
    addi x4, x0, 7
    slti x5, x3, 0
    sltiu x6, x3, -1
    xori x7, x4, 3
    ori x8, x4, 8
    andi x9, x3, 15
    slli x10, x4, 3
    srli x11, x3, 3
    srai x12, x3, 3
    add x13, x3, x4
    sub x14, x4, x3
    sll x15, x4, x4
    slt x16, x3, x4
    sltu x17, x3, x4
    xor x18, x3, x4
    srl x19, x3, x4
    sra x20, x3, x4
    or x21, x3, x4
    and x22, x3, x4
    fence 0, 0
    fence.tso
    pause
    ecall
    addi x0, x0, 99
    ebreak
