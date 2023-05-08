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

    // Program Counter signals
    reg  [DWIDTH-1:0] pc;
    wire [DWIDTH-1:0] pc_increment;

    // Decode signals
    reg  [DWIDTH-1:0] instr;
    wire [3:0]        op;
    wire              ssel;
    wire [1:0]        wbsel;
    wire              we_regfile;
    wire              we_dmem;
    wire [2:0]        jump_type;
    wire [25:0]       jump_addr;
    wire [DWIDTH-1:0] imm;
    wire [4:0]        rs1_id;
    wire [4:0]        rs2_id;
    wire [4:0]        rdst_id;
    
    // Regfile signals
    reg  [DWIDTH-1:0] rd;
    wire [DWIDTH-1:0] rs1_out;
    wire [DWIDTH-1:0] rs2_out;

    // ALU signals
    reg  [DWIDTH-1:0] alu_rs1;
    reg  [DWIDTH-1:0] alu_rs2;
    wire [DWIDTH-1:0] alu_out;
    wire              zero;
    wire              overflow;

    // Dmem signals
    wire [DWIDTH-1:0] dmem_out;

    // Program counter
    assign pc_increment = pc + 4;

    always @(posedge clk) begin
        if (rst)
            pc <= 0;
        else if (jump_type == J_TYPE_BEQ && zero) 
            pc <= pc_increment + {imm[29:0], 2'b00};
        else if (jump_type == J_TYPE_JR) 
            pc <= rs1_out;
        else if (jump_type == J_TYPE_JAL || jump_type == J_TYPE_J) 
            pc <= {pc[31:28], jump_addr, 2'b00};
        else
            pc <= pc_increment;
    end
    
    imem imem_inst(
        .addr(pc),
        .rdata(instr)
    );

    decode decode_inst (
        // input
        .instr(instr),

        // output  
        .op(op),
        .ssel(ssel),
        .wbsel(wbsel),
        .we_regfile(we_regfile),
        .we_dmem(we_dmem),
        .jump_type(jump_type),
        .jump_addr(jump_addr),
        .imm(imm),
        .rs1_id(rs1_id),
        .rs2_id(rs2_id),
        .rdst_id(rdst_id)
    );

    // Regfile
    always @(*) begin
        case (wbsel)
            2'b00:   rd = alu_out;
            2'b01:   rd = dmem_out;
            2'b10:   rd = pc_increment;
            default: rd = 0;
        endcase
    end

    reg_file reg_file_inst (
        // input
        .clk(clk),
        .rst(rst),

        .rs1_id(rs1_id),
        .rs2_id(rs2_id),

        .we(we_regfile),
        .rdst_id(rdst_id),
        .rdst(rd),

        // output 
        .rs1(rs1_out), // rs
        .rs2(rs2_out)  // rt
    );

    // ALU
    always @(*) begin
        alu_rs1 = rs1_out;
    end

    always @(*) begin
        alu_rs2 = ssel ? rs2_out : imm;
    end

    alu alu_inst (
        // input
        .op(op),
        .rs1(alu_rs1),
        .rs2(alu_rs2),

        // output
        .rd(alu_out),
        .zero(zero),
        .overflow(overflow)
    );

    // Dmem
    dmem dmem_inst (
        .clk(clk),
        .addr(alu_out),
        .we(we_dmem),
        .wdata(rs2_out),
        .rdata(dmem_out)
    );

endmodule