`include "defines.v"

// MEM/WB 流水线寄存器模块
module pipeline_reg_mem_wb(
    input wire clk,                         // 时钟信号
    input wire rst,                         // 复位信号
    // EX/MEM阶段传入的数据
    input wire [`ADDR_LEN-1:0] pc_mem,       // MEM阶段的PC值
    input wire [`DATA_LEN-1:0] alu_result_mem, // MEM阶段ALU结果
    input wire [`DATA_LEN-1:0] mem_read_data,  // 存储器读数据
    input wire [`REG_ADDR_LEN-1:0] write_reg_addr_mem, // MEM阶段写寄存器地址
    input wire mem_to_reg_flag_mem,          // MEM阶段存储器到寄存器选择
    input wire reg_write_flag_mem,           // MEM阶段寄存器写使能
    
    // 输出到WB阶段
    output reg [`ADDR_LEN-1:0] pc_wb,       // WB阶段的PC值
    output reg [`DATA_LEN-1:0] alu_result_wb, // WB阶段ALU结果
    output reg [`DATA_LEN-1:0] mem_read_data_wb, // WB阶段存储器读数据
    output reg [`REG_ADDR_LEN-1:0] write_reg_addr_wb, // WB阶段写寄存器地址
    output reg mem_to_reg_flag_wb,          // WB阶段存储器到寄存器选择
    output reg reg_write_flag_wb            // WB阶段寄存器写使能
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_wb <= 32'b0;
            alu_result_wb <= 32'b0;
            mem_read_data_wb <= 32'b0;
            write_reg_addr_wb <= 5'b0;
            mem_to_reg_flag_wb <= 1'b0;
            reg_write_flag_wb <= 1'b0;
        end
        else begin
            pc_wb <= pc_mem;
            alu_result_wb <= alu_result_mem;
            mem_read_data_wb <= mem_read_data;
            write_reg_addr_wb <= write_reg_addr_mem;
            mem_to_reg_flag_wb <= mem_to_reg_flag_mem;
            reg_write_flag_wb <= reg_write_flag_mem;
        end
    end

endmodule