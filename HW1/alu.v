module alu #(parameter DWIDTH = 32)
(
    input [3 : 0] op,           // Operation to perform.
    input [DWIDTH-1 : 0] rs1,   // Input data #1.
    input [DWIDTH-1 : 0] rs2,   // Input data #2.
    output [DWIDTH-1 : 0] rd,   // Result of computation.
    output zero,                // zero = 1 if rd is 0, 0 otherwise.
    output overflow             // overflow = 1 if overflow happens.
);

endmodule
