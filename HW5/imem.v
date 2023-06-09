module imem #(
    parameter SIZE = 16,
    parameter DWIDTH = 32
)(
    input  [DWIDTH-1 : 0] addr,  // byte address
    output [DWIDTH-1 : 0] rdata  // read data
);

    reg [DWIDTH-1 : 0] RAM [SIZE-1 : 0];

    integer idx;
    initial begin
        for (idx = 0; idx < SIZE; idx = idx+1) RAM[idx] = {(DWIDTH){ 1'h0 }};
    end

    assign rdata = RAM[addr[$clog2(SIZE)+1:2]];

endmodule
