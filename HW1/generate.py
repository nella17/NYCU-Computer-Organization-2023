import ctypes
import random

CNT = 1000

DWIDTH = 32
TYPE = ctypes.c_int32
mn = -2**(DWIDTH-1)
mx = 2**(DWIDTH-1) - 1

OPbits = 4
OPs = {
    0b0000: lambda rs1, rs2: rs1 & rs2,
    0b0001: lambda rs1, rs2: rs1 | rs2,
    0b0010: lambda rs1, rs2: rs1 + rs2,
    0b0110: lambda rs1, rs2: rs1 - rs2,
    0b1100: lambda rs1, rs2: ~(rs1 | rs2),
    0b0111: lambda rs1, rs2: type(rs1)(rs1 < rs2),
}

for i in range(CNT):
    if i == 0:
        op = random.choice([x for x in range(2**OPbits) if x not in OPs])
    else:
        op = random.choice(list(OPs.keys()))

    rs1 = random.randint(mn, mx)
    rs2 = random.randint(mn, mx)

    if op not in OPs:
        ans_rd = 0
        ans_zero = 0
        ans_overflow = 0
    else:
        rd = OPs[op](rs1, rs2)
        ans_rd = TYPE(rd).value
        ans_zero = int(ans_rd == 0)
        ans_overflow = int(ans_rd != rd)
        if ans_overflow: ans_zero = 0

    print(f'{op} {rs1} {rs2} {ans_rd} {ans_zero} {ans_overflow}')

