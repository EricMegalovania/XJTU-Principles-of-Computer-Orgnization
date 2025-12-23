`include "defines.v"

module register_file(
    input wire clk,                         // 时钟信号
    input wire rst,                         // 复位信号, 低电平有效
    input wire we,                          // 写使能信号
    input wire [`REG_ADDR_LEN-1:0] raddr1,  // 第一个读地址
    input wire [`REG_ADDR_LEN-1:0] raddr2,  // 第二个读地址
    input wire [`REG_ADDR_LEN-1:0] waddr,   // 写地址
    input wire [`DATA_LEN-1:0] wdata,       // 写数据
    output reg [`DATA_LEN-1:0] rdata1,      // 第一个读数据
    output reg [`DATA_LEN-1:0] rdata2       // 第二个读数据
);
    
    // 定义32个32位寄存器
    reg [`DATA_LEN-1:0] regs [`REG_NUM-1:0];
    
    // 复位操作
    integer i;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            // 复位时清0
            for (i = 0; i < `REG_NUM; i = i + 1) begin
                regs[i] <= 32'b0;
            end
        end
        else if (we) begin
            // 写操作, 注意regs[0]始终为0
            if (waddr != 5'b0) begin
                regs[waddr] <= wdata;
            end
        end
    end
    
    // 读操作，异步读取
    always @(*) begin
        rdata1 = regs[raddr1];
    end
    
    always @(*) begin
        rdata2 = regs[raddr2];
    end
    
endmodule
