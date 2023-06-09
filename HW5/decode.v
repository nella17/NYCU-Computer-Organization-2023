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

    // Jump type
    localparam [2:0] J_TYPE_NOP = 3'b000,
                     J_TYPE_BEQ = 3'b001,
                     J_TYPE_JAL = 3'b010,
                     J_TYPE_JR  = 3'b011,
                     J_TYPE_J   = 3'b100;

    localparam [5:0] OPCODE_REGS = 6'h00,
                     OPCODE_ADDI = 6'h08,
                     OPCODE_SLTI = 6'h0A,
                     OPCODE_LW   = 6'h23,
                     OPCODE_SW   = 6'h2b,
                     OPCODE_BEQ  = 6'h04,
                     OPCODE_JAL  = 6'h03,
                     OPCODE_J    = 6'h02;

    localparam [5:0] REGS_ADD = 6'h20,
                     REGS_SUB = 6'h22,
                     REGS_AND = 6'h24,
                     REGS_OR  = 6'h25,
                     REGS_NOR = 6'h27,
                     REGS_SLT = 6'h2A,
                     REGS_JR  = 6'h08;

    localparam [3:0] OP_AND = 4'b0000,
                     OP_OR  = 4'b0001,
                     OP_ADD = 4'b0010,
                     OP_SUB = 4'b0110,
                     OP_NOR = 4'b1100,
                     OP_SLT = 4'b0111,
                     OP_NOT_DEFINED = 4'b1111;

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
