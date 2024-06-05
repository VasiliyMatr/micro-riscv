// Defines GPR file module

`include "defines.sv"

module GPR_FILE
(
    input wire clk,
    input wire we,

    // Read 2 GPRs at once
    input wire [`GPR_ID_BITS - 1 : 0] read1_id,
    input wire [`GPR_ID_BITS - 1 : 0] read2_id,
    output reg [`GPR_BITS - 1 : 0] read1_val,
    output reg [`GPR_BITS - 1 : 0] read2_val,

    // Write one GPR at once
    input wire [`GPR_ID_BITS - 1 : 0] write_id,
    input wire [`GPR_BITS - 1 : 0] write_val
);

    reg [`GPR_BITS - 1 : 0] gprs [`GPR_NUM - 1 : 0];

    assign read1_val = (read1_id == 0) ? `GPR_BITS'b0 : gprs[read1_id];
    assign read2_val = (read2_id == 0) ? `GPR_BITS'b0 : gprs[read2_id];

    always @(negedge clk) begin
        if (we)
            gprs[write_id] <= write_val;
    end

    integer i;
    initial begin
        for (i = 0; i != `GPR_NUM; i = i + 1) begin
            gprs[i] <= 0;
        end
        // set sp
        gprs[2] <= 64'h10000;
    end

endmodule
