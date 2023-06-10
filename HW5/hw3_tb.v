/*
 *    Author : Che-Yu Wu @ EISL
 *    Date   : 2022-03-30
 */

module hw3_tb (
    input         clk,
    input         rst,
    output reg    correctness
);

    localparam DWIDTH = 32;

    integer i, tmp;

    reg [31:0] golden_reg[0:31];
    reg [31:0] golden_dmem[0:15];

    reg [31:0] correctness_reg;
    reg [15:0] correctness_dmem;


    core_top core_top_inst (
        .clk(clk),
        .rst(rst)
    );

    initial begin
        correctness = 0;
    end

    always @(*) begin

        for (i = 0; i < 32; i = i + 1) begin
            correctness_reg[i] = (golden_reg[i] == core_top_inst.reg_file_inst.R[i]);
        end

        for (i = 0; i < 16; i = i + 1) begin
            correctness_dmem[i] = (golden_dmem[i] == core_top_inst.dmem_inst.RAM[i]);
        end

        correctness = (&correctness_reg) && (&correctness_dmem);
    end

task write_golden_reg;
/* verilator public */
    input integer byte_addr;
    input [31:0] val;
    begin
        golden_reg[byte_addr] = val;
    end
endtask

task write_golden_dmem;
/* verilator public */
    input integer byte_addr;
    input [31:0] val;
    begin
        golden_dmem[byte_addr] = val;
    end
endtask

task write_imem;
/* verilator public */
    input integer byte_addr;
    input [31:0] val;
    begin
        core_top_inst.imem_inst.RAM[byte_addr] = val;
    end
endtask

task write_dmem;
/* verilator public */
    input integer byte_addr;
    input [31:0] val;
    begin
        core_top_inst.dmem_inst.RAM[byte_addr] = val;
    end
endtask

task read_correctness_reg;
/* verilator public */
    input integer k;
    output val;
    begin
        val = correctness_reg[k];
    end
endtask

task read_correctness_dmem;
/* verilator public */
    input integer k;
    output val;
    begin
        val = correctness_dmem[k];
    end
endtask

task read_reg;
/* verilator public */
    input integer k;
    output [31:0] val;
    begin
        val = core_top_inst.reg_file_inst.R[k];
    end
endtask

task read_golden_reg;
/* verilator public */
    input integer k;
    output [31:0] val;
    begin
        val = golden_reg[k];
    end
endtask

task read_dmem;
/* verilator public */
    input integer k;
    output [31:0] val;
    begin
        val = core_top_inst.dmem_inst.RAM[k];
    end
endtask

task read_golden_dmem;
/* verilator public */
    input integer k;
    output [31:0] val;
    begin
        val = golden_dmem[k];
    end
endtask

task check_pc;
/* verilator public */
    output val;
    begin
        val = core_top_inst.ex_pc != 0
            && core_top_inst.ex_pc == core_top_inst.ex_jpc
            && core_top_inst.ex_pc == core_top_inst.id_pc
            && core_top_inst.wb_pc == core_top_inst.ex_pc;
    end
endtask

endmodule
