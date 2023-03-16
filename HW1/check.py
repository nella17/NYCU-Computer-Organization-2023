import ctypes

with open('./input.txt') as f:
    lines = f.readlines()

TYPE = ctypes.c_int32

OPs = {
    0b0000: lambda rs1, rs2: rs1 & rs2,
    0b0001: lambda rs1, rs2: rs1 | rs2,
    0b0010: lambda rs1, rs2: rs1 + rs2,
    0b0110: lambda rs1, rs2: rs1 - rs2,
    0b1100: lambda rs1, rs2: ~(rs1 | rs2),
    0b0111: lambda rs1, rs2: type(rs1)(rs1 < rs2),
}

for line in lines:
    op, rs1, rs2, ans_rd, ans_zero, ans_overflow = map(int, line.strip().split())
    if op not in OPs:
        rd = zero = overflow = 0
    else:
        rrd = OPs[op](rs1, rs2)
        rd = TYPE(rrd).value
        zero = rd == 0
        overflow = rrd != rd
        if overflow: zero = 0
    if rd != ans_rd or zero != ans_zero or overflow != ans_overflow:
        print(line, rd, zero, overflow)
