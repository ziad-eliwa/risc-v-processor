    addi x1, x0, 1536
    addi x2, x0, 21
    sw x2, 0(x1)
    lw x3, 0(x1)
    sw x3, 4(x1)
    lw x4, 4(x1)
    sw x4, 8(x1)
    lw x5, 8(x1)
    sw x5, 12(x1)
    lw x6, 12(x1)
    sw x6, 16(x1)
    lw x7, 16(x1)
    add x8, x7, x6
    ebreak
