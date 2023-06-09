package common;

// hazard type
localparam [1:0] C_PIPE  = 2'b00,
                 C_FLUSH = 2'b10,
                 C_STALL = 2'b01,
                 C_JUMP  = 2'b11;

// Jump type
localparam [2:0] J_TYPE_NOP = 3'b000,
                 J_TYPE_BEQ = 3'b001,
                 J_TYPE_JAL = 3'b010,
                 J_TYPE_JR  = 3'b011,
                 J_TYPE_J   = 3'b100;

// fw type
localparam [1:0] FW_EX  = 2'b00,
                 FW_MEM = 2'b01,
                 FW_WB  = 2'b10;

// instruction opcode
localparam [5:0] OPCODE_REGS = 6'h00,
                 OPCODE_ADDI = 6'h08,
                 OPCODE_SLTI = 6'h0A,
                 OPCODE_LW   = 6'h23,
                 OPCODE_SW   = 6'h2b,
                 OPCODE_BEQ  = 6'h04,
                 OPCODE_JAL  = 6'h03,
                 OPCODE_J    = 6'h02;

// instruction register function
localparam [5:0] REGS_ADD = 6'h20,
                 REGS_SUB = 6'h22,
                 REGS_AND = 6'h24,
                 REGS_OR  = 6'h25,
                 REGS_NOR = 6'h27,
                 REGS_SLT = 6'h2A,
                 REGS_JR  = 6'h08;

// alu opcode
localparam [3:0] OP_AND = 4'b0000,
                 OP_OR  = 4'b0001,
                 OP_ADD = 4'b0010,
                 OP_SUB = 4'b0110,
                 OP_NOR = 4'b1100,
                 OP_SLT = 4'b0111,
                 OP_NOT_DEFINED = 4'b1111;

endpackage: common;
