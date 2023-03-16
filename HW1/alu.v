module alu #(parameter DWIDTH = 32)
(
    input [3 : 0] op,           // Operation to perform.
    input signed [DWIDTH-1 : 0] rs1,   // Input data #1.
    input signed [DWIDTH-1 : 0] rs2,   // Input data #2.
    output reg signed [DWIDTH-1 : 0] rd,   // Result of computation.
    output zero,                // zero = 1 if rd is 0, 0 otherwise.
    output overflow             // overflow = 1 if overflow happens.
);

    localparam [3:0] OP_AND = 4'b0000,
                     OP_OR  = 4'b0001,
                     OP_ADD = 4'b0010,
                     OP_SUB = 4'b0110,
                     OP_NOR = 4'b1100,
                     OP_SLT = 4'b0111;

    reg valid;
    always @(*) begin
        casez (op)
            `OP_AND,
            `OP_OR ,
            `OP_ADD,
            `OP_SUB,
            `OP_NOR,
            `OP_SLT:
                valid = 1;
            default:
                valid = 0;
        endcase
    end

    assign zero = valid && ~overflow && rd == 0;

    always @(*) begin
        casez (op)
            `OP_AND: rd = rs1 & rs2;
            `OP_OR : rd = rs1 | rs2;
            `OP_ADD: rd = rs1 + rs2;
            `OP_SUB: rd = rs1 - rs2;
            `OP_NOR: rd = ~(rs1 | rs2);
            `OP_SLT: rd = { {(DWIDTH-1){ 1'h0 }}, rs1 < rs2 };
            default: rd = 0;
        endcase
    end

    always @(*) begin
        casez (op)
            `OP_ADD:
                overflow = (rs1 >= 0 && rs2 >= 0 && rd < 0) || (rs1 < 0 && rs2 < 0 && rd >= 0);
            `OP_SUB:
                overflow = (rs1 >= 0 && rs2 < 0 && rd < 0) || (rs1 < 0 && rs2 >= 0 && rd >= 0);
            default:
                overflow = 0;
        endcase
    end

endmodule
