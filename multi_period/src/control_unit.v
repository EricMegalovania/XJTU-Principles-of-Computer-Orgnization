`include "defines.v"

// 控制单元模块 - 多周期实现
module control_unit(
    input wire clk,                     // 时钟信号
    input wire rst,                     // 复位信号
    input wire [`OPCODE] opcode,        // 指令的opcode字段
    input wire [`FUNCT] funct,          // 指令的funct字段
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
    
    // 状态定义
    parameter [3:0] 
        STATE_IF  = 4'b0000,  // 取指状态
        STATE_ID  = 4'b0001,  // 译码状态
        STATE_EX  = 4'b0010,  // 执行状态
        STATE_MEM = 4'b0011,  // 内存访问状态
        STATE_WB  = 4'b0100;  // 写回状态
    
    reg [3:0] current_state;  // 当前状态
    reg [3:0] next_state;     // 下一个状态
    
    // 状态寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= STATE_IF;
        end else begin
            current_state <= next_state;
        end
    end
    
    // 状态转换逻辑
    always @(*) begin
        case (current_state)
            STATE_IF: begin
                // 取指完成后进入译码状态
                next_state = STATE_ID;
            end
            
            STATE_ID: begin
                case (opcode)
                    `OP_R_TYPE: begin
                        next_state = STATE_EX;
                    end
                    `OP_ADDI, `OP_ORI: begin
                        next_state = STATE_EX;
                    end
                    `OP_LW, `OP_SW: begin
                        next_state = STATE_EX;
                    end
                    `OP_BEQ: begin
                        next_state = STATE_EX;
                    end
                    `OP_J: begin
                        next_state = STATE_IF; // 跳转指令直接回到取指
                    end
                    default: begin
                        next_state = STATE_IF;
                    end
                endcase
            end
            
            STATE_EX: begin
                case (opcode)
                    `OP_R_TYPE: begin
                        next_state = STATE_WB;
                    end
                    `OP_ADDI, `OP_ORI: begin
                        next_state = STATE_WB;
                    end
                    `OP_LW: begin
                        next_state = STATE_MEM;
                    end
                    `OP_SW: begin
                        next_state = STATE_MEM;
                    end
                    `OP_BEQ: begin
                        next_state = STATE_IF;
                    end
                    default: begin
                        next_state = STATE_IF;
                    end
                endcase
            end
            
            STATE_MEM: begin
                case (opcode)
                    `OP_LW: begin
                        next_state = STATE_WB;
                    end
                    `OP_SW: begin
                        next_state = STATE_IF;
                    end
                    default: begin
                        next_state = STATE_IF;
                    end
                endcase
            end
            
            STATE_WB: begin
                // 写回完成后回到取指状态
                next_state = STATE_IF;
            end
            
            default: begin
                next_state = STATE_IF;
            end
        endcase
    end
    
    // 控制信号生成
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
            STATE_IF: begin
                // 取指状态
                pc_write_flag = 1'b1;  // 允许PC写入
                ir_write_flag = 1'b1;  // 允许指令寄存器写入
                alu_src_a     = `ALU_SRC_A_PC;
                alu_src_b     = `ALU_SRC_B_FOUR;
                alu_op        = `ALU_ADD;
                pc_src        = `PC_SRC_ALU;
            end
            
            STATE_ID: begin
                // 译码状态
                reg_data_write_flag = 1'b1;  // 允许寄存器数据写入
                alu_src_a           = `ALU_SRC_A_REG1;
                alu_src_b           = `ALU_SRC_B_REG2;
                alu_op              = `ALU_ADD;
                
                // 根据opcode设置ALU操作
                case (opcode)
                    `OP_R_TYPE: begin
                        alu_op = `ALU_ADD; // 实际操作在EX阶段根据funct确定
                    end
                    `OP_ADDI, `OP_LW, `OP_SW: begin
                        alu_op = `ALU_ADD;
                    end
                    `OP_ORI: begin
                        alu_op = `ALU_OR;
                    end
                    `OP_BEQ: begin
                        alu_op = `ALU_SUB;
                    end
                    `OP_J: begin
                        jump_flag = 1'b1;
                        pc_write_flag = 1'b1;
                        pc_src = `PC_SRC_JUMP;
                    end
                endcase
            end
            
            STATE_EX: begin
                // 执行状态
                alu_out_write_flag = 1'b1;  // 允许ALU输出写入
                
                case (opcode)
                    `OP_R_TYPE: begin
                        reg_dst_flag = 1'b1;
                        alu_src_a = `ALU_SRC_A_REG1;
                        alu_src_b = `ALU_SRC_B_REG2;
                        
                        // 根据funct确定ALU操作
                        case (funct)
                            `FUNCT_ADD: alu_op = `ALU_ADD;
                            `FUNCT_SUB: alu_op = `ALU_SUB;
                            `FUNCT_AND: alu_op = `ALU_AND;
                            `FUNCT_OR:  alu_op = `ALU_OR;
                            default:    alu_op = `ALU_DEFAULT;
                        endcase
                    end
                    
                    `OP_ADDI: begin
                        reg_dst_flag = 1'b0;
                        alu_src_a = `ALU_SRC_A_REG1;
                        alu_src_b = `ALU_SRC_B_IMM;
                        alu_op = `ALU_ADD;
                    end
                    
                    `OP_ORI: begin
                        reg_dst_flag = 1'b0;
                        alu_src_a = `ALU_SRC_A_REG1;
                        alu_src_b = `ALU_SRC_B_IMM;
                        alu_op = `ALU_OR;
                    end
                    
                    `OP_LW, `OP_SW: begin
                        reg_dst_flag = 1'b0;
                        alu_src_a = `ALU_SRC_A_REG1;
                        alu_src_b = `ALU_SRC_B_IMM;
                        alu_op = `ALU_ADD;
                    end
                    
                    `OP_BEQ: begin
                        branch_flag = 1'b1;
                        alu_src_a = `ALU_SRC_A_REG1;
                        alu_src_b = `ALU_SRC_B_REG2;
                        alu_op = `ALU_SUB;
                        
                        if (zero) begin
                            pc_write_flag = 1'b1;
                            pc_src = `PC_SRC_ALU;
                        end
                    end
                endcase
            end
            
            STATE_MEM: begin
                // 内存访问状态
                case (opcode)
                    `OP_LW: begin
                        mem_read_flag = 1'b1;
                        mem_data_write_flag = 1'b1;
                    end
                    
                    `OP_SW: begin
                        mem_write_flag = 1'b1;
                    end
                endcase
            end
            
            STATE_WB: begin
                // 写回状态
                reg_write_flag = 1'b1;
                
                case (opcode)
                    `OP_R_TYPE, `OP_ADDI, `OP_ORI: begin
                        mem_to_reg_flag = 1'b0;
                    end
                    
                    `OP_LW: begin
                        mem_to_reg_flag = 1'b1;
                    end
                endcase
            end
        endcase
    end
    
endmodule
