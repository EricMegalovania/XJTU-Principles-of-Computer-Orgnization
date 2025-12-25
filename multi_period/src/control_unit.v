`include "defines.v"

// 控制单元模块
module control_unit(
    input wire clk,                   // 时钟信号
    input wire rst,                   // 复位信号
    input wire [`INSTR_LEN-1:0] inst, // 指令
    output reg reg_dst_flag,          // 寄存器写地址选择信号
    output reg alu_src_flag,          // ALU源操作数选择信号
    output reg mem_to_reg_flag,       // 存储器到寄存器写回选择信号
    output reg reg_write_flag,        // 寄存器写使能信号
    output reg mem_read_flag,         // 存储器读使能信号
    output reg mem_write_flag,        // 存储器写使能信号
    output reg branch_flag,           // 分支控制信号
    output reg jump_flag,             // 跳转控制信号
    output reg [`ALU_OPCODE] alu_op   // ALU操作码
);
    
    reg [`STATE_LEN-1:0] state;
    reg [`STATE_LEN-1:0] new_state;

    // 指令类型
    wire [5:0] opcode = inst[`OPCODE];
    wire [5:0] funct  = inst[`FUNCT];
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= `STATE_IF;
        end
        else begin
            state <= new_state;
        end
    end

    // 状态机逻辑
    control_state control_state_inst (
        .clk(clk),
        .rst(rst),
        .opcode(opcode),
        .state(state),
        .new_state(new_state)
    );
    
    // 控制信号生成逻辑
    control_unit control_unit_inst (
        .opcode(opcode),
        .funct(funct),
        .state(state),
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
