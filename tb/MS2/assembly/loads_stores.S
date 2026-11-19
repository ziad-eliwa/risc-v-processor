    addi x1, x0, 1536
    lui x2, 0x80001
    addi x2, x2, -1
    sw x2, 0(x1)
    lb x3, 3(x1)
    addi x18, x3, 1
    lbu x4, 3(x1)
    lh x5, 2(x1)
    lhu x6, 2(x1)
    lw x7, 0(x1)
    addi x8, x0, 68
    sb x8, 1(x1)
    lw x9, 0(x1)
    addi x10, x0, -1
    sh x10, 2(x1)
    lh x11, 2(x1)
    lhu x12, 2(x1)
    lb x13, 2(x1)
    lbu x14, 2(x1)
    sh x8, 0(x1)
    lw x15, 0(x1)
    add x16, x15, x14
    ebreak
