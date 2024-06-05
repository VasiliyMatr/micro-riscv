`include "hart.sv"

`timescale 1ns / 10ps

module testbench();

reg clk = 0;
reg reset = 1;

always begin
    #1 clk = ~clk;
    #1 clk = ~clk;

    reset = 0;

    #1 clk = ~clk;
    #1 clk = ~clk;
    #1 clk = ~clk;
    #1 clk = ~clk;
    #1 clk = ~clk;
    #1 clk = ~clk;
    #1 clk = ~clk;
end

HART hart(.clk(clk), .reset(reset));

// test settings
initial begin

    $dumpvars;
    $display ("Testing hart...");
    #2000 $finish;

end

endmodule
