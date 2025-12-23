`include "defines.v"

// 立即数符号扩展模块
module sign_extender(
    input wire [`IMM] imm,       // 16位立即数
    output wire [`DATA_LEN-1:0] ext_imm  // 32位扩展后的立即数
);
    
    // 符号扩展：将16位立即数扩展为32位
    assign ext_imm = {{16{imm[15]}}, imm};  // 最高位符号位扩展
    
endmodule
