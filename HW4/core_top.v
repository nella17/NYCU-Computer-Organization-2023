`define PIPE(clk, ctrl, out, in)    \
    always @(posedge clk) begin     \
        casez (ctrl)                \
            C_PIPE : out <= in;     \
            C_FLUSH: out <= 0;      \
            C_STALL: out <= out;    \
            default: out <= out;    \
        endcase                     \
    end

module core_top #(
    parameter DWIDTH = 32
)(
    input                 clk,
    input                 rst
);


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

    // IF imem
    reg  [DWIDTH-1:0] if_pc;
    wire [DWIDTH-1:0] if_npc;
    wire [DWIDTH-1:0] if_instr;

    // ID
    reg  [DWIDTH-1:0] id_pc, id_npc;
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
    reg  [DWIDTH-1:0] ex_pc, ex_npc, ex_jpc;
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
    reg  mem_we_regfile, mem_we_dmem, mem_sel_dmem;
    reg  [4:0] mem_rdst_id;
    reg  [DWIDTH-1:0] mem_rs2;
    reg  [DWIDTH-1:0] mem_rd;
    // MEM dmem
    wire [DWIDTH-1:0] mem_wdata, mem_rdata;
    // MEM reg
    wire [DWIDTH-1:0] mem_rdst;

    // WB
    reg  wb_we_regfile;
    reg  [4:0] wb_rdst_id;
    reg  [DWIDTH-1:0] wb_rdst;

    wire [1:0] if_ctrl, id_ctrl, ex_ctrl, mem_ctrl;
    hazard_ctrl hazard_ctrl_inst(
        .rst(rst),

        .id_rs1_id  (id_rs1_id  ),
        .id_rs2_id  (id_rs2_id  ),
        .ex_rdst_id (ex_rdst_id ),
        .mem_rdst_id(mem_rdst_id),
        .wb_rdst_id (wb_rdst_id ),

        .ex_jump_type(ex_jump_type),
        .id_pc(id_pc),
        .ex_jpc(ex_jpc),

        .if_ctrl (if_ctrl ),
        .id_ctrl (id_ctrl ),
        .ex_ctrl (ex_ctrl ),
        .mem_ctrl(mem_ctrl)
    );

    assign if_npc = if_pc + 4;

    always @(posedge clk) begin
        casez (if_ctrl)
            C_PIPE:
                if_pc <= if_npc;
            C_JUMP:
                if_pc <= ex_jpc;
            C_FLUSH:
                if_pc <= 0;
            C_STALL:
                if_pc <= if_pc;
            default:
                if_pc <= if_pc;
        endcase
    end

    imem imem_inst(
        .addr(if_pc),
        .rdata(if_instr)
    );

    `PIPE(clk, id_ctrl, id_pc   , if_pc   );
    `PIPE(clk, id_ctrl, id_npc  , if_npc  );
    `PIPE(clk, id_ctrl, id_instr, if_instr);

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

        .we(wb_we_regfile),
        .rdst_id(wb_rdst_id),
        .rdst(wb_rdst),

        // output 
        .rs1(id_rs1), // rs
        .rs2(id_rs2)  // rt
    );

    `PIPE(clk, ex_ctrl, ex_pc        , id_pc         );
    `PIPE(clk, ex_ctrl, ex_npc       , id_npc        );
    `PIPE(clk, ex_ctrl, ex_jump_type , id_jump_type  );
    `PIPE(clk, ex_ctrl, ex_jump_addr , id_jump_addr  );
    `PIPE(clk, ex_ctrl, ex_we_regfile, id_we_regfile );
    `PIPE(clk, ex_ctrl, ex_we_dmem   , id_we_dmem    );
    `PIPE(clk, ex_ctrl, ex_sel_dmem  , id_sel_dmem   );
    `PIPE(clk, ex_ctrl, ex_ssel      , id_ssel       );
    `PIPE(clk, ex_ctrl, ex_op        , id_op         );
    `PIPE(clk, ex_ctrl, ex_imm       , id_imm        );
    `PIPE(clk, ex_ctrl, ex_rdst_id   , id_rdst_id    );
    `PIPE(clk, ex_ctrl, ex_rs1       , id_rs1        );
    `PIPE(clk, ex_ctrl, ex_rs2       , id_rs2        );

    always @(*) begin
        casez (ex_jump_type)
            J_TYPE_NOP:
                ex_jpc = ex_npc;
            J_TYPE_BEQ:
                ex_jpc = ex_npc + (ex_rs == ex_rt ? ex_imm * 4 : 0);
            J_TYPE_JAL,
            J_TYPE_J:
                ex_jpc = { ex_npc[31:28], ex_jump_addr, 2'h0 };
            J_TYPE_JR:
                ex_jpc = ex_rs;
            default:
                ex_jpc = ex_npc;
        endcase
    end


    assign ex_rs = ex_rs1;
    assign ex_rt = ex_jump_type == J_TYPE_JAL ? ex_npc :
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

    `PIPE(clk, mem_ctrl, mem_we_regfile, ex_we_regfile );
    `PIPE(clk, mem_ctrl, mem_we_dmem   , ex_we_dmem    );
    `PIPE(clk, mem_ctrl, mem_sel_dmem  , ex_sel_dmem   );
    `PIPE(clk, mem_ctrl, mem_rdst_id   , ex_rdst_id    );
    `PIPE(clk, mem_ctrl, mem_rs2       , ex_rs2        );
    `PIPE(clk, mem_ctrl, mem_rd        , ex_rd         );

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

    assign wb_we_regfile    = mem_we_regfile;
    assign wb_rdst_id       = mem_rdst_id;
    assign wb_rdst          = mem_rdst;

endmodule
