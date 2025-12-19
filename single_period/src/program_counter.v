// 程序计数器模块
// 存储当前指令地址，并根据控制信号更新下一条指令地址

`include "defines.v"

module program_counter (
    input  wire                     clk,      // 时钟信号
    input  wire                     rst,      // 复位信号
    input  wire                     branch,   // 分支信号
    input  wire                     jump,     // 跳转信号
    input  wire                     zero,     // ALU运算结果是否为零
    input  wire [`ADDR_LEN-1:0]     imm_ext,  // 扩展后的立即数（用于分支）
    input  wire [`J_ADDR]           j_addr,   // 跳转地址（用于J型指令）
    output reg  [`ADDR_LEN-1:0]     pc        // 程序计数器输出
);

    // 下一条指令地址
    reg [`ADDR_LEN-1:0] pc_next;

    always @(*) begin
        if (rst) begin
            // 复位时，PC初始化为0
            pc_next = `ADDR_LEN'h0;
        end else if (jump) begin
            // 跳转指令：PC = (PC + 4)的高4位 | (j_addr << 2)
            pc_next = {pc[31:28], j_addr, 2'b00};
        end else if (branch && zero) begin
            // 分支指令且条件满足：PC = PC + 4 + (imm_ext << 2)
            pc_next = pc + 4 + (imm_ext << 2);
        end else begin
            // 正常顺序执行：PC = PC + 4
            pc_next = pc + 4;
        end
    end

    // 时钟上升沿更新PC
    always @(posedge clk) begin
        pc <= pc_next;
    end

endmodule
