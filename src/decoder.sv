// Defines instr decoder

`include "defines.sv"

// RV64I opcodes
`define LUI        7'b0110111
`define AUIPC      7'b0010111
`define JAL        7'b1101111
`define JALR       7'b1100111
`define BRANCH_OP  7'b1100011
`define LOAD_OP    7'b0000011
`define STORE_OP   7'b0100011
`define REG_IMM_OP 7'b0010011
`define REG_REG_OP 7'b0110011
`define SYS_CALL   7'b1110011

module DECODER
(
    input wire [`WORD_BITS - 1 : 0] instr,

    output wire [4 : 0] rs1,
    output wire [4 : 0] rs2,
    output wire [4 : 0] rd,

    output logic [`WORD_BITS - 1 : 0] imm,
    output logic [`ALU_OP_BITS - 1 : 0] alu_op,
    output logic [2 : 0] funct3,

    // Flags
    output logic mem_read, mem_write,
    output logic invalid_bit, exception_bit,
    output logic reg_write, jump, branch, branch_inv_cond,

    // Alu src1 switch
    output logic [`ALU_SRC1_BITS - 1 : 0] alu_src1_mode,

    // Alu src2 switch
    output logic [`ALU_SRC2_BITS - 1 : 0] alu_src2_mode,

    // Pc switch
    output logic [`PC_MODE_BITS - 1 : 0] pc_mode
);

wire [6 : 0] opcode = instr[6 : 0];

assign rs1 = instr[19 : 15];
assign rs2 = instr[24 : 20];
assign rd = instr[11 : 7];

assign funct3 = instr[14 : 12];
wire [6 : 0] funct7 = instr[31 : 25];

/// Prepare immediates

wire [`WORD_BITS - 1 : 0] imm_i, imm_s, imm_b, imm_u, imm_j, shamt;

assign imm_i = { {20 {instr[31]}}, instr[31 : 20] };

assign imm_s = { {20 {instr[31]}}, instr[31 : 25], instr[11 : 7] };

assign imm_b = { {20 {instr[31]}}, instr[7],
    instr[30 : 25], instr[11 : 8], 1'b0 };

assign imm_u = { instr[31 : 12], {12 {1'b0}} };

assign imm_j = { {12 {instr[31]}}, instr[19 : 12],
    instr[20], instr[30 : 21], 1'b0 };

assign shamt = { {27 {1'b0}}, instr[24 : 20] };

/// Choose immediate by opcode
assign imm =
    (opcode == `LUI)        ? imm_u :
    (opcode == `AUIPC)      ? imm_u :
    (opcode == `JAL)        ? imm_j :
    (opcode == `JALR)       ? imm_i :
    (opcode == `BRANCH_OP)  ? imm_b :
    (opcode == `LOAD_OP)    ? imm_i :
    (opcode == `STORE_OP)   ? imm_s :
    (opcode == `REG_IMM_OP && funct3 == 3'b001) ? shamt : // SLLI
    (opcode == `REG_IMM_OP && funct3 == 3'b101) ? shamt : // SRLI, SRAI
    (opcode == `REG_IMM_OP) ? imm_i :
    0;

always_comb begin

/// Set default values

invalid_bit = 0;
exception_bit = 0;

alu_op = `ALU_INVALID;
alu_src1_mode = `ALU_SRC1_RS1;
alu_src2_mode = `ALU_SRC2_RS2;

mem_read = 0;
mem_write = 0;
reg_write = 0;

jump = 0;
branch = 0;
pc_mode = `PC_4;
branch_inv_cond = 0;

case(opcode)
    `LUI: begin
        alu_op = `ALU_SRC2;
        alu_src1_mode = `ALU_SRC1_RS1;
        alu_src2_mode = `ALU_SRC2_IMM;

        reg_write = 1;
    end

    `AUIPC: begin
        alu_op = `ALU_ADD;
        alu_src1_mode = `ALU_SRC1_PC;
        alu_src2_mode = `ALU_SRC2_IMM;

        reg_write = 1;
    end

    `JAL: begin
        alu_op = `ALU_INVALID;

        reg_write = 1;

        jump = 1;
        pc_mode = `PC_IMM;
    end

    `JALR: begin
        alu_op = `ALU_INVALID;

        reg_write = 1;

        jump = 1;
        pc_mode = `PC_REG;
    end

    `BRANCH_OP: begin
        alu_src1_mode = `ALU_SRC1_RS1;
        alu_src2_mode = `ALU_SRC2_RS2;

        branch = 1;
        pc_mode = `PC_IMM;

        case (funct3)
            // beq
            3'b000: alu_op = `ALU_SUB;
            // bne
            3'b001: begin
                alu_op = `ALU_SUB;
                branch_inv_cond = 1;
            end

            // blt
            3'b100: alu_op = `ALU_SLT;
            // bge
            3'b101: begin
                alu_op = `ALU_SLT;
                branch_inv_cond = 1;
            end

            // bltu
            3'b110: alu_op = `ALU_SLTU;
            // bgeu
            3'b111: begin
                alu_op = `ALU_SLTU;
                branch_inv_cond = 1;
            end

            // invalid instr
            default: begin
                alu_op = `ALU_INVALID;
                invalid_bit = 1;
            end
        endcase
    end

    `LOAD_OP: begin
        alu_op = `ALU_ADD;
        alu_src1_mode = `ALU_SRC1_RS1;
        alu_src2_mode = `ALU_SRC2_IMM;

        mem_read = 1;
        reg_write = 1;
    end

    `STORE_OP: begin
        alu_op = `ALU_ADD;
        alu_src1_mode = `ALU_SRC1_RS1;
        alu_src2_mode = `ALU_SRC2_IMM;

        mem_write = 1;
    end

    `REG_IMM_OP: begin
        alu_src1_mode = `ALU_SRC1_RS1;
        alu_src2_mode = `ALU_SRC2_IMM;

        reg_write = 1;

        case (funct3)
            // addi
            3'b000: alu_op = `ALU_ADD;
            // slli
            3'b001: alu_op = `ALU_SHL;
            // slti
            3'b010: alu_op = `ALU_SLT;
            // sltiu
            3'b011: alu_op = `ALU_SLTU;
            // xori
            3'b100: alu_op = `ALU_XOR;
            // ori
            3'b110: alu_op = `ALU_OR;
            // andi
            3'b111: alu_op = `ALU_AND;

            // srli, srai
            3'b101: alu_op = (funct7 == 0 ? `ALU_SHR : `ALU_SHA);

            // invalid instr
            default: begin
                alu_op = `ALU_INVALID;
                invalid_bit = 1;
            end
        endcase
    end

    `REG_REG_OP: begin
        alu_src1_mode = `ALU_SRC1_RS1;
        alu_src2_mode = `ALU_SRC2_RS2;

        reg_write = 1;

        case (funct3)
            3'b111: alu_op = `ALU_AND;
            3'b110: alu_op = `ALU_OR;
            3'b100: alu_op = `ALU_XOR;
            3'b001: alu_op = `ALU_SHL;
            3'b010: alu_op = `ALU_SLT;
            3'b011: alu_op = `ALU_SLTU;

            3'b000: alu_op = (funct7 == 0 ? `ALU_ADD : `ALU_SUB);
            3'b101: alu_op = (funct7 == 0 ? `ALU_SHR : `ALU_SHA);

            // invalid instr
            default: begin
                alu_op = `ALU_INVALID;
                invalid_bit = 1;
            end
        endcase
    end

    `SYS_CALL: begin
        exception_bit = 1;
    end

    default: begin
        invalid_bit = 1;
    end
endcase
end

endmodule
