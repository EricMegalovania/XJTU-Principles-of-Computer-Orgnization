`include "defines.v"

// 控制单元模块
module control_sign(
    input wire [`OPCODE] opcode,        // 指令的opcode字段
    input wire [`FUNCT] funct,          // 指令的funct字段
    input wire [`STATE_LEN-1:0] state,  // 当前状态
    output wire reg_dst_flag,           // 寄存器写地址选择信号
    output wire alu_src_flag,           // ALU源操作数选择信号
    output wire mem_to_reg_flag,        // 存储器到寄存器写回选择信号
    output wire reg_write_flag,         // 寄存器写使能信号
    output wire mem_read_flag,          // 存储器读使能信号
    output wire mem_write_flag,         // 存储器写使能信号
    output wire branch_flag,            // 分支控制信号
    output wire jump_flag,              // 跳转控制信号
    output wire [`ALU_OPCODE] alu_op    // ALU操作码
);
    
    // 内部寄存器信号
    reg reg_dst_flag_reg;
    reg alu_src_flag_reg;
    reg mem_to_reg_flag_reg;
    reg reg_write_flag_reg;
    reg mem_read_flag_reg;
    reg mem_write_flag_reg;
    reg branch_flag_reg;
    reg jump_flag_reg;
    reg [`ALU_OPCODE] alu_op_reg;
    
    always @(*) begin
        // 默认值
        reg_dst_flag_reg    = 1'b0;
        alu_src_flag_reg    = 1'b0;
        mem_to_reg_flag_reg = 1'b0;
        reg_write_flag_reg  = 1'b0;
        mem_read_flag_reg   = 1'b0;
        mem_write_flag_reg  = 1'b0;
        branch_flag_reg     = 1'b0;
        jump_flag_reg       = 1'b0;
        alu_op_reg          = `ALU_DEFAULT;
        
        case (state)
            `STATE_IF: begin
                // 取指阶段，不需要任何控制信号
            end
            
            `STATE_ID: begin
                // 解码阶段，根据指令类型设置部分控制信号
                if (opcode == `OP_J) begin
                    jump_flag_reg = 1'b1;
                end
            end
            
            `STATE_EX: begin
                // 执行阶段
                case (opcode)
                    `OP_R_TYPE: begin
                        reg_dst_flag_reg = 1'b1;  // 写地址为rd
                        alu_src_flag_reg = 1'b0;  // 第二个源操作数为寄存器
                        
                        // 根据funct字段确定ALU操作
                        case (funct)
                            `FUNCT_ADD: alu_op_reg = `ALU_ADD;
                            `FUNCT_SUB: alu_op_reg = `ALU_SUB;
                            `FUNCT_AND: alu_op_reg = `ALU_AND;
                            `FUNCT_OR:  alu_op_reg = `ALU_OR;
                            default:    alu_op_reg = `ALU_DEFAULT;
                        endcase
                    end
                    
                    `OP_ADDI, `OP_ORI: begin
                        reg_dst_flag_reg = 1'b0;      // 写地址为rt
                        alu_src_flag_reg = 1'b1;      // 第二个源操作数为立即数
                        alu_op_reg = (opcode == `OP_ADDI) ? `ALU_ADD : `ALU_OR;
                    end
                    
                    `OP_BEQ: begin
                        alu_src_flag_reg = 1'b0;      // 第二个源操作数为寄存器
                        branch_flag_reg  = 1'b1;      // 分支
                        alu_op_reg       = `ALU_SUB;  // 减法(用于比较)
                    end
                    
                    `OP_LW, `OP_SW: begin
                        alu_src_flag_reg = 1'b1;      // 第二个源操作数为立即数
                        alu_op_reg       = `ALU_ADD;  // 加法(计算地址)
                    end
                endcase
            end
            
            `STATE_MEM: begin
                // 访存阶段
                case (opcode)
                    `OP_LW: begin
                        mem_read_flag_reg = 1'b1;      // 读存储器
                    end
                    
                    `OP_SW: begin
                        mem_write_flag_reg = 1'b1;      // 写存储器
                    end
                endcase
            end
            
            `STATE_WB: begin
                // 写回阶段
                case (opcode)
                    `OP_R_TYPE, `OP_ADDI, `OP_ORI: begin
                        reg_write_flag_reg  = 1'b1;      // 写寄存器
                        mem_to_reg_flag_reg = 1'b0;      // 写回数据来自ALU
                    end
                    
                    `OP_LW: begin
                        reg_write_flag_reg  = 1'b1;      // 写寄存器
                        mem_to_reg_flag_reg = 1'b1;      // 写回数据来自存储器
                    end
                endcase
            end
        endcase
    end
    
    // 将内部寄存器信号连接到输出
    assign reg_dst_flag    = reg_dst_flag_reg;
    assign alu_src_flag    = alu_src_flag_reg;
    assign mem_to_reg_flag = mem_to_reg_flag_reg;
    assign reg_write_flag  = reg_write_flag_reg;
    assign mem_read_flag   = mem_read_flag_reg;
    assign mem_write_flag  = mem_write_flag_reg;
    assign branch_flag     = branch_flag_reg;
    assign jump_flag       = jump_flag_reg;
    assign alu_op          = alu_op_reg;
    
endmodule