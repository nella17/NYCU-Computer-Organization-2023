from sys import argv
from copy import deepcopy
import ctypes, random

count = int(argv[1]) if len(argv) >= 2 else 10
seed =  argv[2] if len(argv) >= 3 else random.randbytes(8).hex()

print(f'count = {count}')
print(f'seed = {seed}')

random.seed(seed)

chunk = lambda x: ctypes.c_int32(x).value
REGSIZE = 32
INSTRSIZE = 32
RANGE = {
    'r': (0, REGSIZE - 1),
    'i': (-2 ** 15, 2 ** 15 - 1),
}
MASK = {
    'i': 2 ** 16 - 1
}

class Registers:
    def __init__(self, size: int, chunk):
        self.regs = [ 0 ] * size
        self.chunk = chunk
    def rst(self):
        for i in range(len(self.regs)):
            self.regs[i] = 0
    def set(self, i: int, v: int):
        if i != 0:
            self.regs[i] = self.chunk(v)
    def get(self, i: int):
        return self.regs[i]
    def dump(self):
        return self.regs.copy()

class ALU:
    OP_AND = 0b0000
    OP_OR  = 0b0001
    OP_ADD = 0b0010
    OP_SUB = 0b0110
    OP_NOR = 0b1100
    OP_SLT = 0b0111

    OPs = {
        OP_AND: lambda rs1, rs2: rs1 & rs2,
        OP_OR : lambda rs1, rs2: rs1 | rs2,
        OP_ADD: lambda rs1, rs2: rs1 + rs2,
        OP_SUB: lambda rs1, rs2: rs1 - rs2,
        OP_NOR: lambda rs1, rs2: ~(rs1 | rs2),
        OP_SLT: lambda rs1, rs2: type(rs1)(rs1 < rs2),
    }

    @staticmethod
    def run(op: int, rs1: int, rs2: int):
        if op not in ALU.OPs:
            rd = 0
            zero = 0
            overflow = 0
        else:
            rd = ALU.OPs[op](rs1, rs2)
            rd = chunk(rd)
            zero = int(rd == 0)
            overflow = int(rd != rd)
            if overflow: zero = 0
        return (rd, zero, overflow)

class Instruction:
    def __init__(self,
            assembly: str,
            aluOP: int,
            Format: str,
            opcode: int,
            funct = 0
        ):
        self.assembly = assembly
        self.op, args = assembly.split(' ', maxsplit=1)
        self.params = args.split(', ')
        self.aluOP = aluOP
        self.Format = Format
        self.data = {
            'opcode': opcode,
            'funct': funct,
        }

    def compile(self):
        formats = {
            'R': { 'opcode': 6, 'rs': 5, 'rt': 5, 'rd': 5, 'shamt': 5, 'funct': 6 },
            'I': { 'opcode': 6, 'rs': 5, 'rt': 5, 'imm': 16 },
        }[self.Format]
        assert sum(formats.values()) == INSTRSIZE
        code = ''
        for key, size in formats.items():
            T = key[0]
            value = self.data.get(key, 0) & MASK.get(T, -1)
            binary = bin(value)[2:]
            assert len(binary) <= size
            code += binary.zfill(size)
        return int(code, 2)

    def asm(self):
        asm = self.assembly
        for key, value in self.data.items():
            value = str(value)
            if key.startswith('r'):
                value = 'r' + value
            asm = asm.replace(key, value)
        return asm

    def rand(self):
        new = deepcopy(self)
        for param in new.params:
            T = param[0]
            value = random.randint(*RANGE[T])
            new.data[param] = value
        return new

    def dump(self):
        code = self.compile()
        binary = bin(code)[2:].zfill(INSTRSIZE)
        asm = self.asm()
        return f'{binary} = {code}\n{asm}\n'

class Machine:
    def __init__(self):
        self.register = Registers(REGSIZE, chunk)
        self.instrs = [
            Instruction('add rd, rs, rt',   ALU.OP_ADD, 'R', 0x00, 0x20),
            Instruction('addi rt, rs, imm', ALU.OP_ADD, 'I', 0x08),
            Instruction('sub rd, rs, rt',   ALU.OP_SUB, 'R', 0x00, 0x22),
            Instruction('and rd, rs, rt',   ALU.OP_AND, 'R', 0x00, 0x24),
            Instruction('or rd, rs, rt',    ALU.OP_OR , 'R', 0x00, 0x25),
            Instruction('nor rd, rs, rt',   ALU.OP_NOR, 'R', 0x00, 0x27),
            Instruction('slt rd, rs, rt',   ALU.OP_SLT, 'R', 0x00, 0x2a),
            Instruction('slti rt, rs, imm', ALU.OP_SLT, 'I', 0x0a),
        ]
        self.instr_map = {
            instr.op: instr
            for instr in self.instrs
        }

    def run(self, instrs: list[Instruction]):
        inputs = ''
        debug = ''
        for idx, instr in enumerate(instrs):
            match len(instr.params):
                case 3:
                    op = instr.op
                    params = [instr.data[n] for n in instr.params]
                    rdst_id = params[0]
                    rs1_id, rs2_id, imm = 0, 0, 0
                    if op.endswith('i'):
                        op = op[:-1]
                        rs1_id = params[1]
                        rs1 = self.register.get(rs1_id)
                        rs2 = imm = params[2]
                        ssel = 0
                    else:
                        rs1_id = params[1]
                        rs1 = self.register.get(rs1_id)
                        rs2_id = params[2]
                        rs2 = self.register.get(rs2_id)
                        ssel = 1
                    rd = ALU.run(instr.aluOP, rs1, rs2)[0]
                    self.register.set(rdst_id, rd)
                    line = ('{} {} {} {} {} {} {}\n').format(
                        instr.compile(),
                        instr.aluOP,
                        ssel,
                        imm,
                        rs1_id,
                        rs2_id,
                        rdst_id,
                    )
                    inputs += line
                    debug += f'pattern {idx}\n'
                    debug += line
                    debug += instr.dump()
                    debug += f'{rd} = {rs1} @ {rs2}\n'
                    debug += str(instr.data) + '\n'
                    debug += '\n'
                case _:
                    raise Exception('not implement')
        return (inputs, debug, self.register.dump())

    def rand(self, count = 1):
        return [random.choice(self.instrs).rand() for _ in range(count)]

machine = Machine()
instrs = machine.rand(count)
inputs, debug, regs = machine.run(instrs)

with open('./input.txt', 'w') as f:
    f.write(inputs)
with open('./reg_file.txt', 'w') as f:
    f.write(' '.join(map(str, regs)))

with open('./debug.txt', 'w') as f:
    f.write(debug)
