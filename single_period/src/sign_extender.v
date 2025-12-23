`include "defines.v"

module sign_extender(
    input wire [`IMM] imm,
    output wire [`DATA_LEN-1:0] ext_imm
);
    
    // imm[15] 为符号位, 进行有符号扩展
    assign ext_imm = {{16{imm[15]}}, imm};
    
endmodule
