// Defines memory module

`include "defines.sv"

module DATA_MEMORY
#(
    // Bus width in log scale
    parameter BUS_BYTES_LOG = 3,
    parameter BUS_BITS_LOG = BUS_BYTES_LOG + 3,
    // Bus width
    parameter BUS_BITS = 1 << BUS_BITS_LOG,
    parameter ADDR_BITS = 16,
    parameter NUM_BYTES = 1 << ADDR_BITS
)
(
    input wire clk,
    input wire we,

    input wire [BUS_BITS - 1 : 0] access_addr,
    input wire [`FUNCT3_BITS - 1 : 0] funct3,

    input wire [BUS_BITS - 1 : 0] store_data,
    output reg [BUS_BITS - 1 : 0] load_data
);

    reg [`BYTE_BITS - 1 : 0] memory [NUM_BYTES - 1 : 0];

    // Trunc input addr
    wire [ADDR_BITS - 1 : 0] addr = access_addr [ADDR_BITS - 1 : 0];

    /// Decode funct3

    // 000 - LB/SB (8 bits with sign extend)
    // 001 - LH/SH (16 bits with sign extend)
    // 010 - LW/SW (32 bits with sign extend)
    // 011 - LD/SD (64 bits)
    // 100 - LBU (8 bits with zero extend)
    // 101 - LHU (16 bits with zero extend)
    // 110 - LWU (32 bits with zero extend)

    wire [1 : 0] size = funct3 [1 : 0];
    wire ext = ~funct3 [2];

    /// Get data for all types of loads

    wire [`BYTE_BITS - 1 : 0] lb = memory[addr];
    wire lb_sign = ext && lb[`BYTE_BITS - 1];
    wire [BUS_BITS - 1 : 0] lb_ext = {{(BUS_BITS - `BYTE_BITS) {lb_sign}}, lb};

    wire [`HALF_BITS - 1 : 0] lh = { memory[addr + 1], memory[addr] };
    wire lh_sign = ext && lh[`HALF_BITS - 1];
    wire [BUS_BITS - 1 : 0] lh_ext = {{(BUS_BITS - `HALF_BITS) {lh_sign}}, lh};

    wire [`WORD_BITS - 1 : 0] lw = {
        memory[addr + 3], memory[addr + 2],
        memory[addr + 1], memory[addr]
    };
    wire lw_sign = ext && lw[`WORD_BITS - 1];
    wire [BUS_BITS - 1 : 0] lw_ext = {{(BUS_BITS - `WORD_BITS) {lw_sign}}, lw};

    wire [`DWORD_BITS - 1 : 0] ld = {
        memory[addr + 7], memory[addr + 6],
        memory[addr + 5], memory[addr + 4],
        memory[addr + 3], memory[addr + 2],
        memory[addr + 1], memory[addr]
    };

    always @(posedge clk) begin
        /// Load
        case (size)
            2'b00: load_data <= lb_ext;
            2'b01: load_data <= lh_ext;
            2'b10: load_data <= lw_ext;
            2'b11: load_data <= ld;
        endcase

        /// Store
        if (we) begin
            memory[addr] <= store_data[7 : 0];

            if (size > 0) begin
                memory[addr + 1] <= store_data[15 : 8];
            end

            if (size > 1) begin
                memory[addr + 2] <= store_data[23 : 16];
                memory[addr + 3] <= store_data[31 : 24];
            end

            if (size > 2) begin
                memory[addr + 4] <= store_data[39 : 32];
                memory[addr + 5] <= store_data[47 : 40];
                memory[addr + 6] <= store_data[55 : 48];
                memory[addr + 7] <= store_data[63 : 56];
            end
        end
    end

    integer i;
    initial begin
        for (i = 0; i != NUM_BYTES; i = i + 1) begin
            memory[i] <= 8'hFF;
        end
    end

endmodule
