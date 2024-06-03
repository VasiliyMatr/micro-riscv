// Defines memory module

`include "defines.sv"

module MEMORY
#(
    parameter ADDR_BITS = 16;
)
(
    input wire clk,
    input wire we,

    input wire [`GPR_BITS - 1 : 0] access_addr,
    input wire [`FUNCT3_BITS - 1 : 0] funct3,

    input wire [`GPR_BITS - 1 : 0] store_data,
    output wire [`GPR_BITS - 1 : 0] load_data
);

    reg [`BYTE_BITS : 0] memory [(1 << ADDR_BITS) : 0];

    // Trunc input addr
    wire tr_addr [ADDR_BITS - 1 : 0] = access_addr [ADDR_BITS - 1 : 0];

    // Will do one aligned load
    wire al_addr [ADDR_BITS - 1 : 0];
    al_addr [ADDR_BITS - 1 : 3] = tr_addr [ADDR_BITS - 1 : 3];
    al_addr [2 : 0] = 0;

    // funct3 decoding:
    // 000 - LB/SB (8 bits with sign extend)
    // 001 - LH/SH (16 bits with sign extend)
    // 010 - LW/SW (32 bits with sign extend)
    // 011 - LD/SD (64 bits)
    // 100 - LBU (8 bits with zero extend)
    // 101 - LHU (16 bits with zero extend)
    // 110 - LWU (32 bits with zero extend)

    wire size = funct3 [1 : 0];
    wire ext = ~funct3 [2];

    /// Load

    wire [`DWORD_BITS - 1 : 0] load_raw = {
        memory[al_addr + 7], memory[al_addr + 6], memory[al_addr + 5], memory[al_addr + 4],
        memory[al_addr + 3], memory[al_addr + 2], memory[al_addr + 1], memory[al_addr]
    };

    wire [`DWORD_BITS : 0] lb_data = {
        {(`DWORD_BITS - `BYTE_BITS) {ext && load_raw[`BYTE_BITS - 1]}},
        load_raw[`BYTE_BITS - 1 : 0]
    };

    wire [`DWORD_BITS : 0] lh_data = {
        {(`DWORD_BITS - `HALF_BITS) {ext && load_raw[`HALF_BITS - 1]}},
        load_raw[`HALF_BITS - 1 : 0]
    };

    wire [`DWORD_BITS : 0] lw_data = {
        {(`DWORD_BITS - `WORD_BITS) {ext && load_raw[`WORD_BITS - 1]}},
        load_raw[`WORD_BITS - 1 : 0]
    };

    assign load_data =
        (size == 2'b00) ? lb_data :
        (size == 2'b01) ? lh_data :
        (size == 2'b10) ? lw_data :
        load_raw;

    /// Store

    always @(posedge clk) begin
        if (we) begin
            memory[tr_addr] <= store_data[7 : 0];

            if (size > 0) begin
                memory[tr_addr + 1] <= store_data[15 : 8];
            end

            if (size > 1) begin
                memory[tr_addr + 2] <= store_data[23 : 16];
                memory[tr_addr + 3] <= store_data[31 : 24];
            end

            if (size > 2) begin
                memory[tr_addr + 4] <= store_data[39 : 32];
                memory[tr_addr + 5] <= store_data[47 : 40];
                memory[tr_addr + 6] <= store_data[55 : 48];
                memory[tr_addr + 7] <= store_data[63 : 56];
            end
        end
    end

endmodule
