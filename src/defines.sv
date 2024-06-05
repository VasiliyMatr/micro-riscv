// Contains common arch defines

// Data sizes
`define BYTE_BITS 8
`define HALF_BITS 16
`define WORD_BITS 32
`define DWORD_BITS 64

// RISCV arch have 32 GPRs
`define GPR_BITS `DWORD_BITS
`define GPR_ID_BITS 5
`define GPR_NUM (1 << `GPR_ID_BITS)

// Memory access type is encoded with 3 bits
`define FUNCT3_BITS 3

// ALU operations
`define ALU_INVALID 4'b0000
`define ALU_ADD     4'b0001
`define ALU_SUB     4'b0010
`define ALU_AND     4'b0011
`define ALU_OR      4'b0100
`define ALU_XOR     4'b0101
`define ALU_SHL     4'b0110
`define ALU_SHR     4'b0111
`define ALU_SHA     4'b1000
`define ALU_SLT     4'b1001
`define ALU_SLTU    4'b1010
`define ALU_SRC1    4'b1011
`define ALU_SRC2    4'b1100

`define ALU_OP_BITS 4

// Alu src1 switches
`define ALU_SRC1_RS1 1'b0
`define ALU_SRC1_PC  1'b1

`define ALU_SRC1_BITS 1

// Alu src2 switches
`define ALU_SRC2_RS2 2'b00
`define ALU_SRC2_IMM 2'b01
`define ALU_SRC2_PC  2'b10

`define ALU_SRC2_BITS 2

// Fwd switches
`define NO_FW   2'b00
`define FW_WB   2'b01
`define FW_MEM  2'b10

`define FW_MODE_BITS 2

// Pc wb switches
`define PC_4    2'b00
`define PC_IMM  2'b01
`define PC_REG  2'b10

`define PC_MODE_BITS 2
