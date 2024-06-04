// Defines PC writeback module

`include "defines.sv"

module PC_WB
(
    input wire clk,
    input wire en,

    input wire [1 : 0] pc_mode,
    input wire [`DWORD_BITS - 1 : 0] pc_new,
    input wire [`WORD_BITS - 1 : 0] imm,
    input wire [`DWORD_BITS - 1 : 0] reg_val,

    output reg [`DWORD_BITS - 1 : 0] pc
);

wire [`DWORD_BITS - 1 : 0] src1;
wire [`DWORD_BITS - 1 : 0] src2;

wire imm_sign = imm[`WORD_BITS - 1];
wire [`DWORD_BITS - 1 : 0] imm_ext = {{`WORD_BITS {imm_sign}}, imm};

always_comb begin
    case (pc_mode)
        `PC_4: begin
            src1 = pc;
            src2 = 4;
        end

        `PC_IMM: begin
            src1 = pc_new;
            src2 = imm_ext;
        end

        `PC_REG: begin
            src1 = reg_val;
            src2 = imm_ext;
        end

        default: begin
            pc_src1 = 0;
            pc_src2 = 0;
        end
    endcase
end

always @(posedge clk) begin
    if (en)
        pc <= src1 + src2;
end

endmodule
