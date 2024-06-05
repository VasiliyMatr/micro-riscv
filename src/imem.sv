// Defines data memory module

`include "defines.sv"

module INSTR_MEMORY
#(
    parameter ADDR_BITS = 10,
    parameter WORDS_NUM = 1 << (ADDR_BITS - 2)
)
(
    input wire [`DWORD_BITS - 1 : 0] pc,

    output wire [`WORD_BITS - 1 : 0] instr
);

    reg [`WORD_BITS - 1 : 0] memory [WORDS_NUM - 1 : 0];

    // get word id
    wire [ADDR_BITS - 3 : 0] word_id = pc [ADDR_BITS - 1 : 2];

    assign instr = memory[word_id];

    // read code from file
    initial begin
        $readmemh ("code.txt", memory);
    end

endmodule
