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

    always @(posedge clk) begin
        if (rst)
            pc <= 0;
    end
    
    imem imem_inst(
        .addr(),
        .rdata()
    );

    decode decode_inst (
        // input
        .instr(),

        // output  
        .jump_type(),
        .jump_addr(),
        .we_regfile(),
        .we_dmem(),

        .op(),
        .ssel(),
        .imm(),
        .rs1_id(),
        .rs2_id(),
        .rdst_id()
    );

    reg_file reg_file_inst (
        // input
        .clk(),
        .rst(),

        .rs1_id(),
        .rs2_id(),

        .we(),
        .rdst_id(),
        .rdst(),

        // output 
        .rs1(), // rs
        .rs2()  // rt
    );

    alu alu_inst (
        // input
        .op(),
        .rs1(),
        .rs2(),

        // output
        .rd(),
        .zero(),
        .overflow()
    );

    // Dmem
    dmem dmem_inst (
        .clk(),
        .addr(),
        .we(),
        .wdata(),
        .rdata()
    );

endmodule