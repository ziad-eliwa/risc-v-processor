    addi x1, x0, 1
    addi x2, x0, 2
    beq x1, x2, skip1
    addi x3, x0, 1
skip1:
    bne x1, x2, bne_t
    addi x3, x0, 99
bne_t:
    blt x1, x2, blt_t
    addi x4, x0, 99
blt_t:
    bge x2, x1, bge_t
    addi x5, x0, 99
bge_t:
    bltu x1, x2, bltu_t
    addi x6, x0, 99
bltu_t:
    bgeu x2, x1, bgeu_t
    addi x7, x0, 99
bgeu_t:
    beq x1, x1, beq_t
    addi x8, x0, 99
beq_t:
    bne x1, x1, nottaken
    addi x8, x0, 3
nottaken:
    jal x9, jal_target
    addi x10, x0, 99
jal_target:
    addi x11, x0, 0
    jalr x12, 96(x11)
    addi x13, x0, 99
    ebreak
jalr_target:
    addi x14, x0, 42
    ebreak
