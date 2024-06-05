// Data memory test bench

`include "dmem.sv"

`timescale 1ns / 10ps

module testbench ();

reg clk = 0;
reg we = 1;

reg [`DWORD_BITS - 1 : 0] addr = 16'h1007;
reg [`FUNCT3_BITS - 1 : 0] funct3 = 0;

reg [`DWORD_BITS - 1 : 0] store_data = 64'h8899AABBCCDDEEFF;
wire [`DWORD_BITS - 1 : 0] load_data = 0;

always begin
    // SB
    funct3 = 3'b000;
    #1 clk = ~clk;
    #1 clk = ~clk;

    // SH
    funct3 = 3'b001;
    #1 clk = ~clk;
    #1 clk = ~clk;

    // SW
    funct3 = 3'b010;
    #1 clk = ~clk;
    #1 clk = ~clk;

    // SD
    funct3 = 3'b011;
    #1 clk = ~clk;
    #1 clk = ~clk;

    // LBU
    we = 0;
    funct3 = 3'b100;
    #1 clk = ~clk;
    #1 clk = ~clk;

    // LHU
    funct3 = 3'b101;
    #1 clk = ~clk;
    #1 clk = ~clk;

    // LWU
    funct3 = 3'b110;
    #1 clk = ~clk;
    #1 clk = ~clk;
end

DATA_MEMORY dmem(
    .clk(clk),
    .we(we),
    .access_addr(addr),
    .funct3(funct3),
    .store_data(store_data),
    .load_data(load_data)
);

// test settings
initial begin

    $dumpvars;
    $display ("Testing dmem...");
    #2000 $finish;

end

endmodule
