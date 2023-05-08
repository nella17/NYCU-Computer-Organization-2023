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

    reg [31:0] golden_reg[0:31]/* verilator public */;
    reg [31:0] golden_dmem[0:15]/* verilator public */;

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

task writereg;
/* verilator public */
    input integer byte_addr;
    input [31:0] val;
    begin
        golden_reg[byte_addr] = val;
    end
endtask

task writedmem;
/* verilator public */
    input integer byte_addr;
    input [31:0] val;
    begin
        golden_dmem[byte_addr] = val;
    end
endtask

endmodule