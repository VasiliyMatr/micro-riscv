// Defines GPR file module

`include "defines.sv"

module GPR_FILE
(
    input wire clk;
    input wire we;

    // Read 2 GPRs at once
    input wire [`GPR_ID_BITS - 1 : 0] read1_id;
    input wire [`GPR_ID_BITS - 1 : 0] read2_id;
    output reg [`GPR_BITS - 1 : 0] read1_val;
    output reg [`GPR_BITS - 1 : 0] read2_val;

    // Write one GPR at once
    input wire [`GPR_ID_BITS - 1 : 0] write_id;
    output reg [`GPR_BITS - 1 : 0] write_val;
);

    reg [`GPR_BITS - 1 : 0] gprs [`GPR_NUM - 1 : 0];

    assign read1_val = (read1_id == 0) ? 0 : gprs[read1_id];
    assign read2_val = (read2_id == 0) ? 0 : gprs[read2_id];

    always @(negedge clk) begin
        if (we)
            file[write_id] <= write_val;
    end

endmodule
