`include "defines.v"

// ID/EX 流水线寄存器模块
module pipeline_reg_id_ex(
    input wire clk,                         // 时钟信号
    input wire rst,                         // 复位信号
    input wire stall,                       // 暂停信号
    // PC和指令信息
    input wire [`ADDR_LEN-1:0] pc_id,       // ID阶段的PC值
    input wire [`INSTR_LEN-1:0] inst_id,    // ID阶段的指令
    // 寄存器堆数据
    input wire [`DATA_LEN-1:0] reg1_data,   // 寄存器1数据
    input wire [`DATA_LEN-1:0] reg2_data,   // 寄存器2数据
    input wire [`REG_ADDR_LEN-1:0] rs_addr, // rs寄存器地址
    input wire [`REG_ADDR_LEN-1:0] rt_addr, // rt寄存器地址
    input wire [`REG_ADDR_LEN-1:0] rd_addr, // rd寄存器地址
    // 扩展立即数
    input wire [`DATA_LEN-1:0] ext_imm,     // 符号扩展立即数
    // 控制信号
    input wire reg_dst_flag,                // 寄存器写地址选择
    input wire alu_src_flag,                // ALU源操作数选择
    input wire mem_to_reg_flag,             // 存储器到寄存器选择
    input wire reg_write_flag,              // 寄存器写使能
    input wire mem_read_flag,               // 存储器读使能
    input wire mem_write_flag,              // 存储器写使能
    input wire branch_flag,                 // 分支控制
    input wire jump_flag,                   // 跳转控制
    input wire [`ALU_OPCODE] alu_op,        // ALU操作码
    
    // 输出到EX阶段
    output reg [`ADDR_LEN-1:0] pc_ex,       // EX阶段的PC值
    output reg [`INSTR_LEN-1:0] inst_ex,    // EX阶段的指令
    output reg [`DATA_LEN-1:0] reg1_data_ex, // EX阶段寄存器1数据
    output reg [`DATA_LEN-1:0] reg2_data_ex, // EX阶段寄存器2数据
    output reg [`REG_ADDR_LEN-1:0] rs_addr_ex, // EX阶段rs地址
    output reg [`REG_ADDR_LEN-1:0] rt_addr_ex, // EX阶段rt地址
    output reg [`REG_ADDR_LEN-1:0] rd_addr_ex, // EX阶段rd地址
    output reg [`DATA_LEN-1:0] ext_imm_ex,     // EX阶段扩展立即数
    output reg reg_dst_flag_ex,               // EX阶段寄存器写地址选择
    output reg alu_src_flag_ex,               // EX阶段ALU源操作数选择
    output reg mem_to_reg_flag_ex,            // EX阶段存储器到寄存器选择
    output reg reg_write_flag_ex,             // EX阶段寄存器写使能
    output reg mem_read_flag_ex,              // EX阶段存储器读使能
    output reg mem_write_flag_ex,             // EX阶段存储器写使能
    output reg branch_flag_ex,                // EX阶段分支控制
    output reg jump_flag_ex,                  // EX阶段跳转控制
    output reg [`ALU_OPCODE] alu_op_ex        // EX阶段ALU操作码
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_ex <= 32'b0;
            inst_ex <= 32'b0;
            reg1_data_ex <= 32'b0;
            reg2_data_ex <= 32'b0;
            rs_addr_ex <= 5'b0;
            rt_addr_ex <= 5'b0;
            rd_addr_ex <= 5'b0;
            ext_imm_ex <= 32'b0;
            reg_dst_flag_ex <= 1'b0;
            alu_src_flag_ex <= 1'b0;
            mem_to_reg_flag_ex <= 1'b0;
            reg_write_flag_ex <= 1'b0;
            mem_read_flag_ex <= 1'b0;
            mem_write_flag_ex <= 1'b0;
            branch_flag_ex <= 1'b0;
            jump_flag_ex <= 1'b0;
            alu_op_ex <= `ALU_DEFAULT;
        end
        else if (stall) begin
            // 暂停时保持不变
            pc_ex <= pc_ex;
            inst_ex <= inst_ex;
            reg1_data_ex <= reg1_data_ex;
            reg2_data_ex <= reg2_data_ex;
            rs_addr_ex <= rs_addr_ex;
            rt_addr_ex <= rt_addr_ex;
            rd_addr_ex <= rd_addr_ex;
            ext_imm_ex <= ext_imm_ex;
            reg_dst_flag_ex <= reg_dst_flag_ex;
            alu_src_flag_ex <= alu_src_flag_ex;
            mem_to_reg_flag_ex <= mem_to_reg_flag_ex;
            reg_write_flag_ex <= 1'b0;        // 暂停时清除写使能
            mem_read_flag_ex <= mem_read_flag_ex;
            mem_write_flag_ex <= mem_write_flag_ex;
            branch_flag_ex <= branch_flag_ex;
            jump_flag_ex <= jump_flag_ex;
            alu_op_ex <= alu_op_ex;
        end
        else begin
            pc_ex <= pc_id;
            inst_ex <= inst_id;
            reg1_data_ex <= reg1_data;
            reg2_data_ex <= reg2_data;
            rs_addr_ex <= rs_addr;
            rt_addr_ex <= rt_addr;
            rd_addr_ex <= rd_addr;
            ext_imm_ex <= ext_imm;
            reg_dst_flag_ex <= reg_dst_flag;
            alu_src_flag_ex <= alu_src_flag;
            mem_to_reg_flag_ex <= mem_to_reg_flag;
            reg_write_flag_ex <= reg_write_flag;
            mem_read_flag_ex <= mem_read_flag;
            mem_write_flag_ex <= mem_write_flag;
            branch_flag_ex <= branch_flag;
            jump_flag_ex <= jump_flag;
            alu_op_ex <= alu_op;
        end
    end

endmodule