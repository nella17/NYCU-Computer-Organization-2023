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

    // imm
    reg  [DWIDTH-1:0] pc;
    wire [DWIDTH-1:0] npc;
    wire [DWIDTH-1:0] instr;
    // decode
    wire [2:0] jump_type;
    wire [DWIDTH-7:0] jump_addr;
    wire we_regfile, we_dmem, sel_dmem;
    wire [3:0] op;
    wire ssel;
    wire [DWIDTH-1:0] imm;
    wire [4:0] rs1_id, rs2_id, rdst_id;
    // reg
    wire [DWIDTH-1:0] rdst, rs1, rs2;
    reg  [DWIDTH-1:0] rs, rt;
    // alu
    wire [DWIDTH-1:0] rd;
    wire zero, overflow;
    // dmem
    wire [DWIDTH-1:0] wdata, rdata;

    assign npc = pc + 4;
    always @(posedge clk) begin
        if (rst)
            pc <= 0;
        else
            casez (jump_type)
                J_TYPE_NOP:
                    pc <= npc;
                J_TYPE_BEQ:
                    pc <= npc + (rs == rt ? imm * 4 : 0);
                J_TYPE_JAL,
                J_TYPE_J:
                    pc <= { pc[31:28], jump_addr, 2'h0 };
                J_TYPE_JR:
                    pc <= rs;
                default:
                    pc <= pc;
            endcase
    end

    // TODO: ??
    assign rs = rs1;
    assign rt = jump_type == J_TYPE_JAL ? npc :
                ~ssel && jump_type != J_TYPE_BEQ ? imm :
                    rs2;
    assign rdst = ~sel_dmem ? rdata : rd;
    assign wdata = rs2;

    imem imem_inst(
        .addr(pc),
        .rdata(instr)
    );

    decode decode_inst (
        // input
        .instr(instr),

        // output  
        .jump_type(jump_type),
        .jump_addr(jump_addr),
        .we_regfile(we_regfile),
        .we_dmem(we_dmem),
        .sel_dmem(sel_dmem),

        .op(op),
        .ssel(ssel),
        .imm(imm),
        .rs1_id(rs1_id),
        .rs2_id(rs2_id),
        .rdst_id(rdst_id)
    );

    reg_file reg_file_inst (
        // input
        .clk(clk),
        .rst(rst),

        .rs1_id(rs1_id),
        .rs2_id(rs2_id),

        .we(we_regfile),
        .rdst_id(rdst_id),
        .rdst(rdst),

        // output 
        .rs1(rs1), // rs
        .rs2(rs2)  // rt
    );

    alu alu_inst (
        // input
        .op(op),
        .rs1(rs1),
        .rs2(rt),

        // output
        .rd(rd),
        .zero(zero),
        .overflow(overflow)
    );

    // Dmem
    dmem dmem_inst (
        .clk(clk),
        .addr(rd),
        .we(we_dmem),
        .wdata(wdata),
        .rdata(rdata)
    );

endmodule
