module decode #(parameter DWIDTH = 32)
(
    input [DWIDTH-1:0]  instr,   // Input instruction.

    output reg [2 : 0]      jump_type,
    output reg [DWIDTH-7:0] jump_addr,
    output reg we_regfile,
    output reg we_dmem, re_dmem,

    output reg [3 : 0]      op,      // Operation code for the ALU.
    output reg              ssel,    // Select the signal for either the immediate value or rs2.

    output reg [DWIDTH-1:0] imm,     // The immediate value (if used).
    output reg [4 : 0]      rs1_id,  // register ID for rs.
    output reg [4 : 0]      rs2_id,  // register ID for rt (if used).
    output reg [4 : 0]      rdst_id  // register ID for rd or rt (if used).
);
    import common::*;

/***************************************************************************************
    ---------------------------------------------------------------------------------
    | R_type |    |   opcode   |   rs   |   rt   |   rd   |   shamt   |    funct    |
    ---------------------------------------------------------------------------------
    | I_type |    |   opcode   |   rs   |   rt   |             immediate            |
    ---------------------------------------------------------------------------------
    | J_type |    |   opcode   |                     address                        |
    ---------------------------------------------------------------------------------
                   31        26 25    21 20    16 15    11 10        6 5           0
 ***************************************************************************************/

    // FIXME: when DWIDTH != 32
    wire [5:0] opcode, funct;
    wire [4:0] rs, rt, rd, shamt;
    wire [15:0] immediate;
    wire [25:0] address;

    assign { opcode, address } = instr;
    assign { rs, rt, immediate } = address;
    assign { rd, shamt, funct } = immediate;

    // assign { opcode, rs, rt, rd, shamt, funct } = instr;
    // assign immediate = ssel ? 0 : instr[15:0];
    // assign address = instr[25:0];

    assign jump_addr = address;
    assign rs1_id = rs;
    assign rs2_id = rt;

    reg zero_imm;

    always @ (*) begin
        casez (opcode)
            OPCODE_JAL:
                        zero_imm = 1;
            default:    zero_imm = 0;
        endcase
    end

    always @ (*) begin
        casez (opcode)
            OPCODE_REGS:
                        ssel = 1;
            default:    ssel = 0;
        endcase
    end

    assign imm = (ssel || zero_imm) ? 0 : { {16{ immediate[15] }},  immediate };

    always @ (*) begin
        casez (opcode)
            OPCODE_REGS:
                casez (funct)
                    REGS_ADD: op = OP_ADD;
                    REGS_SUB: op = OP_SUB;
                    REGS_AND: op = OP_AND;
                    REGS_OR:  op = OP_OR;
                    REGS_NOR: op = OP_NOR;
                    REGS_SLT: op = OP_SLT;
                    REGS_JR:  op = OP_NOT_DEFINED;
                    default:  op = OP_NOT_DEFINED;
                endcase
            OPCODE_ADDI: op = OP_ADD;
            OPCODE_SLTI: op = OP_SLT;

            OPCODE_LW,
            OPCODE_SW:   op = OP_ADD;

            OPCODE_J,
            OPCODE_JAL,
            OPCODE_BEQ: op = OP_OR;

            default: op = OP_NOT_DEFINED;
        endcase
    end

    always @ (*) begin
        casez (opcode)
            OPCODE_REGS :
                casez (funct)
                    REGS_JR:  rdst_id = 0;
                    default:  rdst_id = rd;
                endcase
            OPCODE_ADDI,
            OPCODE_SLTI,
            OPCODE_LW  :
                        rdst_id = rt;
            OPCODE_JAL :
                        rdst_id = 5'd31;
            default:    
                        rdst_id = rd;
        endcase
    end

    always @ (*) begin
        casez (opcode)
            OPCODE_SW ,
            OPCODE_BEQ,
            OPCODE_J  :
                        we_regfile = 0;
            default:    we_regfile = 1;
        endcase
    end

    always @ (*) begin
        casez (opcode)
            OPCODE_SW :
                        we_dmem = 1;
            default:    we_dmem = 0;
        endcase
    end

    always @ (*) begin
        casez (opcode)
            OPCODE_LW:
                        re_dmem = 1;
            default:    re_dmem = 0;
        endcase
    end

    always @ (*) begin
        casez (opcode)
            OPCODE_REGS:
                casez (funct)
                    REGS_JR: jump_type = J_TYPE_JR;
                    default: jump_type = J_TYPE_NOP;
                endcase
            OPCODE_J:   jump_type = J_TYPE_J;
            OPCODE_JAL: jump_type = J_TYPE_JAL;
            OPCODE_BEQ: jump_type = J_TYPE_BEQ;
            default:    jump_type = J_TYPE_NOP;
        endcase
    end

endmodule
