`include "defines.v"

// ALU（算术逻辑单元）模块
module alu(
    input wire [`DATA_LEN-1:0] a,       // 第一个操作数
    input wire [`DATA_LEN-1:0] b,       // 第二个操作数
    input wire [`3:0] alu_op,           // ALU操作码
    output reg [`DATA_LEN-1:0] result,  // ALU运算结果
    output reg zero                     // 零标志位，当结果为0时置1
);
    
    always @(*) begin
        // 默认值
        result = 32'h00000000;
        zero = 1'b0;
        
        case (alu_op)
            4'b0000: begin  // AND操作
                result = a & b;
            end
            
            4'b0001: begin  // OR操作
                result = a | b;
            end
            
            4'b0010: begin  // 加法操作
                result = a + b;
            end
            
            4'b0110: begin  // 减法操作
                result = a - b;
            end
            
            4'b0111: begin  // 小于则置1
                result = (a < b) ? 32'h00000001 : 32'h00000000;
            end
            
            default: begin
                result = 32'h00000000;
            end
        endcase
        
        // 设置零标志位
        zero = (result == 32'h00000000) ? 1'b1 : 1'b0;
    end
    
endmodule
