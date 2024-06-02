// Contains common arch defines

`define BYTE_BITS 8
`define HALF_BITS 16
`define WORD_BITS 32

`define GPR_BITS `WORD_BITS

`define GPR_ID_BITS 5
`define GPR_NUM (1 << `GPR_ID_BITS)
