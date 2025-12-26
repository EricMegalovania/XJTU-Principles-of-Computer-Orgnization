`include "defines.v"

// Stall 控制器 - 处理数据冒险
module stall_controller(
    // ID阶段指令信息
    input wire [`INSTR_LEN-1:0] inst_id,     // ID阶段指令
    input wire [`REG_ADDR_LEN-1:0] rs_addr_id, // ID阶段rs寄存器地址
    input wire [`REG_ADDR_LEN-1:0] rt_addr_id, // ID阶段rt寄存器地址
    
    // EX/MEM阶段信息
    input wire reg_write_flag_ex,            // EX/MEM阶段寄存器写使能
    input wire [`REG_ADDR_LEN-1:0] write_reg_addr_ex, // EX/MEM阶段写寄存器地址
    input wire mem_read_flag_ex,             // EX/MEM阶段存储器读使能（lw指令）
    
    // MEM/WB阶段信息
    input wire reg_write_flag_mem,           // MEM/WB阶段寄存器写使能
    input wire [`REG_ADDR_LEN-1:0] write_reg_addr_mem, // MEM/WB阶段写寄存器地址
    
    // Stall信号输出
    output reg stall                         // 暂停信号
);

    // 检查ID阶段指令是否需要使用某个寄存器
    wire need_rs_id, need_rt_id;
    wire rs_hazard_ex, rt_hazard_ex;         // 与EX/MEM阶段的冒险
    wire rs_hazard_mem, rt_hazard_mem;       // 与MEM/WB阶段的冒险
    
    // 判断ID阶段指令是否需要rs和rt寄存器
    assign need_rs_id = (inst_id[`OPCODE] != `OP_J); // 除了跳转指令，其他都需要rs
    assign need_rt_id = (inst_id[`OPCODE] == `OP_R_TYPE || 
                         inst_id[`OPCODE] == `OP_ADDI || 
                         inst_id[`OPCODE] == `OP_ORI ||
                         inst_id[`OPCODE] == `OP_BEQ ||
                         inst_id[`OPCODE] == `OP_SW);
    
    // 检查与EX/MEM阶段的RAW冒险
    assign rs_hazard_ex = need_rs_id && reg_write_flag_ex && (write_reg_addr_ex == rs_addr_id);
    assign rt_hazard_ex = need_rt_id && reg_write_flag_ex && (write_reg_addr_ex == rt_addr_id);
    
    // 检查与MEM/WB阶段的RAW冒险
    assign rs_hazard_mem = need_rs_id && reg_write_flag_mem && (write_reg_addr_mem == rs_addr_id);
    assign rt_hazard_mem = need_rt_id && reg_write_flag_mem && (write_reg_addr_mem == rt_addr_id);
    
    always @(*) begin
        // 默认不暂停
        stall = 1'b0;
        
        // Load-Use冒险：EX/MEM阶段是lw指令且需要使用其结果
        if (mem_read_flag_ex && (rs_hazard_ex || rt_hazard_ex)) begin
            stall = 1'b1;  // 插入一个气泡
        end
        // 普通RAW冒险：MEM/WB阶段的结果被当前ID阶段使用
        else if (rs_hazard_mem || rt_hazard_mem) begin
            stall = 1'b0;  // 不需要暂停，使用寄存器堆的写后读特性
        end
    end

endmodule