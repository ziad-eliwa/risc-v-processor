    addi x1, x0, 1536
    lw x2, 0(x1)
    add x3, x2, x2
    add x4, x3, x2
    sw x4, 8(x1)
    lw x5, 8(x1)
    beq x5, x4, ok
    addi x6, x0, 99
ok:
    lw x7, 4(x1)
    sw x7, 12(x1)
    lw x8, 12(x1)
    add x9, x8, x7
    add x10, x9, x9
    add x11, x10, x10
    add x12, x11, x10
    ebreak

    .org 0x600
    .word 0x00000007

    .org 0x604
    .word 0x00000004
