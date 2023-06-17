module dmem (
    input           clk,
    input  [ 5 : 0] addr,  // byte address
    input           we,    // write-enable
    input  [31 : 0] wdata, // write data
    output [31 : 0] rdata, // read data
    output reg [31 : 0] rdata_byte  // read data
);

    reg [31 : 0] RAM [15 : 0];

    integer idx;

    initial begin
        for (idx = 0; idx < 16; idx = idx+1) RAM[idx] = 32'h0;
    end

    // Read operation
    assign rdata = RAM[addr[5:2]];

    wire [1:0] idx = addr[1:0];
    always @ (*) begin
        casez (idx)
            3: rdata_byte = rdata[31:24];
            2: rdata_byte = rdata[23:16];
            1: rdata_byte = rdata[15: 8];
            0: rdata_byte = rdata[ 7: 0];
        endcase
    end

    // Write operation
    always @(posedge clk) begin
        if (we) RAM[addr[5:2]] <= wdata;
    end

endmodule
