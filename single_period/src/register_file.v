// 寄存器堆模块
// 32个32位寄存器，支持同时读取两个寄存器和写入一个寄存器

`include "defines.v"

module register_file (
    input  wire                     clk,      // 时钟信号
    input  wire                     rst,      // 复位信号
    input  wire                     we,       // 写使能信号
    input  wire [`REG_ADDR_LEN-1:0] w_addr,   // 写地址
    input  wire [`DATA_LEN-1:0]     w_data,   // 写数据
    input  wire [`REG_ADDR_LEN-1:0] r_addr1,  // 第一个读地址（rs）
    input  wire [`REG_ADDR_LEN-1:0] r_addr2,  // 第二个读地址（rt）
    output wire [`DATA_LEN-1:0]     r_data1,  // 第一个读数据
    output wire [`DATA_LEN-1:0]     r_data2   // 第二个读数据
);

    // 寄存器堆：32个32位寄存器
    reg [`DATA_LEN-1:0] regs [`REG_NUM-1:0];

    // 复位操作
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 复位时，所有寄存器清零
            for (i = 0; i < `REG_NUM; i = i + 1) begin
                regs[i] <= `DATA_LEN'h0;
            end
        end else if (we) begin
            // 写操作：时钟上升沿，写使能有效，且写地址不为0（$zero寄存器不可写）
            if (w_addr != 5'd0) begin
                regs[w_addr] <= w_data;
            end
        end
    end

    // 读操作：组合逻辑，读地址变化时立即输出
    // $zero寄存器始终输出0
    assign r_data1 = (r_addr1 == 5'd0) ? `DATA_LEN'h0 : regs[r_addr1];
    assign r_data2 = (r_addr2 == 5'd0) ? `DATA_LEN'h0 : regs[r_addr2];

endmodule
