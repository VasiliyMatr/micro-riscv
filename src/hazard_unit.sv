// Defines hazard unit

`include "defines.sv"

module HAZARD_UNIT
(
    input wire reg_write_mem, reg_write_wb,
    input wire [4 : 0] rs1_dec, rs2_dec, rd_exe,
    input wire [4 : 0] rs1_exe, rs2_exe, rd_mem, rd_wb,
    input wire mem_read_exe, took_branch,

    output wire [`FW_MODE_BITS - 1 : 0] fwd_rs1_exe, fwd_rs2_exe,
    output wire flush_exe, stall_dec, stall_fetch
);

// Create stall if there is unresolvable data hazard
wire stall = mem_read_exe & ((rs1_dec == rd_exe) || (rs2_dec == rd_exe));

// Pass stall and flush flags
assign flush_exe = stall || took_branch;
assign stall_dec = stall;
assign stall_fetch = stall;

// Choose rs1 fwd mode
assign fwd_rs1_exe =
    rs1_exe == 0 ? `NO_FW :
    (reg_write_mem && (rd_mem == rs1_exe)) ? `FW_MEM :
    (reg_write_wb  && (rd_wb  == rs1_exe)) ? `FW_WB :
    `NO_FW;

// Choose rs2 fwd mode
assign fwd_rs2_exe =
    rs2_exe == 0 ? `NO_FW :
    (reg_write_mem && (rd_mem == rs2_exe)) ? `FW_MEM :
    (reg_write_wb  && (rd_wb  == rs2_exe)) ? `FW_WB :
    `NO_FW;

endmodule
