`include "defines.v"

// 数据存储器模块
module data_memory(
    input wire clk,                         // 时钟信号
    input wire rst,                         // 复位信号，高电平有效
    input wire mem_read_flag,               // 存储器读使能信号
    input wire mem_write_flag,              // 存储器写使能信号
    input wire [`ADDR_LEN-1:0] addr,        // 存储器地址
    input wire [`DATA_LEN-1:0] write_data,  // 写入数据
    output reg [`DATA_LEN-1:0] read_data    // 读出数据
);
    
    // 数据存储器，大小为256个字
    reg [`DATA_LEN-1:0] data_mem [0:255];
    
    // 复位操作和写操作
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 256; i = i + 1) begin
                data_mem[i] <= 32'b0;
            end
        end
        else if (mem_write_flag) begin
            data_mem[addr[`ADDR_LEN-1:2]] <= write_data;
        end
    end
    
    // 读操作
    always @(*) begin
        if (mem_read_flag) begin
            read_data = data_mem[addr[`ADDR_LEN-1:2]];
        end
        else begin
            read_data = 32'b0;
        end
    end
    
endmodule
