`include "defines.v"

// 控制单元模块
module control_unit(
    input wire clk,                     // 时钟信号
    input wire rst,                     // 复位信号
    input wire [`OPCODE] opcode,        // 指令的opcode字段
    input wire [`FUNCT] funct,          // 指令的funct字段
    input wire [`STATE_LEN-1:0] state,  // 当前指令
    output wire reg_dst_flag,           // 寄存器写地址选择信号
    output wire alu_src_flag,           // ALU源操作数选择信号
    output wire mem_to_reg_flag,        // 存储器到寄存器写回选择信号
    output wire reg_write_flag,         // 寄存器写使能信号
    output wire mem_read_flag,          // 存储器读使能信号
    output wire mem_write_flag,         // 存储器写使能信号
    output wire branch_flag,            // 分支控制信号
    output wire jump_flag,              // 跳转控制信号
    output wire [`ALU_OPCODE] alu_op,   // ALU操作码
    output wire [`STATE_LEN-1:0] new_state,
    output wire state_pc,             // 下个状态是否为 IF
    output wire state_regfile_read,   // 下个状态是否为 ID
    output wire state_regfile_write,  // 下个状态是否为 WB
    output wire state_memory          // 下个状态是否为 MEM
);

    // 状态机逻辑
    control_state control_state_inst ( 
        .rst(rst),
        .opcode(opcode),
        .state(state),
        .new_state(new_state),
        .state_pc(state_pc),
        .state_regfile_read(state_regfile_read),
        .state_regfile_write(state_regfile_write),
        .state_memory(state_memory)
    );
    
    // 控制信号生成逻辑
    control_sign control_sign_inst (
        .opcode(opcode),
        .funct(funct),
        .reg_dst_flag(reg_dst_flag),
        .alu_src_flag(alu_src_flag),
        .mem_to_reg_flag(mem_to_reg_flag),
        .reg_write_flag(reg_write_flag),
        .mem_read_flag(mem_read_flag),
        .mem_write_flag(mem_write_flag),
        .branch_flag(branch_flag),
        .jump_flag(jump_flag),
        .alu_op(alu_op)
    );
    
endmodule
