module core_top #(
    parameter DWIDTH = 32
)(
    input                 clk,
    input                 rst
);

    // Jump type
    localparam [2:0] J_TYPE_NOP = 3'b000,
                     J_TYPE_BEQ = 3'b001,
                     J_TYPE_JAL = 3'b010,
                     J_TYPE_JR  = 3'b011,
                     J_TYPE_J   = 3'b100;

    // IF imem
    reg  [DWIDTH-1:0] if_pc;
    wire [DWIDTH-1:0] if_instr;

    // ID
    reg  [DWIDTH-1:0] id_pc;
    reg  [DWIDTH-1:0] id_instr;
    // ID decode
    wire [2:0] id_jump_type;
    wire [DWIDTH-7:0] id_jump_addr;
    wire id_we_regfile, id_we_dmem, id_sel_dmem, id_ssel;
    wire [3:0] id_op;
    wire [DWIDTH-1:0] id_imm;
    wire [4:0] id_rs1_id, id_rs2_id, id_rdst_id;
    // ID reg
    wire [DWIDTH-1:0] id_rs1, id_rs2;

    // EX
    reg  [DWIDTH-1:0] ex_pc;
    reg  [2:0] ex_jump_type;
    reg  [DWIDTH-7:0] ex_jump_addr;
    reg  ex_we_regfile, ex_we_dmem, ex_sel_dmem, ex_ssel;
    reg  [3:0] ex_op;
    reg  [DWIDTH-1:0] ex_imm;
    reg  [4:0] ex_rdst_id;
    reg  [DWIDTH-1:0] ex_rs1, ex_rs2;
    wire [DWIDTH-1:0] ex_rs, ex_rt;
    // EX alu
    wire [DWIDTH-1:0] ex_rd;
    wire ex_zero, ex_overflow;

    // MEM
    reg  mem_we_dmem, mem_sel_dmem;
    reg  [4:0] mem_rdst_id;
    reg  [DWIDTH-1:0] mem_rs2;
    reg  [DWIDTH-1:0] mem_rd;
    // MEM dmem
    wire [DWIDTH-1:0] mem_wdata, mem_rdata;
    // MEM reg
    wire [DWIDTH-1:0] mem_rdst;

    // WB
    reg  [4:0] wb_rdst_id;
    reg  [DWIDTH-1:0] wb_rdst;

    always @(posedge clk) begin
        if (rst)
            if_pc <= 0;
        else
            casez (ex_jump_type)
                J_TYPE_NOP:
                    if_pc <= ex_pc + 4;
                J_TYPE_BEQ:
                    if_pc <= ex_pc + 4 + (ex_rs == ex_rt ? ex_imm * 4 : 0);
                J_TYPE_JAL,
                J_TYPE_J:
                    if_pc <= { ex_pc[31:28], ex_jump_addr, 2'h0 };
                J_TYPE_JR:
                    if_pc <= ex_rs;
                default:
                    if_pc <= ex_pc;
            endcase
    end

    imem imem_inst(
        .addr(if_pc),
        .rdata(if_instr)
    );

    always @(posedge clk) begin
        id_pc       <= if_pc;
        id_instr    <= if_instr;
    end

    decode decode_inst (
        // input
        .instr(id_instr),

        // output  
        .jump_type(id_jump_type),
        .jump_addr(id_jump_addr),
        .we_regfile(id_we_regfile),
        .we_dmem(id_we_dmem),
        .sel_dmem(id_sel_dmem),

        .op(id_op),
        .ssel(id_ssel),
        .imm(id_imm),
        .rs1_id(id_rs1_id),
        .rs2_id(id_rs2_id),
        .rdst_id(id_rdst_id)
    );

    reg_file reg_file_inst (
        // input
        .clk(clk),
        .rst(rst),

        .rs1_id(id_rs1_id),
        .rs2_id(id_rs2_id),

        .we(id_we_regfile),
        .rdst_id(wb_rdst_id),
        .rdst(wb_rdst),

        // output 
        .rs1(id_rs1), // rs
        .rs2(id_rs2)  // rt
    );

    always @(posedge clk) begin
        ex_pc           <= id_pc;
        ex_jump_type    <= id_jump_type;
        ex_jump_addr    <= id_jump_addr;
        ex_we_regfile   <= id_we_regfile;
        ex_we_dmem      <= id_we_dmem;
        ex_sel_dmem     <= id_sel_dmem;
        ex_ssel         <= id_ssel;
        ex_op           <= id_op;
        ex_imm          <= id_imm;
        ex_rdst_id      <= id_rdst_id;
        ex_rs1          <= id_rs1;
        ex_rs2          <= id_rs2;
    end

    assign ex_rs = ex_rs1;
    assign ex_rt = ex_jump_type == J_TYPE_JAL ? ex_pc + 4 :
                ~ex_ssel && ex_jump_type != J_TYPE_BEQ ? ex_imm :
                    ex_rs2;

    alu alu_inst (
        // input
        .op(ex_op),
        .rs1(ex_rs),
        .rs2(ex_rt),

        // output
        .rd(ex_rd),
        .zero(ex_zero),
        .overflow(ex_overflow)
    );

    always @(posedge clk) begin
        mem_we_dmem     <= ex_we_dmem;
        mem_sel_dmem    <= ex_sel_dmem;
        mem_rdst_id     <= ex_rdst_id;
        mem_rs2         <= ex_rs2;
        mem_rd          <= ex_rd;
    end

    assign mem_rdst = ~mem_sel_dmem ? mem_rdata : mem_rd;
    assign mem_wdata = mem_rs2;

    // Dmem
    dmem dmem_inst (
        .clk(clk),
        .addr(mem_rd),
        .we(mem_we_dmem),
        .wdata(mem_wdata),
        .rdata(mem_rdata)
    );

    always @(posedge clk) begin
        wb_rdst_id  <= mem_rdst_id;
        wb_rdst     <= mem_rdst;
    end

endmodule
