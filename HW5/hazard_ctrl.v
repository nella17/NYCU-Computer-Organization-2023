module hazard_ctrl #(
    parameter DWIDTH = 32
) (
    input  rst,
    input  [4:0] id_rs1_id, id_rs2_id, ex_rdst_id, mem_rdst_id, wb_rdst_id,
    input  ex_re_dmem,
    input  [2:0] ex_jump_type,
    input  [DWIDTH-1:0] id_pc, ex_jpc,
    output reg [1:0] if_ctrl, id_ctrl, ex_ctrl, mem_ctrl, wb_ctrl
);

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

    wire data_hazard = 
            id_rs1_id != 0 && ex_re_dmem && id_rs1_id == ex_rdst_id ||
            id_rs2_id != 0 && ex_re_dmem && id_rs2_id == ex_rdst_id;

    wire control_hazard = ex_jump_type != J_TYPE_NOP && ex_jpc != id_pc;

    always @(*) begin
        if (rst)
            if_ctrl = C_FLUSH;
        else if (control_hazard)
            if_ctrl = C_JUMP;
        else if (id_ctrl == C_STALL || id_ctrl == C_FLUSH)
            if_ctrl = C_STALL;
        else
            if_ctrl = C_PIPE;
    end

    always @(*) begin
        if (rst)
            id_ctrl = C_FLUSH;
        else if (control_hazard)
            id_ctrl = C_FLUSH;
        else if (ex_ctrl == C_STALL || ex_ctrl == C_FLUSH)
            id_ctrl = C_STALL;
        else
            id_ctrl = C_PIPE;
    end

    always @(*) begin
        if (rst)
            ex_ctrl = C_FLUSH;
        else if (data_hazard || control_hazard)
            ex_ctrl = C_FLUSH;
        else
            ex_ctrl = C_PIPE;
    end

    always @(*) begin
        if (rst)
            mem_ctrl = C_FLUSH;
        else
            mem_ctrl = C_PIPE;
    end

    assign wb_ctrl = C_PIPE;

endmodule
