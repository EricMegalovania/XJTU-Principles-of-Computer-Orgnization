`include "defines.v"

// 控制单元模块
module control_unit(
    input wire clk,                  // 时钟信号
    input wire rst,                  // 复位信号
    input wire [`INSTR_LEN-1:0] inst, // 指令
    input wire zero,                 // ALU零标志位
    
    // 输出控制信号
    output reg reg_dst_flag,         // 寄存器目标选择
    output reg alu_src_flag,         // ALU源选择
    output reg mem_to_reg_flag,      // 存储器到寄存器
    output reg reg_write_flag,       // 寄存器写使能
    output reg mem_read_flag,        // 存储器读使能
    output reg mem_write_flag,       // 存储器写使能
    output reg branch_flag,          // 分支标志
    output reg jump_flag,            // 跳转标志
    output reg [`ALU_OPCODE] alu_op, // ALU操作码
    
    // 输出状态
    output reg [2:0] state           // 当前状态
);
    
    // 状态定义
    localparam IF = 3'b000;  // 取指阶段
    localparam ID = 3'b001;  // 译码阶段
    localparam EX = 3'b010;  // 执行阶段
    localparam MEM = 3'b011; // 访存阶段
    localparam WB = 3'b100;  // 写回阶段
    
    // 指令类型
    wire [5:0] opcode = inst[`OPCODE];
    wire [5:0] funct = inst[`FUNCT];
    
    // 状态机逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IF;
        end
        else begin
            case (state)
                IF:  state <= ID;
                ID:  state <= EX;
                EX:  begin
                    // 根据指令类型决定是否进入MEM阶段
                    if (opcode == `OP_LW || opcode == `OP_SW) begin
                        state <= MEM;
                    end
                    // R型指令和I型运算指令直接进入WB阶段
                    else if (opcode == `OP_R_TYPE || opcode == `OP_ADDI || opcode == `OP_ORI) begin
                        state <= WB;
                    end
                    // beq和j指令完成后直接回到IF阶段
                    else begin
                        state <= IF;
                    end
                end
                MEM: begin
                    // LW指令需要进入WB阶段
                    if (opcode == `OP_LW) begin
                        state <= WB;
                    end
                    // SW指令完成后直接回到IF阶段
                    else begin
                        state <= IF;
                    end
                end
                WB:  state <= IF;
                default: state <= IF;
            endcase
        end
    end
    
    // 控制信号生成逻辑
    always @(*) begin
        // 默认值
        reg_dst_flag = 1'b0;
        alu_src_flag = 1'b0;
        mem_to_reg_flag = 1'b0;
        reg_write_flag = 1'b0;
        mem_read_flag = 1'b0;
        mem_write_flag = 1'b0;
        branch_flag = 1'b0;
        jump_flag = 1'b0;
        alu_op = `ALU_DEFAULT;
        
        case (state)
            IF: begin
                // 取指阶段不需要控制信号
            end
            
            ID: begin
                // 译码阶段，根据指令类型生成部分控制信号
                case (opcode)
                    `OP_R_TYPE: begin
                        // R型指令
                        reg_dst_flag = 1'b1; // 写入rd
                        alu_src_flag = 1'b0; // ALU源为寄存器
                        
                        // 根据funct字段设置ALU操作码
                        case (funct)
                            `FUNCT_ADD: alu_op = `ALU_ADD;
                            `FUNCT_SUB: alu_op = `ALU_SUB;
                            `FUNCT_AND: alu_op = `ALU_AND;
                            `FUNCT_OR:  alu_op = `ALU_OR;
                            default:    alu_op = `ALU_DEFAULT;
                        endcase
                    end
                    
                    `OP_ADDI: begin
                        // addi指令
                        reg_dst_flag = 1'b0; // 写入rt
                        alu_src_flag = 1'b1; // ALU源为立即数
                        alu_op = `ALU_ADD;   // ALU执行加法
                    end
                    
                    `OP_ORI: begin
                        // ori指令
                        reg_dst_flag = 1'b0; // 写入rt
                        alu_src_flag = 1'b1; // ALU源为立即数
                        alu_op = `ALU_OR;    // ALU执行或操作
                    end
                    
                    `OP_BEQ: begin
                        // beq指令
                        reg_dst_flag = 1'b0; // 不写入寄存器
                        alu_src_flag = 1'b0; // ALU源为寄存器
                        alu_op = `ALU_SUB;   // ALU执行减法，用于比较
                        branch_flag = 1'b1;  // 分支标志
                    end
                    
                    `OP_J: begin
                        // j指令
                        jump_flag = 1'b1; // 跳转标志
                    end
                    
                    `OP_LW: begin
                        // lw指令
                        reg_dst_flag = 1'b0; // 写入rt
                        alu_src_flag = 1'b1; // ALU源为立即数
                        alu_op = `ALU_ADD;   // ALU执行加法，计算地址
                        mem_to_reg_flag = 1'b1; // 从存储器读取数据
                    end
                    
                    `OP_SW: begin
                        // sw指令
                        reg_dst_flag = 1'b0; // 不写入寄存器
                        alu_src_flag = 1'b1; // ALU源为立即数
                        alu_op = `ALU_ADD;   // ALU执行加法，计算地址
                    end
                    
                    default: begin
                        // 默认情况
                    end
                endcase
            end
            
            EX: begin
                // 执行阶段，根据指令类型生成控制信号
                // 大部分控制信号已经在ID阶段生成
                case (opcode)
                    `OP_R_TYPE, `OP_ADDI, `OP_ORI: begin
                        reg_write_flag = 1'b1; // 寄存器写使能
                    end
                    
                    `OP_LW: begin
                        mem_read_flag = 1'b1; // 存储器读使能
                    end
                    
                    `OP_SW: begin
                        mem_write_flag = 1'b1; // 存储器写使能
                    end
                    
                    default: begin
                        // 默认情况
                    end
                endcase
            end
            
            MEM: begin
                // 访存阶段
                case (opcode)
                    `OP_LW: begin
                        mem_read_flag = 1'b1; // 存储器读使能
                        mem_to_reg_flag = 1'b1; // 从存储器读取数据
                    end
                    
                    `OP_SW: begin
                        mem_write_flag = 1'b1; // 存储器写使能
                    end
                    
                    default: begin
                        // 默认情况
                    end
                endcase
            end
            
            WB: begin
                // 写回阶段
                case (opcode)
                    `OP_R_TYPE, `OP_ADDI, `OP_ORI: begin
                        reg_write_flag = 1'b1; // 寄存器写使能
                    end
                    
                    `OP_LW: begin
                        reg_write_flag = 1'b1; // 寄存器写使能
                        mem_to_reg_flag = 1'b1; // 从存储器读取数据
                    end
                    
                    default: begin
                        // 默认情况
                    end
                endcase
            end
            
            default: begin
                // 默认情况
            end
        endcase
    end
    
endmodule
