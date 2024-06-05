// Defines ALU module

`include "defines.sv"

module ALU
#(
    parameter OP_SIZE = `DWORD_BITS
)
(
    input wire [OP_SIZE - 1 : 0] in1, in2,
    input wire [`ALU_OP_BITS - 1 : 0] alu_op,

    output logic [OP_SIZE - 1 : 0] out,
    output logic zero_flag
);

assign zero_flag = (out === 0);
wire [4 : 0] shamt = in2[4 : 0];

wire less = $signed(in1) < $signed(in2);
wire less_u = in1 < in2;

always_comb begin
    case (alu_op)
        `ALU_ADD:  out = in1 + in2;
        `ALU_SUB:  out = in1 - in2;
        `ALU_AND:  out = in1 & in2;
        `ALU_OR:   out = in1 | in2;
        `ALU_XOR:  out = in1 ^ in2;
        `ALU_SHL:  out = in1 << shamt;
        `ALU_SHR:  out = in1 >> shamt;
        `ALU_SHA:  out = $signed(in1) >>> $signed(shamt);
        `ALU_SLT:  out = less;
        `ALU_SLTU: out = less_u;
        `ALU_SRC1: out = in1;
        `ALU_SRC2: out = in2;
        default:   out = 0;
    endcase
end

endmodule
