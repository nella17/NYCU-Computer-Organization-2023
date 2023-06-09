module hazard_ctrl #(
    parameter DWIDTH = 32
) (
    input  rst,
    input  [4:0] id_rs1_id, id_rs2_id, ex_rdst_id, mem_rdst_id, wb_rdst_id,
    input  ex_re_dmem,
    input  [2:0] ex_jump_type,
    input  [DWIDTH-1:0] id_pc, ex_pc, ex_npc, ex_jpc,
    output reg [1:0] if_ctrl, id_ctrl, ex_ctrl, mem_ctrl, wb_ctrl
);
    import common::*;

    wire data_hazard = 
            id_rs1_id != 0 && ex_re_dmem && id_rs1_id == ex_rdst_id ||
            id_rs2_id != 0 && ex_re_dmem && id_rs2_id == ex_rdst_id;

    wire control_hazard = (ex_pc != 0 || ex_npc != 0) && ex_jpc != id_pc;

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
