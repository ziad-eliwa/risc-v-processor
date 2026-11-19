    addi x1, x0, 1536
    lw x2, 0(x1)
    slti x3, x2, 0
    sltiu x4, x2, -1
    blt x2, x0, less
    addi x5, x0, 99
less:
    bge x0, x2, ge
    addi x6, x0, 99
ge:
    bltu x0, x2, unsigned_less
    addi x7, x0, 99
unsigned_less:
    bgeu x2, x0, unsigned_ge
    addi x8, x0, 99
unsigned_ge:
    srai x9, x2, 31
    srli x10, x2, 31
    sub x11, x0, x2
    ebreak

    .org 0x600
    .word 0x8000ff80
