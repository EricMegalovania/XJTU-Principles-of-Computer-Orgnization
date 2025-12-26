`include "defines.v"

// 流水线CPU控制信号生成模块（无状态机版本）
module control_sign_pipeline(
    input wire [`OPCODE] opcode,        // 指令的opcode字段
    input wire [`FUNCT] funct,          // 指令的funct字段
    output reg reg_dst_flag,            // 寄存器写地址选择信号
    output reg alu_src_flag,            // ALU源操作数选择信号
    output reg mem_to_reg_flag,         // 存储器到寄存器写回选择信号
    output reg reg_write_flag,          // 寄存器写使能信号
    output reg mem_read_flag,           // 存储器读使能信号
    output reg mem_write_flag,          // 存储器写使能信号
    output reg branch_flag,             // 分支控制信号
    output reg jump_flag,               // 跳转控制信号
    output reg [`ALU_OPCODE] alu_op     // ALU操作码
);
    
    always @(*) begin
        // 默认值
        reg_dst_flag    = 1'b0;
        alu_src_flag    = 1'b0;
        mem_to_reg_flag = 1'b0;
        reg_write_flag  = 1'b0;
        mem_read_flag   = 1'b0;
        mem_write_flag  = 1'b0;
        branch_flag     = 1'b0;
        jump_flag       = 1'b0;
        alu_op          = `ALU_DEFAULT;
        
        case (opcode)
            // R型指令
            `OP_R_TYPE: begin
                reg_dst_flag    = 1'b1;  // 写地址为rd
                alu_src_flag    = 1'b0;  // 第二个源操作数为寄存器
                mem_to_reg_flag = 1'b0;  // 写回数据来自ALU
                reg_write_flag  = 1'b1;  // 写寄存器
                mem_read_flag   = 1'b0;  // 不读存储器
                mem_write_flag  = 1'b0;  // 不写存储器
                branch_flag     = 1'b0;  // 不分支
                jump_flag       = 1'b0;  // 不跳转
                
                // 根据funct字段确定ALU操作
                case (funct)
                    `FUNCT_ADD: alu_op = `ALU_ADD;
                    `FUNCT_SUB: alu_op = `ALU_SUB;
                    `FUNCT_AND: alu_op = `ALU_AND;
                    `FUNCT_OR:  alu_op = `ALU_OR;
                    default:    alu_op = `ALU_DEFAULT;
                endcase
            end
            
            // addi指令
            `OP_ADDI: begin
                reg_dst_flag    = 1'b0;  // 写地址为rt
                alu_src_flag    = 1'b1;  // 第二个源操作数为立即数
                mem_to_reg_flag = 1'b0;  // 写回数据来自ALU
                reg_write_flag  = 1'b1;  // 写寄存器
                mem_read_flag   = 1'b0;  // 不读存储器
                mem_write_flag  = 1'b0;  // 不写存储器
                branch_flag     = 1'b0;  // 不分支
                jump_flag       = 1'b0;  // 不跳转
                alu_op          = `ALU_ADD;
            end
            
            // ori指令
            `OP_ORI: begin
                reg_dst_flag    = 1'b0;  // 写地址为rt
                alu_src_flag    = 1'b1;  // 第二个源操作数为立即数
                mem_to_reg_flag = 1'b0;  // 写回数据来自ALU
                reg_write_flag  = 1'b1;  // 写寄存器
                mem_read_flag   = 1'b0;  // 不读存储器
                mem_write_flag  = 1'b0;  // 不写存储器
                branch_flag     = 1'b0;  // 不分支
                jump_flag       = 1'b0;  // 不跳转
                alu_op          = `ALU_OR;
            end
            
            // lw指令
            `OP_LW: begin
                reg_dst_flag    = 1'b0;  // 写地址为rt
                alu_src_flag    = 1'b1;  // 第二个源操作数为立即数
                mem_to_reg_flag = 1'b1;  // 写回数据来自存储器
                reg_write_flag  = 1'b1;  // 写寄存器
                mem_read_flag   = 1'b1;  // 读存储器
                mem_write_flag  = 1'b0;  // 不写存储器
                branch_flag     = 1'b0;  // 不分支
                jump_flag       = 1'b0;  // 不跳转
                alu_op          = `ALU_ADD;
            end
            
            // sw指令
            `OP_SW: begin
                reg_dst_flag    = 1'b0;  // 无效
                alu_src_flag    = 1'b1;  // 第二个源操作数为立即数
                mem_to_reg_flag = 1'b0;  // 无效
                reg_write_flag  = 1'b0;  // 不写寄存器
                mem_read_flag   = 1'b0;  // 不读存储器
                mem_write_flag  = 1'b1;  // 写存储器
                branch_flag     = 1'b0;  // 不分支
                jump_flag       = 1'b0;  // 不跳转
                alu_op          = `ALU_ADD;
            end
            
            // beq指令
            `OP_BEQ: begin
                reg_dst_flag    = 1'b0;  // 无效
                alu_src_flag    = 1'b0;  // 两个操作数都来自寄存器
                mem_to_reg_flag = 1'b0;  // 无效
                reg_write_flag  = 1'b0;  // 不写寄存器
                mem_read_flag   = 1'b0;  // 不读存储器
                mem_write_flag  = 1'b0;  // 不写存储器
                branch_flag     = 1'b1;  // 分支
                jump_flag       = 1'b0;  // 不跳转
                alu_op          = `ALU_SUB;  // beq使用减法比较
            end
            
            // j指令
            `OP_J: begin
                reg_dst_flag    = 1'b0;  // 无效
                alu_src_flag    = 1'b0;  // 无效
                mem_to_reg_flag = 1'b0;  // 无效
                reg_write_flag  = 1'b0;  // 不写寄存器
                mem_read_flag   = 1'b0;  // 不读存储器
                mem_write_flag  = 1'b0;  // 不写存储器
                branch_flag     = 1'b0;  // 不分支
                jump_flag       = 1'b1;  // 跳转
                alu_op          = `ALU_DEFAULT;
            end
            
            default: begin
                // 其他指令使用默认值
            end
        endcase
    end
    
endmodule