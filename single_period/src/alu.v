`include "defines.v"

// ALU（算术逻辑单元）模块
module alu(
    input wire [`DATA_LEN-1:0] a,       // 第一个操作数
    input wire [`DATA_LEN-1:0] b,       // 第二个操作数
    input wire [`ALU_OPCODE] alu_op,    // ALU操作码
    output reg [`DATA_LEN-1:0] result,  // ALU运算结果
    output reg zero                     // 零标志位，当结果为0时置1
);
    
    always @(*) begin
        // 默认值
        result = 32'b0;
        zero = 1'b0;
        
        case (alu_op)
            `ALU_ADD: begin
                result = a + b;
            end
            
            `ALU_SUB: begin
                result = a - b;
            end
            
            `ALU_AND: begin
                result = a & b;
            end
            
            `ALU_OR: begin
                result = a | b;
            end
            
            `ALU_DEFAULT: begin
                result = 32'b0;
            end
        endcase
        
        // 设置零标志位
        zero = (result == 32'b0) ? 1'b1 : 1'b0;
    end
    
endmodule
