`include "defines.v"

// EX/MEM 流水线寄存器模块
module pipeline_reg_ex_mem(
    input wire clk,                         // 时钟信号
    input wire rst,                         // 复位信号
    // ID/EX阶段传入的数据
    input wire [`ADDR_LEN-1:0] pc_ex,       // EX阶段的PC值
    input wire [`DATA_LEN-1:0] reg1_data_ex, // EX阶段寄存器1数据
    input wire [`DATA_LEN-1:0] reg2_data_ex, // EX阶段寄存器2数据
    input wire [`REG_ADDR_LEN-1:0] rs_addr_ex, // EX阶段rs地址
    input wire [`REG_ADDR_LEN-1:0] rt_addr_ex, // EX阶段rt地址
    input wire [`REG_ADDR_LEN-1:0] rd_addr_ex, // EX阶段rd地址
    input wire [`DATA_LEN-1:0] ext_imm_ex,     // EX阶段扩展立即数
    input wire reg_dst_flag_ex,               // EX阶段寄存器写地址选择
    input wire alu_src_flag_ex,               // EX阶段ALU源操作数选择
    input wire mem_to_reg_flag_ex,            // EX阶段存储器到寄存器选择
    input wire reg_write_flag_ex,             // EX阶段寄存器写使能
    input wire mem_read_flag_ex,              // EX阶段存储器读使能
    input wire mem_write_flag_ex,             // EX阶段存储器写使能
    input wire branch_flag_ex,                // EX阶段分支控制
    input wire jump_flag_ex,                  // EX阶段跳转控制
    input wire [`ALU_OPCODE] alu_op_ex,        // EX阶段ALU操作码
    // ALU结果
    input wire [`DATA_LEN-1:0] alu_result,   // ALU运算结果
    input wire zero,                         // ALU零标志位
    
    // 输出到MEM阶段
    output reg [`ADDR_LEN-1:0] pc_mem,       // MEM阶段的PC值
    output reg [`DATA_LEN-1:0] alu_result_mem, // MEM阶段ALU结果
    output reg zero_mem,                     // MEM阶段零标志位
    output reg [`DATA_LEN-1:0] reg2_data_mem, // MEM阶段寄存器2数据
    output reg [`REG_ADDR_LEN-1:0] write_reg_addr_mem, // MEM阶段写寄存器地址
    output reg mem_to_reg_flag_mem,          // MEM阶段存储器到寄存器选择
    output reg reg_write_flag_mem,           // MEM阶段寄存器写使能
    output reg mem_read_flag_mem,            // MEM阶段存储器读使能
    output reg mem_write_flag_mem,           // MEM阶段存储器写使能
    output reg branch_flag_mem,              // MEM阶段分支控制
    output reg jump_flag_mem                 // MEM阶段跳转控制
);

    // 写寄存器地址选择逻辑（在EX阶段完成）
    wire [`REG_ADDR_LEN-1:0] write_reg_addr;
    mux2 #(`REG_ADDR_LEN) reg_dst_mux(
        .sel(reg_dst_flag_ex),
        .in0(rt_addr_ex),
        .in1(rd_addr_ex),
        .out(write_reg_addr)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_mem <= 32'b0;
            alu_result_mem <= 32'b0;
            zero_mem <= 1'b0;
            reg2_data_mem <= 32'b0;
            write_reg_addr_mem <= 5'b0;
            mem_to_reg_flag_mem <= 1'b0;
            reg_write_flag_mem <= 1'b0;
            mem_read_flag_mem <= 1'b0;
            mem_write_flag_mem <= 1'b0;
            branch_flag_mem <= 1'b0;
            jump_flag_mem <= 1'b0;
        end
        else begin
            pc_mem <= pc_ex;
            alu_result_mem <= alu_result;
            zero_mem <= zero;
            reg2_data_mem <= reg2_data_ex;
            write_reg_addr_mem <= write_reg_addr;
            mem_to_reg_flag_mem <= mem_to_reg_flag_ex;
            reg_write_flag_mem <= reg_write_flag_ex;
            mem_read_flag_mem <= mem_read_flag_ex;
            mem_write_flag_mem <= mem_write_flag_ex;
            branch_flag_mem <= branch_flag_ex;
            jump_flag_mem <= jump_flag_ex;
        end
    end

endmodule