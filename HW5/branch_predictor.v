module branch_predictor #(
    parameter SIZE = 16,
    parameter DWIDTH = 32
) (
    input  clk,
    input  [DWIDTH-1:0] if_pc, if_instr,
    output reg [DWIDTH-1:0] if_npc
);
    import common::*;

    // decode instr
    // FIXME: when DWIDTH != 32
    wire [5:0] opcode = if_instr[31:26];
    wire [25:0] address = if_instr[25:0];
    wire [15:0] immediate = if_instr[15:0];
    wire [DWIDTH-1:0] if_pc4 = if_pc + 4;

    reg  [2:0] jump_type;
    always @ (*) begin
        casez (opcode)
            OPCODE_J:   jump_type = J_TYPE_J;
            OPCODE_JAL: jump_type = J_TYPE_JAL;
            OPCODE_BEQ: jump_type = J_TYPE_BEQ;
            default:    jump_type = J_TYPE_NOP;
        endcase
    end

    // FIXME: when SIZE tooo large
    reg [DWIDTH-1:0] TARGET [SIZE-1:0];
    reg PREDICT [SIZE-1:0];

    integer idx;
    initial begin
        for (idx = 0; idx < SIZE; idx = idx+1) begin
            TARGET[idx] = idx * 4 + 4;
            PREDICT[idx] = 1;
        end
    end

    wire [$clog2(SIZE)-1:0] idx = if_pc[$clog2(SIZE)+1:2];
    wire init = TARGET[idx] == if_pc4;

    reg [DWIDTH-1:0] target;
    always @(*) begin
        if (init)
            casez (jump_type)
                J_TYPE_NOP:
                    target = if_pc4;
                J_TYPE_BEQ:
                    target = if_pc4 + immediate * 4;
                J_TYPE_J:
                    target = { if_pc4[31:28], address, 2'h0 };
                default:
                    target = if_pc4;
            endcase
        else
            target = TARGET[idx];
    end

    always @(*) begin
        if (PREDICT[idx])
            if_npc = target;
        else
            if_npc = if_pc4;
    end

    always @(clk) begin
        // TODO
        if (0) begin
            TARGET[idx] <= 0;
        end else if (init) begin
            TARGET[idx] <= target;
        end
    end

endmodule
