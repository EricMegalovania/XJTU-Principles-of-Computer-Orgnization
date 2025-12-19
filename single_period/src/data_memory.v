// 数据存储器模块
// 可读可写，32位宽，按字寻址

`include "defines.v"

module data_memory (
    input  wire                     clk,      // 时钟信号
    input  wire                     rst,      // 复位信号
    input  wire                     we,       // 写使能信号
    input  wire [`ADDR_LEN-1:0]     addr,     // 数据地址
    input  wire [`DATA_LEN-1:0]     w_data,   // 写数据
    output wire [`DATA_LEN-1:0]     r_data    // 读数据
);

    // 数据存储器大小：1024个字（4KB）
    parameter DMEM_SIZE = 1024;

    // 数据存储器：DMEM_SIZE个32位数据
    reg [`DATA_LEN-1:0] dmem [DMEM_SIZE-1:0];

    // 复位操作
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 复位时，所有数据清零
            for (i = 0; i < DMEM_SIZE; i = i + 1) begin
                dmem[i] <= `DATA_LEN'h0;
            end
        end else if (we) begin
            // 写操作：时钟上升沿，写使能有效
            // 地址右移2位，将字节地址转换为字地址
            dmem[addr[31:2]] <= w_data;
        end
    end

    // 读操作：组合逻辑，地址变化时立即输出
    // 地址右移2位，将字节地址转换为字地址
    assign r_data = dmem[addr[31:2]];

endmodule
