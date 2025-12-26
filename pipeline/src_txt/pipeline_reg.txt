`include "defines.v"

// IF/ID 流水线寄存器模块
module pipeline_reg_if_id(
    input wire clk,
    input wire rst,
    input wire flush,           // 冲刷信号
    input wire stall,           // 暂停信号
    
    // IF阶段输入
    input wire [`ADDR_LEN-1:0] if_pc_plus4,
    input wire [`DATA_LEN-1:0] if_inst,
    
    // ID阶段输出
    output reg [`ADDR_LEN-1:0] id_pc_plus4,
    output reg [`DATA_LEN-1:0] id_inst
);
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            id_pc_plus4 <= 32'b0;
            id_inst <= 32'b0;
        end
        else if (flush) begin
            // 冲刷流水线，插入空指令
            id_pc_plus4 <= 32'b0;
            id_inst <= 32'b0;
        end
        else if (!stall) begin
            // 正常流水线推进
            id_pc_plus4 <= if_pc_plus4;
            id_inst <= if_inst;
        end
        // 如果stall=1，则保持不变（暂停）
    end
    
endmodule

// ID/EX 流水线寄存器模块
module pipeline_reg_id_ex(
    input wire clk,
    input wire rst,
    input wire flush,           // 冲刷信号
    input wire stall,           // 暂停信号
    
    // ID阶段输入 - 控制信号
    input wire id_reg_dst_flag,
    input wire id_alu_src_flag,
    input wire id_mem_to_reg_flag,
    input wire id_reg_write_flag,
    input wire id_mem_read_flag,
    input wire id_mem_write_flag,
    input wire id_branch_flag,
    input wire id_jump_flag,
    input wire [`ALU_OPCODE] id_alu_op,
    
    // ID阶段输入 - 数据
    input wire [`DATA_LEN-1:0] id_pc_plus4,
    input wire [`DATA_LEN-1:0] id_reg1_data,
    input wire [`DATA_LEN-1:0] id_reg2_data,
    input wire [`DATA_LEN-1:0] id_ext_imm,
    input wire [`REG_ADDR_LEN-1:0] id_inst_rs,
    input wire [`REG_ADDR_LEN-1:0] id_inst_rt,
    input wire [`REG_ADDR_LEN-1:0] id_inst_rd,
    input wire [`DATA_LEN-1:0] id_jump_addr,
    
    // EX阶段输出 - 控制信号
    output reg ex_reg_dst_flag,
    output reg ex_alu_src_flag,
    output reg ex_mem_to_reg_flag,
    output reg ex_reg_write_flag,
    output reg ex_mem_read_flag,
    output reg ex_mem_write_flag,
    output reg ex_branch_flag,
    output reg ex_jump_flag,
    output reg [`ALU_OPCODE] ex_alu_op,
    
    // EX阶段输出 - 数据
    output reg [`DATA_LEN-1:0] ex_pc_plus4,
    output reg [`DATA_LEN-1:0] ex_reg1_data,
    output reg [`DATA_LEN-1:0] ex_reg2_data,
    output reg [`DATA_LEN-1:0] ex_ext_imm,
    output reg [`REG_ADDR_LEN-1:0] ex_inst_rs,
    output reg [`REG_ADDR_LEN-1:0] ex_inst_rt,
    output reg [`REG_ADDR_LEN-1:0] ex_inst_rd,
    output reg [`DATA_LEN-1:0] ex_jump_addr
);
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 控制信号复位
            ex_reg_dst_flag <= 1'b0;
            ex_alu_src_flag <= 1'b0;
            ex_mem_to_reg_flag <= 1'b0;
            ex_reg_write_flag <= 1'b0;
            ex_mem_read_flag <= 1'b0;
            ex_mem_write_flag <= 1'b0;
            ex_branch_flag <= 1'b0;
            ex_jump_flag <= 1'b0;
            ex_alu_op <= `ALU_DEFAULT;
            
            // 数据复位
            ex_pc_plus4 <= 32'b0;
            ex_reg1_data <= 32'b0;
            ex_reg2_data <= 32'b0;
            ex_ext_imm <= 32'b0;
            ex_inst_rs <= 5'b0;
            ex_inst_rt <= 5'b0;
            ex_inst_rd <= 5'b0;
            ex_jump_addr <= 32'b0;
        end
        else if (flush) begin
            // 冲刷流水线，插入空指令
            ex_reg_dst_flag <= 1'b0;
            ex_alu_src_flag <= 1'b0;
            ex_mem_to_reg_flag <= 1'b0;
            ex_reg_write_flag <= 1'b0;
            ex_mem_read_flag <= 1'b0;
            ex_mem_write_flag <= 1'b0;
            ex_branch_flag <= 1'b0;
            ex_jump_flag <= 1'b0;
            ex_alu_op <= `ALU_DEFAULT;
            
            ex_pc_plus4 <= 32'b0;
            ex_reg1_data <= 32'b0;
            ex_reg2_data <= 32'b0;
            ex_ext_imm <= 32'b0;
            ex_inst_rs <= 5'b0;
            ex_inst_rt <= 5'b0;
            ex_inst_rd <= 5'b0;
            ex_jump_addr <= 32'b0;
        end
        else if (!stall) begin
            // 正常流水线推进
            ex_reg_dst_flag <= id_reg_dst_flag;
            ex_alu_src_flag <= id_alu_src_flag;
            ex_mem_to_reg_flag <= id_mem_to_reg_flag;
            ex_reg_write_flag <= id_reg_write_flag;
            ex_mem_read_flag <= id_mem_read_flag;
            ex_mem_write_flag <= id_mem_write_flag;
            ex_branch_flag <= id_branch_flag;
            ex_jump_flag <= id_jump_flag;
            ex_alu_op <= id_alu_op;
            
            ex_pc_plus4 <= id_pc_plus4;
            ex_reg1_data <= id_reg1_data;
            ex_reg2_data <= id_reg2_data;
            ex_ext_imm <= id_ext_imm;
            ex_inst_rs <= id_inst_rs;
            ex_inst_rt <= id_inst_rt;
            ex_inst_rd <= id_inst_rd;
            ex_jump_addr <= id_jump_addr;
        end
        // 如果stall=1，则保持不变（暂停）
    end
    
endmodule

// EX/MEM 流水线寄存器模块
module pipeline_reg_ex_mem(
    input wire clk,
    input wire rst,
    input wire flush,           // 冲刷信号
    input wire stall,           // 暂停信号
    
    // EX阶段输入 - 控制信号
    input wire ex_mem_to_reg_flag,
    input wire ex_reg_write_flag,
    input wire ex_mem_read_flag,
    input wire ex_mem_write_flag,
    input wire ex_branch_flag,
    input wire ex_jump_flag,
    
    // EX阶段输入 - 数据
    input wire [`DATA_LEN-1:0] ex_alu_result,
    input wire [`DATA_LEN-1:0] ex_reg2_data,
    input wire [`REG_ADDR_LEN-1:0] ex_write_reg_addr,
    input wire [`DATA_LEN-1:0] ex_pc_plus4,
    input wire [`DATA_LEN-1:0] ex_jump_addr,
    
    // MEM阶段输出 - 控制信号
    output reg mem_mem_to_reg_flag,
    output reg mem_reg_write_flag,
    output reg mem_mem_read_flag,
    output reg mem_mem_write_flag,
    output reg mem_branch_flag,
    output reg mem_jump_flag,
    
    // MEM阶段输出 - 数据
    output reg [`DATA_LEN-1:0] mem_alu_result,
    output reg [`DATA_LEN-1:0] mem_reg2_data,
    output reg [`REG_ADDR_LEN-1:0] mem_write_reg_addr,
    output reg [`DATA_LEN-1:0] mem_pc_plus4,
    output reg [`DATA_LEN-1:0] mem_jump_addr
);
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 控制信号复位
            mem_mem_to_reg_flag <= 1'b0;
            mem_reg_write_flag <= 1'b0;
            mem_mem_read_flag <= 1'b0;
            mem_mem_write_flag <= 1'b0;
            mem_branch_flag <= 1'b0;
            mem_jump_flag <= 1'b0;
            
            // 数据复位
            mem_alu_result <= 32'b0;
            mem_reg2_data <= 32'b0;
            mem_write_reg_addr <= 5'b0;
            mem_pc_plus4 <= 32'b0;
            mem_jump_addr <= 32'b0;
        end
        else if (flush) begin
            // 冲刷流水线，插入空指令
            mem_mem_to_reg_flag <= 1'b0;
            mem_reg_write_flag <= 1'b0;
            mem_mem_read_flag <= 1'b0;
            mem_mem_write_flag <= 1'b0;
            mem_branch_flag <= 1'b0;
            mem_jump_flag <= 1'b0;
            
            mem_alu_result <= 32'b0;
            mem_reg2_data <= 32'b0;
            mem_write_reg_addr <= 5'b0;
            mem_pc_plus4 <= 32'b0;
            mem_jump_addr <= 32'b0;
        end
        else if (!stall) begin
            // 正常流水线推进
            mem_mem_to_reg_flag <= ex_mem_to_reg_flag;
            mem_reg_write_flag <= ex_reg_write_flag;
            mem_mem_read_flag <= ex_mem_read_flag;
            mem_mem_write_flag <= ex_mem_write_flag;
            mem_branch_flag <= ex_branch_flag;
            mem_jump_flag <= ex_jump_flag;
            
            mem_alu_result <= ex_alu_result;
            mem_reg2_data <= ex_reg2_data;
            mem_write_reg_addr <= ex_write_reg_addr;
            mem_pc_plus4 <= ex_pc_plus4;
            mem_jump_addr <= ex_jump_addr;
        end
        // 如果stall=1，则保持不变（暂停）
    end
    
endmodule

// MEM/WB 流水线寄存器模块
module pipeline_reg_mem_wb(
    input wire clk,
    input wire rst,
    input wire flush,           // 冲刷信号
    input wire stall,           // 暂停信号
    
    // MEM阶段输入 - 控制信号
    input wire mem_mem_to_reg_flag,
    input wire mem_reg_write_flag,
    
    // MEM阶段输入 - 数据
    input wire [`DATA_LEN-1:0] mem_alu_result,
    input wire [`DATA_LEN-1:0] mem_mem_read_data,
    input wire [`REG_ADDR_LEN-1:0] mem_write_reg_addr,
    
    // WB阶段输出 - 控制信号
    output reg wb_mem_to_reg_flag,
    output reg wb_reg_write_flag,
    
    // WB阶段输出 - 数据
    output reg [`DATA_LEN-1:0] wb_alu_result,
    output reg [`DATA_LEN-1:0] wb_mem_read_data,
    output reg [`REG_ADDR_LEN-1:0] wb_write_reg_addr
);
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 控制信号复位
            wb_mem_to_reg_flag <= 1'b0;
            wb_reg_write_flag <= 1'b0;
            
            // 数据复位
            wb_alu_result <= 32'b0;
            wb_mem_read_data <= 32'b0;
            wb_write_reg_addr <= 5'b0;
        end
        else if (flush) begin
            // 冲刷流水线，插入空指令
            wb_mem_to_reg_flag <= 1'b0;
            wb_reg_write_flag <= 1'b0;
            
            wb_alu_result <= 32'b0;
            wb_mem_read_data <= 32'b0;
            wb_write_reg_addr <= 5'b0;
        end
        else if (!stall) begin
            // 正常流水线推进
            wb_mem_to_reg_flag <= mem_mem_to_reg_flag;
            wb_reg_write_flag <= mem_reg_write_flag;
            
            wb_alu_result <= mem_alu_result;
            wb_mem_read_data <= mem_mem_read_data;
            wb_write_reg_addr <= mem_write_reg_addr;
        end
        // 如果stall=1，则保持不变（暂停）
    end
    
endmodule