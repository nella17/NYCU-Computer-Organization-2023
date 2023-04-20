module decode #(parameter DWIDTH = 32)
(
    input [DWIDTH-1:0]  instr,   // Input instruction.

    output reg [2 : 0]      jump_type,
    output reg [DWIDTH-7:0] jump_addr,
    output reg we_regfile,
    output reg we_dmem,
    output reg sel_dmem,

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

    assign rs1_id = rs;
    assign rs2_id = rt;
    assign imm = ssel ? 0 : { {16{ immediate[15] }},  immediate };

    always @ (*) begin
        casez (opcode)
            6'h0: begin
                rdst_id = rd;
                ssel = 1;
                casez (funct)
                    6'h20: begin // add
                        op = OP_ADD;
                    end
                    6'h22: begin // sub
                        op = OP_SUB;
                    end
                    6'h24: begin // and
                        op = OP_AND;
                    end
                    6'h25: begin // or
                        op = OP_OR;
                    end
                    6'h27: begin // nor
                        op = OP_NOR;
                    end
                    6'h2a: begin // slt
                        op = OP_SLT;
                    end
                    default: begin
                        op = OP_NOT_DEFINED;
                    end
                endcase
            end
            6'h8: begin // addi
                rdst_id = rt;
                ssel = 0;
                op = OP_ADD;
            end
            6'hA: begin // slti
                rdst_id = rt;
                ssel = 0;
                op = OP_SLT;
            end
            default: begin
                op = OP_NOT_DEFINED;
            end
        endcase
    end

endmodule
