    addi x1, x0, 9
    addi x2, x0, 0
loop:
    addi x2, x2, 1
    blt x2, x1, loop
    addi x3, x2, 13
    ebreak
