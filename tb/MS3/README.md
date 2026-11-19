# All eight RV32I test programs in assembly

These listings match the supplied test/programs/*.hex machine code after assembly + linking.

Notes: execute from PC = 0, EBREAK halts; see .S files for encodings and PC addresses.

## alu_all

```asm
.option norvc
.option norelax
.section .text
.globl _start
_start:
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
```

Expected nonzero register values:
x1=0x12345000, x2=0x00001004, x3=0xFFFFFFEF, x4=0x00000007, x5=0x00000001, x6=0x00000001, x7=0x00000004, x8=0x0000000F, x9=0x0000000F, x10=0x00000038, x11=0x1FFFFFFD, x12=0xFFFFFFFD, x13=0xFFFFFFF6, x14=0x00000018, x15=0x00000380, x16=0x00000001, x18=0xFFFFFFE8, x19=0x01FFFFFF, x20=0xFFFFFFFF, x21=0xFFFFFFEF, x22=0x00000007

## loads_stores

```asm
.option norvc
.option norelax
.section .text
.globl _start
_start:
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
```

Expected nonzero register values:
x1=0x00000600, x2=0x80000FFF, x3=0xFFFFFF80, x4=0x00000080, x5=0xFFFF8000, x6=0x00008000, x7=0x80000FFF, x8=0x00000044, x9=0x800044FF, x10=0xFFFFFFFF, x11=0xFFFFFFFF, x12=0x0000FFFF, x13=0xFFFFFFFF, x14=0x000000FF, x15=0xFFFF0044, x16=0xFFFF0143, x18=0xFFFFFF81

## data_hazards

```asm
.option norvc
.option norelax
.section .text
.globl _start
_start:
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
    .word 0x00000007    # preload byte address 0x600

    .org 0x604
    .word 0x00000004    # preload byte address 0x604
```

Expected nonzero register values:
x1=0x00000600, x2=0x00000007, x3=0x0000000E, x4=0x00000015, x5=0x00000015, x7=0x00000004, x8=0x00000004, x9=0x00000008, x10=0x00000010, x11=0x00000020, x12=0x00000030

## control_transfers

```asm
.option norvc
.option norelax
.section .text
.globl _start
_start:
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
```

Expected nonzero register values:
x1=0x00000001, x2=0x00000002, x3=0x00000001, x8=0x00000003, x9=0x0000004C, x12=0x00000058, x14=0x0000002A

## branch_training

```asm
.option norvc
.option norelax
.section .text
.globl _start
_start:
    addi x1, x0, 9                      
    addi x2, x0, 0                      
loop:
    addi x2, x2, 1                      
    blt x2, x1, loop                    
    addi x3, x2, 13                     
    ebreak                              
```

Expected nonzero register values:
x1=0x00000009, x2=0x00000009, x3=0x00000016

## mem_arbitration

```asm
.option norvc
.option norelax
.section .text
.globl _start
_start:
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
```

Expected nonzero register values:
x1=0x00000600, x2=0x00000015, x3=0x00000015, x4=0x00000015, x5=0x00000015, x6=0x00000015, x7=0x00000015, x8=0x0000002A

## signed_boundaries

```asm
.option norvc
.option norelax
.section .text
.globl _start
_start:
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
    .word 0x8000ff80    # preload byte address 0x600
```

Expected nonzero register values:
x1=0x00000600, x2=0x8000FF80, x3=0x00000001, x4=0x00000001, x9=0xFFFFFFFF, x10=0x00000001, x11=0x7FFF0080

## btb_alias

```asm
.option norvc
.option norelax
.section .text
.globl _start
_start:
    jal x0, alias_pc                    
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
    addi x0, x0, 0                      
alias_pc:
    jal x0, done                        
    addi x1, x0, 99                     
done:
    addi x2, x0, 42                     
    ebreak                              
```

Expected nonzero register values:
x2=0x0000002A

