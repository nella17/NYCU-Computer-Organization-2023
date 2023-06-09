module forwarding_uint #(
    parameter DWIDTH = 32
) (
    input  [4:0] ex_rs1_id, ex_rs2_id, mem_rdst_id, wb_rdst_id,
    input  mem_we_regfile, wb_we_regfile,
    input  [DWIDTH-1:0] mem_rdst, wb_rdst,
    output reg [1:0] fw_rs1, fw_rs2
);

    // fw type
    localparam [1:0] FW_EX  = 2'b00,
                     FW_MEM = 2'b01,
                     FW_WB  = 2'b10;

    always @(*) begin
        if (ex_rs1_id == 0)
            fw_rs1 = FW_EX;
        else if (mem_we_regfile && ex_rs1_id == mem_rdst_id)
            fw_rs1 = FW_MEM;
        else if (wb_we_regfile && ex_rs1_id == wb_rdst_id)
            fw_rs1 = FW_WB;
        else
            fw_rs1 = FW_EX;
    end

    always @(*) begin
        if (ex_rs2_id == 0)
            fw_rs2 = FW_EX;
        else if (mem_we_regfile && ex_rs2_id == mem_rdst_id)
            fw_rs2 = FW_MEM;
        else if (wb_we_regfile && ex_rs2_id == wb_rdst_id)
            fw_rs2 = FW_WB;
        else
            fw_rs2 = FW_EX;
    end

endmodule
