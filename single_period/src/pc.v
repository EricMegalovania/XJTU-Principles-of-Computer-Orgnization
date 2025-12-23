`include "defines.v"

// 程序计数器模块
module pc(
    input wire clk,           // 时钟信号
    input wire rst_n,         // 复位信号，低电平有效
    input wire [`ADDR_LEN-1:0] next_pc,  // 下一个PC值
    output reg [`ADDR_LEN-1:0] pc         // 当前PC值
);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 32'h00000000;  // 复位时PC初始化为0
        end else begin
            pc <= next_pc;       // 时钟上升沿更新PC
        end
    end
    
endmodule
