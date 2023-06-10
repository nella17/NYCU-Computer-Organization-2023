module branch_predictor #(
    parameter SIZE = 16,
    parameter DWIDTH = 32
) (
    input  clk,
    input  rst,
    input  control_hazard,
    input  [DWIDTH-1:0] if_pc, if_instr, ex_pc, ex_jpc,
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
            OPCODE_J,
            OPCODE_JAL: jump_type = J_TYPE_J;
            OPCODE_BEQ: jump_type = J_TYPE_BEQ;
            default:    jump_type = J_TYPE_NOP;
        endcase
    end

    // FIXME: when SIZE tooo large
    reg [DWIDTH-1:0] TARGET [SIZE-1:0];
    reg PREDICT [SIZE-1:0];
    reg INIT [SIZE-1:0];

    // FIXME: reset ?
    integer i;
    always @(posedge rst) begin
        for (i = 0; i < SIZE; i = i+1) begin
            TARGET[i] = i * 4 + 4;
            PREDICT[i] = 1;
            INIT[i] = 0;
        end
    end

    wire [$clog2(SIZE)-1:0] if_idx = if_pc[$clog2(SIZE)+1:2];
    wire [$clog2(SIZE)-1:0] ex_idx = ex_pc[$clog2(SIZE)+1:2];

    wire [DWIDTH-1:0] target = TARGET[if_idx];
    wire predict = PREDICT[if_idx];
    wire init = INIT[if_idx];

    reg [DWIDTH-1:0] npc;
    always @(*) begin
        if (~init)
            casez (jump_type)
                J_TYPE_NOP:
                    npc = if_pc4;
                J_TYPE_BEQ:
                    npc = if_pc4 + immediate * 4;
                J_TYPE_J:
                    npc = { if_pc4[31:28], address, 2'h0 };
                default:
                    npc = if_pc4;
            endcase
        else
            npc = target;
    end

    always @(*) begin
        if (predict)
            if_npc = npc;
        else
            if_npc = if_pc4;
    end

    always @(negedge clk) begin
        if (control_hazard)
            PREDICT[ex_idx] <= ex_jpc != ex_pc + 4;
        else if (jump_type == J_TYPE_J)
            PREDICT[if_idx] <= 1;
        else if (~init)
            PREDICT[if_idx] <= npc == if_pc4;
    end

    always @(posedge clk) begin
        if (control_hazard) begin
            INIT[ex_idx] <= 1;
            TARGET[ex_idx] <= ex_jpc;
        end else if (~init) begin
            INIT[if_idx] <= 1;
            TARGET[if_idx] <= npc;
        end
    end

endmodule
