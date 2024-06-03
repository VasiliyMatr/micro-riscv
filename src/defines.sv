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
