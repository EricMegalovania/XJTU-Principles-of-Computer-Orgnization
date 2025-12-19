// ALU运算模块
// 支持算术运算、逻辑运算、移位操作和比较操作

`include "defines.v"

module alu (
    input  wire [`DATA_LEN-1:0]     a,        // 第一个操作数
    input  wire [`DATA_LEN-1:0]     b,        // 第二个操作数
    input  wire [3:0]               alu_op,   // ALU操作类型
    input  wire [`REG_ADDR_LEN-1:0] shamt,    // 移位量（仅用于移位操作）
    output reg  [`DATA_LEN-1:0]     result,   // 运算结果
    output reg                      zero      // 结果是否为零（用于分支判断）
);

    always @(*) begin
        case (alu_op)
            `ALU_ADD: begin  // 加法
                result = a + b;
            end
            `ALU_SUB: begin  // 减法
                result = a - b;
            end
            `ALU_AND: begin  // 与
                result = a & b;
            end
            `ALU_OR: begin   // 或
                result = a | b;
            end
            `ALU_XOR: begin  // 异或
                result = a ^ b;
            end
            `ALU_SLL: begin  // 逻辑左移
                result = b << shamt;
            end
            `ALU_SRL: begin  // 逻辑右移
                result = b >> shamt;
            end
            `ALU_SRA: begin  // 算术右移
                result = $signed(b) >>> shamt;
            end
            `ALU_SLT: begin  // 带符号小于置1
                result = ($signed(a) < $signed(b)) ? `DATA_LEN'h1 : `DATA_LEN'h0;
            end
            `ALU_SLTU: begin // 无符号小于置1
                result = (a < b) ? `DATA_LEN'h1 : `DATA_LEN'h0;
            end
            `ALU_LW_SW: begin // lw/sw的地址计算（同加法）
                result = a + b;
            end
            default: begin
                result = `DATA_LEN'h0;
            end
        endcase

        // 计算zero标志位：结果为零则zero=1，否则zero=0
        zero = (result == `DATA_LEN'h0) ? 1'b1 : 1'b0;
    end

endmodule
