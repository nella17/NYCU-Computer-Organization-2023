module dmem #(
    parameter SIZE = 16,
    parameter DWIDTH = 32
)(
    input           clk,
    input  [DWIDTH-1 : 0] addr,  // byte address
    input                 we,    // write-enable
    input  [DWIDTH-1 : 0] wdata, // write data
    output [DWIDTH-1 : 0] rdata  // read data
);

    reg [DWIDTH-1 : 0] RAM [SIZE-1 : 0];

    integer idx;
    initial begin
        for (idx = 0; idx < SIZE; idx = idx+1) RAM[idx] = {(DWIDTH){ 1'h0 }};
    end

    // Read operation
    assign rdata = RAM[addr[$clog2(SIZE)+1:2]];

    // Write operation
    always @(posedge clk) begin
        if (we) RAM[addr[$clog2(SIZE)+1:2]] <= wdata;
    end

endmodule
