    li   sp, 0xF00  # stack top
    addi s0, zero, 0x600  # raw sensor readings
    addi s1, zero, 0x700  # report output
    li   s2, 0x800  # calibrated 32-bit readings
    li   s3, 0x880  # status bytes
    li   a3, 0x8C0  # compact signed 16-bit output

    addi s4, zero, 0      # sample index [0..15]
    addi s5, zero, 0      # sum
    li   s6, 0x7fffffff   # minimum
    li   s7, 0x80000000   # maximum
    addi s8, zero, 0      # cold count
    addi s9, zero, 0      # normal count
    addi s10, zero, 0     # hot count
    addi s11, zero, 0     # alarm count
    li   t3, 0x13579BDF  # initial rolling checksum
    addi t4, zero, 0      # hottest index
    addi t5, zero, 0      # coldest index
    addi t6, zero, -1     # first alarm index, -1 means none
    addi a4, zero, 0      # alarm bitmask
    addi a5, zero, 16     # number of samples
    addi a6, zero, 0      # integrity error flag

process_loop:
    jal  ra, process_one
    addi s4, s4, 1
    bltu s4, a5, process_loop  # loop uses unsigned comparison

    jal  ra, finalize_report
    ebreak                     # halt processor after all stores complete
    addi a7, zero, 99          # unreachable: must NEVER execute

    # process_one: update statistics and output one calibrated sensor reading
process_one:
    addi sp, sp, -16
    sw   ra, 12(sp)             # stack call/return test

    lw   t0, 0(s0)              # raw signed Celsius
    addi t1, t0, 2             # sensor calibration +2 C
    add  s5, s5, t1            # sum all corrected temperatures

    bge  t1, s6, min_done
    add  s6, t1, zero
    add  t5, s4, zero
min_done:
    bge  s7, t1, max_done
    add  s7, t1, zero
    add  t4, s4, zero
max_done:
    sw   t1, 0(s2)              # full precision corrected reading
    sh   t1, 0(a3)              # compact 16-bit telemetry reading
    lh   a1, 0(a3)              # signed readback verifies compact value
    beq  a1, t1, compact_ok
    addi a6, zero, 1            # report integrity error, don't crash
compact_ok:
    lhu  a2, 0(a3)              # unsigned low-16 bits for checksum
    jal  ra, mix_checksum

    add  a0, t1, zero           # classify the calibrated reading
    jal  ra, classify_temp     # a0 becomes 0, 1 or 2

    slti a1, t1, 5             # severe cold: temperature < 5
    slti a2, t1, 40            # invert to detect >= 40
    xori a2, a2, 1
    or   a1, a1, a2
    slli a1, a1, 2             # alarm bit goes in bit 2
    or   a0, a0, a1            # status = classification | (alarm << 2)
    sb   a0, 0(s3)

    lbu  a1, 0(s3)              # byte readback / store-to-load dependency
    lb   a2, 0(s3)              # signed byte readback, status is 0..6
    beq  a1, a2, status_ok
    addi a6, zero, 1
status_ok:
    andi a0, a1, 3             # strip alarm bit; get class
    beq  a0, zero, count_cold
    addi a2, zero, 1
    beq  a0, a2, count_normal
    addi s10, s10, 1
    jal  zero, counts_done
count_cold:
    addi s8, s8, 1
    jal  zero, counts_done
count_normal:
    addi s9, s9, 1
counts_done:
    andi a2, a1, 4
    beq  a2, zero, alarm_done
    addi s11, s11, 1
    srli a2, a2, 2             # alarm bit -> 1
    sll  a2, a2, s4            # one alarm bit per sensor
    or   a4, a4, a2            # accumulate 16-bit alarm mask
    bge  t6, zero, alarm_done  # don't replace first alarm index
    add  t6, s4, zero
alarm_done:
    addi s0, s0, 4             # next raw 32-bit reading
    addi s2, s2, 4             # next calibrated 32-bit slot
    addi s3, s3, 1             # next status byte
    addi a3, a3, 2             # next signed 16-bit slot

    lw   ra, 12(sp)
    addi sp, sp, 16
    jalr zero, 0(ra)            # subroutine return (JALR)

    # classify_temp(a0): returns 0=cold, 1=normal, 2=hot
classify_temp:
    slti a1, a0, 18
    bne  a1, zero, is_cold
    slti a1, a0, 30
    bne  a1, zero, is_normal
    addi a0, zero, 2
    jalr zero, 0(ra)
is_cold:
    addi a0, zero, 0
    jalr zero, 0(ra)
is_normal:
    addi a0, zero, 1
    jalr zero, 0(ra)

    # mix_checksum: update t3 with ROTL32(t3,5) xor zero-extended LH output
mix_checksum:
    slli a0, t3, 5
    srli a1, t3, 27
    or   a0, a0, a1
    xor  t3, a0, a2
    jalr zero, 0(ra)

    # finalize_report: write a report with the sample summary and health flags.
finalize_report:
    li   a0, 0x47524E48         # ASCII "GRNH" magic, report ready
    sw   a0, 0(s1)
    sw   s5, 4(s1)              # calibrated sum
    srai a0, s5, 4              # arithmetic mean of exactly 16 readings
    sw   a0, 8(s1)              # signed floor(sum / 16)
    sw   s6, 12(s1)             # minimum temperature
    sw   s7, 16(s1)             # maximum temperature
    sw   s8, 20(s1)             # cold count
    sw   s9, 24(s1)             # normal count
    sw   s10, 28(s1)            # hot count
    sw   s11, 32(s1)            # severe alarm count

    sltiu a1, s11, 1
    xori  a1, a1, 1
    sltiu a2, s10, 4
    xori  a2, a2, 1
    slli  a2, a2, 1
    or    a1, a1, a2
    sltiu a2, s8, 4
    xori  a2, a2, 1
    slli  a2, a2, 2
    or    a1, a1, a2
    slti  a2, a0, 30
    xori  a2, a2, 1
    slli  a2, a2, 3
    or    a1, a1, a2
    sw    a1, 36(s1)            # overall warning flags

    sw   t3, 40(s1)             # rolling checksum of compact data
    sw   t6, 44(s1)             # first severe alarm index
    sw   t4, 48(s1)             # maximum temperature index
    sw   t5, 52(s1)             # minimum temperature index
    addi a0, zero, 16
    sw   a0, 56(s1)             # number of samples analyzed
    sw   a4, 60(s1)             # per-sensor alarm bitmask

    add  a0, s8, s9
    add  a0, a0, s10
    bne  a0, a5, report_bad
    bne  a6, zero, report_bad
    li   a0, 0x600D             # success code
    jal  zero, report_status
report_bad:
    li   a0, 0xBAD              # consistency failure code
report_status:
    sw   a0, 64(s1)
    jalr zero, 0(ra)

    # Input temperatures at address 0x600
    .org 0x600
raw_temperatures:
    .word -10, 12, 17, 20
    .word 25, 27, 32, 38
    .word 41, 5, 16, 22
    .word 29, 35, -3, 19
