module alu #(parameter DWIDTH = 32)
(
    input [3 : 0] op,           // Operation to perform.
    input signed [DWIDTH-1 : 0] rs1,   // Input data #1.
    input signed [DWIDTH-1 : 0] rs2,   // Input data #2.
    output reg signed [DWIDTH-1 : 0] rd,   // Result of computation.
    output zero,                // zero = 1 if rd is 0, 0 otherwise.
    output overflow             // overflow = 1 if overflow happens.
);

    assign zero = rd == 0;

    always @(*) begin
        casez (op)
            4'b0000: rd = rs1 & rs2;
            4'b0001: rd = rs1 | rs2;
            4'b0010: rd = rs1 + rs2;
            4'b0110: rd = rs1 - rs2;
            4'b1100: rd = ~(rs1 | rs2);
            4'b0111: rd = { DWIDTH{ rs1 < rs2 } };
            default: rd = 0;
        endcase
    end

    always @(*) begin
        casez (op)
            4'b0010:
                overflow = (rs1 >= 0 && rs2 >= 0 && rd < 0) || (rs1 < 0 && rs2 < 0 && rd >= 0);
            4'b0110:
                overflow = (rs1 >= 0 && rs2 < 0 && rd < 0) || (rs1 < 0 && rs2 >= 0 && rd >= 0);
            default:
                overflow = 0;
        endcase
    end

endmodule