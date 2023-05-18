module hazard_ctrl #(
    parameter DWIDTH = 32
) (
    input  rst,
    input  [4:0] id_rs1_id, id_rs2_id, ex_rdst_id, mem_rdst_id, wb_rdst_id,
    output reg [1:0] if_ctrl, id_ctrl, ex_ctrl, mem_ctrl
);

    localparam [1:0] C_PIPE  = 2'b00,
                     C_FLUSH = 2'b10,
                     C_STALL = 2'b01;

    always @(*) begin
        if (rst)
            if_ctrl = C_FLUSH;
        else if (id_ctrl == C_STALL || id_ctrl == C_FLUSH)
            if_ctrl = C_STALL;
        else
            if_ctrl = C_PIPE;
    end

    always @(*) begin
        if (rst)
            id_ctrl = C_FLUSH;
        else if (ex_ctrl == C_STALL || ex_ctrl == C_FLUSH)
            id_ctrl = C_STALL;
        else
            id_ctrl = C_PIPE;
    end

    always @(*) begin
        if (rst)
            ex_ctrl = C_FLUSH;
        else if (
            id_rs1_id != 0 && (id_rs1_id == ex_rdst_id || id_rs1_id == mem_rdst_id || id_rs1_id == wb_rdst_id) ||
            id_rs2_id != 0 && (id_rs2_id == ex_rdst_id || id_rs2_id == mem_rdst_id || id_rs2_id == wb_rdst_id)
        )
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

endmodule
