`include "defines.v"

// 控制单元模块 - 多周期实现
// 注意：在多周期CPU中，控制单元不再需要外部传入的opcode和funct
// 因为这些信息已经通过阶段寄存器在内部传递
module control_unit(
    input wire clk,                     // 时钟信号
    input wire rst,                     // 复位信号
    input wire zero,                    // ALU零标志
    output reg reg_dst_flag,            // 寄存器写地址选择信号
    output reg alu_src_flag,            // ALU源操作数选择信号
    output reg mem_to_reg_flag,         // 存储器到寄存器写回选择信号
    output reg reg_write_flag,          // 寄存器写使能信号
    output reg mem_read_flag,           // 存储器读使能信号
    output reg mem_write_flag,          // 存储器写使能信号
    output reg branch_flag,             // 分支控制信号
    output reg jump_flag,               // 跳转控制信号
    output reg pc_write_flag,           // PC写使能
    output reg ir_write_flag,           // 指令寄存器写使能
    output reg alu_out_write_flag,      // ALU输出寄存器写使能
    output reg mem_data_write_flag,     // 存储器数据寄存器写使能
    output reg reg_data_write_flag,     // 寄存器数据寄存器写使能
    output reg [`ALU_OPCODE] alu_op,    // ALU操作码
    output reg [`ALU_SRC_A] alu_src_a,  // ALU源操作数A选择
    output reg [`ALU_SRC_B] alu_src_b,  // ALU源操作数B选择
    output reg [`PC_SRC] pc_src         // PC源选择
);
    
    reg [3:0] current_state;  // 当前状态
    reg [3:0] next_state;     // 下一个状态
    
    // 状态寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= `STATE_IF;
        end else begin
            current_state <= next_state;
        end
    end
    
    // 状态转换逻辑 - 多周期CPU的状态转换是固定的流水线步骤
    always @(*) begin
        case (current_state)
            `STATE_IF: begin
                next_state = `STATE_ID; // 取指完成后进入译码
            end
            
            `STATE_ID: begin
                next_state = `STATE_EX; // 译码完成后进入执行
            end
            
            `STATE_EX: begin
                next_state = `STATE_MEM; // 执行完成后进入内存访问
            end
            
            `STATE_MEM: begin
                next_state = `STATE_WB; // 内存访问完成后进入写回
            end
            
            `STATE_WB: begin
                next_state = `STATE_IF; // 写回完成后回到取指，开始下一条指令
            end
            
            default: begin
                next_state = `STATE_IF;
            end
        endcase
    end
    
    // 控制信号生成 - 根据当前状态生成相应的控制信号
    always @(*) begin
        // 默认值
        reg_dst_flag        = 1'b0;
        alu_src_flag        = 1'b0;
        mem_to_reg_flag     = 1'b0;
        reg_write_flag      = 1'b0;
        mem_read_flag       = 1'b0;
        mem_write_flag      = 1'b0;
        branch_flag         = 1'b0;
        jump_flag           = 1'b0;
        pc_write_flag       = 1'b0;
        ir_write_flag       = 1'b0;
        alu_out_write_flag  = 1'b0;
        mem_data_write_flag = 1'b0;
        reg_data_write_flag = 1'b0;
        alu_op              = `ALU_DEFAULT;
        alu_src_a           = `ALU_SRC_A_PC;
        alu_src_b           = `ALU_SRC_B_FOUR;
        pc_src              = `PC_SRC_ALU;
        
        case (current_state)
            `STATE_IF: begin  // 取指状态
                // PC+4，更新PC
                pc_write_flag = 1'b1;  // 允许PC写入
                ir_write_flag = 1'b1;  // 允许指令寄存器写入
                alu_src_a     = `ALU_SRC_A_PC;  // ALU源A为PC
                alu_src_b     = `ALU_SRC_B_FOUR; // ALU源B为4
                alu_op        = `ALU_ADD;       // ALU执行加法
                pc_src        = `PC_SRC_ALU;     // PC更新为ALU结果
            end
            
            `STATE_ID: begin  // 译码状态
                // 从寄存器堆读取操作数，进行符号扩展
                reg_data_write_flag = 1'b1;  // 允许ID/EX寄存器写入
                alu_src_a           = `ALU_SRC_A_REG1; // ALU源A为寄存器1
                alu_src_b           = `ALU_SRC_B_REG2; // ALU源B为寄存器2
                alu_op              = `ALU_ADD;        // ALU默认加法
            end
            
            `STATE_EX: begin  // 执行状态
                // 执行ALU操作
                alu_out_write_flag = 1'b1;  // 允许EX/MEM寄存器写入
                reg_dst_flag       = 1'b1;  // 写寄存器地址选择rd
                alu_src_a          = `ALU_SRC_A_REG1; // ALU源A为寄存器1
                alu_src_b          = `ALU_SRC_B_REG2; // ALU源B为寄存器2
                alu_op             = `ALU_ADD;        // 默认加法操作
            end
            
            `STATE_MEM: begin  // 内存访问状态
                // 访问数据存储器
                mem_read_flag       = 1'b1;  // 允许读取内存
                mem_data_write_flag = 1'b1;  // 允许MEM/WB寄存器写入
            end
            
            `STATE_WB: begin  // 写回状态
                // 将结果写回寄存器堆
                reg_write_flag   = 1'b1;  // 允许寄存器写入
                mem_to_reg_flag  = 1'b0;  // 写回数据选择ALU结果
            end
        endcase
    end
    
endmodule
