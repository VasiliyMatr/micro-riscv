// Defines MICRO CPU hart

`include "defines.sv"

module HART
(
    input wire clk,
    input wire reset
);

// fetched instr code
wire [`DWORD_BITS - 1 : 0] instr_fetch;
reg  [`DWORD_BITS - 1 : 0] instr_dec;

/// rs1, rs2, rd

reg [4 : 0] rs1_dec, rs1_exe, rs2_dec, rs2_exe;

wire [`DWORD_BITS - 1 : 0] rs1_dec_val, rs2_dec_val;
reg  [`DWORD_BITS - 1 : 0] rs1_exe_val, rs2_exe_val;

reg [4 : 0] rd_dec, rd_exe, rd_mem, rd_wd;

/// Alu ins

wire [`ALU_OP_BITS - 1 : 0] alu_op_dec;
reg  [`ALU_OP_BITS - 1 : 0] alu_op_exe;

wire [`ALU_SRC1_BITS - 1 : 0] alu_src1_dec;
wire [`ALU_SRC2_BITS - 1 : 0] alu_src2_dec;

reg  [`ALU_SRC1_BITS - 1 : 0] alu_src1_exe;
reg  [`ALU_SRC2_BITS - 1 : 0] alu_src2_exe;

wire [`WORD_BITS - 1 : 0] imm_dec;
reg  [`WORD_BITS - 1 : 0] imm_exe;

/// Alu outs

wire [`DWORD_BITS - 1 : 0] alu_out_exe, alu_out_mem, alu_out_wb;
wire alu_zero_flag;

/// invalid/exception flags

reg invalid_dec = 0, invalid_exe = 0, invalid_mem = 0, invalid_wb = 0;
reg exception_dec = 0, exception_exe = 0, exception_mem = 0, exception_wb = 0;

/// Memory fields
wire [`FUNCT3_BITS - 1 : 0] funct3_dec;
reg  [`FUNCT3_BITS - 1 : 0] funct3_exe, funct3_mem;

/// Branch inv flag
wire branch_inv_cond_dec;
reg  branch_inv_cond_exe;

/// Hazard unit flags
wire mem_read_dec;
reg  mem_read_exe, mem_read_mem;

wire mem_write_dec;
reg  mem_write_exe, mem_write_mem;

wire reg_write_dec;
reg  reg_write_exe, reg_write_mem, reg_write_wb;

wire jump_dec;
reg  jump_exe;

wire flush_exe, stall_fetch, stall_decode;

wire took_branch_exe;

reg [`DWORD_BITS - 1 : 0] res_wb;

/// Stages enable flags
wire en_pc_wb, en_dec, en_exe, en_mem, en_wb;

/// Stages reset flags
wire reset_dec, reset_exe, reset_mem, reset_wb;

/// Setup stages control flags

assign en_dec = !stall_dec && !exception_wb;
assign reset_dec = reset || took_branch_exe;

assign en_exe = !exception_wb;
assign reset_exe = reset || flush_exe;

assign en_mem = !exception_wb;
assign reset_mem = reset;

assign en_wb = !exception_wb;
assign reset_wb = reset;

assign en_pc_wb = !stall_fetch && !exception_wb;

/// Pc update fields

wire [1 : 0] pc_mode_dec;
reg  [1 : 0] pc_mode_exe, next_pc_mode;

wire [`DWORD_BITS - 1 : 0] pc_fetch;
reg  [`DWORD_BITS - 1 : 0] pc_dec, pc_exe;

assign next_pc_mode = took_branch_exe ? pc_mode_exe : `PC_4;

/// Fetch stage

INSTR_MEMORY imem(.clk(clk), .pc(pc_fetch), .instr(instr_fetch));

PC_WB pc_wb(
    .clk(clk),
    .en(en_pc_wb),
    .pc_mode(next_pc_mode),
    .pc_new(pc_exe),
    .imm(imm_exe),
    .reg_val(rs1_fwd_val),
    .pc_fetch(pc_fetch)
);

/// Fetch -> Decode

always_ff @(posedge clk) begin
    if (reset_dec) begin
        pc_dec <= 0;
        instr_dec <= 0;
    end
    else if (en_dec) begin
        pc_dec <= pc_fetch;
        instr_dec <= instr_fetch;
    end
end

/// Decode stage

DECODER dec(
    .instr(instr_dec),

    .rs1(rs1_dec),
    .rs2(rs2_dec),
    .rd(rd_dec),

    .imm(imm_dec),
    .alu_op(alu_op_dec),
    .funct3(funct3_dec),

    .mem_read(mem_read_dec), .mem_write(mem_read_dec),
    .invalid_bit(invalid_dec), .exception_bit(exception_dec),
    .reg_write(reg_write_dec), .jump(jump_dec), .branch(branch_dec),
    .branch_inv_cond(branch_inv_cond_dec),

    .alu_src1_mode(alu_src1_dec),
    .alu_src2_mode(alu_src2_dec),

    .pc_mode(pc_mode_dec)
);

GPR_FILE gpr_file(
    .clk(clk),
    .we(reg_write_wb),

    .read1_id(rs1_dec),
    .read2_id(rs2_dec),
    .read1_val(rs1_dec_val),
    .read2_val(rs2_dec_val),

    .write_id(rd_dec),
    .write_val(res_wb)
);

/// Decode -> Execute

always_ff @(posedge clk) begin
    if (reset_exe) begin
        pc_exe <= pc_dec;

        rs1_exe <= rs1_dec;
        rs1_exe_val <= rs1_dec_val;
        rs2_exe <= rs2_dec;
        rs2_exe_val <= rs2_dec_val;
        rd_exe <= rd_dec;

        imm_exe <= imm_dec;

        alu_op_exe <= alu_op_dec;

        funct3_exe <= funct3_dec;
        mem_read_exe <= mem_read_dec;
        mem_write_exe <= mem_write_dec;
        reg_write_exe <= reg_write_dec;
        alu_src1_exe <= alu_src1_dec;
        alu_src1_exe <= alu_src2_dec;
        pc_mode_exe <= pc_mode_dec;
        branch_exe <= branch_dec;
        branch_inv_cond_exe <= branch_inv_cond_dec;
        jump_exe <= jump_dec;
        exception_exe <= exception_dec;
        invalid_exe <= invalid_dec;
    end
    else if (en_exe) begin
        pc_exe              <= 0;
        rs1_exe             <= 0;
        rs1_exe_val         <= 0;
        rs2_exe             <= 0;
        rs2_exe_val         <= 0;
        rd_exe              <= 0;
        imm_exe             <= 0;
        alu_op_exe          <= 0;
        funct3_exe          <= 0;
        mem_read_exe        <= 0;
        mem_write_exe       <= 0;
        reg_write_exe       <= 0;
        alu_src1_exe        <= 0;
        alu_src1_exe        <= 0;
        pc_mode_exe         <= 0;
        branch_exe          <= 0;
        branch_inv_cond_exe <= 0;
        jump_exe            <= 0;
        exception_exe       <= 0;
        invalid_exe         <= 0;
    end
end

/// Execute stage

wire [1 : 0] rs1_fwd_exe, rs2_fwd_exe;
wire [`DWORD_BITS - 1 : 0] rs1_fwd_val, rs2_fwd_val, alu_src1_exe_val, alu_src2_exe_val;

assign rs1_fwd_val =
    rs1_fwd_exe[1] == 1 ? alu_out_mem :
    rs1_fwd_exe[0] == 1 ? res_wb :
    rs1_exe_val;

assign rs2_fwd_val =
    rs2_fwd_exe[1] == 1 ? alu_out_mem :
    rs2_fwd_exe[0] == 1 ? res_wb :
    rs2_exe_val;

assign alu_src1_exe_val = alu_src1_exe == `ALU_SRC1_RS1 ? rs1_fwd_val : pc_exe;

wire imm_exe_sign = imm_exe[`WORD_BITS - 1];
wire [`DWORD_BITS - 1 : 0] imm_exe_ext = {{`WORD_BITS {imm_exe_sign}}, imm_exe};

assign alu_src2_exe_val =
    alu_src2_exe == `ALU_SRC2_RS2 ? rs2_fwd_val :
    alu_src2_exe == `ALU_SRC2_IMM ? imm_exe_ext :
    4;

ALU alu(
    .in1(alu_src1_exe_val),
    .in2(alu_src2_exe_val),

    .alu_op(alu_op_exe),
    .out(alu_out_exe),
    .zero_flag(alu_zero_flag)
);

assign took_branch_exe =
    (branch_exe && (alu_zero_flag ^ (~branch_inv_cond_exe))) | jump_exe;

/// Execute -> Memory

always_ff @(posedge clk) begin
    if (reset_mem) begin
        alu_out_mem <= alu_out_exe;
        mem_write_data <= rs2_fwd_val;
        funct3_mem <= funct3_exe;
        mem_read_mem <= mem_read_exe;
        mem_write_mem <= mem_write_exe;
        reg_write_mem <= reg_write_exe;
        rd_mem <= rd_exe;
        exception_mem <= exception_exe;
        invalid_mem <= invalid_exe;
    end
    else if (en_mem) begin
        alu_out_mem     <= 0;
        mem_write_data  <= 0;
        funct3_mem      <= 0;
        mem_read_mem    <= 0;
        mem_write_mem   <= 0;
        reg_write_mem   <= 0;
        rd_mem          <= 0;
        exception_mem   <= 0;
        invalid_mem     <= 0;
    end
end

/// Memory stage

wire [`DWORD_BITS - 1 : 0] mem_read_data;

DATA_MEMORY dmem(
    .clk(clk),
    .we(mem_write_mem),

    .access_addr(alu_out_mem),
    .funct3(funct3_mem),

    .store_data(mem_write_data),
    .load_data(mem_read_data)
);

/// Memory -> Write-back

wire [`DWORD_BITS - 1 : 0] mem_read_data_wb;

always_ff @(posedge clk) begin
    if (reset_wb) begin
        mem_read_data_wb <= mem_read_data;
        alu_out_wb <= alu_out_mem;
        reg_write_wb <= reg_write_mem;
        mem_read_wb <= mem_read_mem;
        rd_wb <= rd_mem;
        exception_wb <= exception_mem;
        invalid_wb <= invalid_mem;
    end
    else if (en_wb) begin
        mem_read_data_wb    <= 0;
        alu_out_wb          <= 0;
        reg_write_wb        <= 0;
        mem_read_wb         <= 0;
        rd_wb               <= 0;
        exception_wb        <= 0;
        invalid_wb          <= 0;
    end
end

/// Write-back stage

assign res_wb = mem_read_wb ? mem_read_data_wb : alu_out_wb;

HAZARD_UNIT hazard_unit(
    .reg_write_mem(reg_write_mem), .reg_write_wb(.reg_write_wb),
    .rs1_dec(rs1_dec), .rs2_dec(rs2_dec), .rd_exe(rd_exe),
    .rs1_exe(rs1_exe), .rs2_exe(rs2_exe), .rd_mem(rd_mem), .rd_wb(rd_wb),
    .mem_read_exe(mem_read_exe), .took_branch(took_branch_exe),

    .fwd_rs1_exe(fwd_rs1_exe), .fwd_rs2_exe(fwd_rs2_exe),
    .flush_exe(flush_exe), .stall_dec(stall_dec), .stall_fetch(stall_fetch)
);

endmodule
