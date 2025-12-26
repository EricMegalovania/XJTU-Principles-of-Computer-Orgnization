`include "defines.v"

// 流水线控制单元模块
module pipeline_control(
    // 寄存器地址
    input wire [`REG_ADDR_LEN-1:0] id_rs,     // ID阶段指令的rs寄存器
    input wire [`REG_ADDR_LEN-1:0] id_rt,     // ID阶段指令的rt寄存器
    input wire [`REG_ADDR_LEN-1:0] ex_rt,     // EX阶段指令的rt寄存器
    
    // 控制信号
    input wire ex_mem_read_flag,              // EX阶段指令是否为lw
    input wire ex_reg_write_flag,             // EX阶段指令是否写寄存器
    
    // 输出信号
    output reg if_stall,                      // IF阶段暂停信号
    output reg id_stall,                      // ID阶段暂停信号
    output reg flush_if_id,                   // 冲刷IF/ID寄存器
    output reg flush_id_ex                    // 冲刷ID/EX寄存器
);
    
    // 冒险检测逻辑
    wire load_use_hazard;                     // Load-Use冒险标志
    
    // 检测Load-Use冒险：
    // 当前ID阶段的指令需要使用某个寄存器，而EX阶段的指令是lw并且要写同一个寄存器
    assign load_use_hazard = ex_mem_read_flag && 
                            ex_reg_write_flag && 
                            ((ex_rt == id_rs) || (ex_rt == id_rt));
    
    // 控制逻辑
    always @(*) begin
        // 默认值
        if_stall = 1'b0;
        id_stall = 1'b0;
        flush_if_id = 1'b0;
        flush_id_ex = 1'b0;
        
        // 如果检测到Load-Use冒险，需要暂停流水线
        if (load_use_hazard) begin
            if_stall = 1'b1;        // 暂停IF阶段
            id_stall = 1'b1;        // 暂停ID阶段
            flush_id_ex = 1'b1;     // 冲刷ID/EX寄存器（插入空指令）
        end
        // 注意：分支和跳转的冲刷逻辑将在主CPU模块中处理
    end
    
endmodule

// PC和IF/ID寄存器暂停控制模块
module pc_if_id_control(
    input wire clk,
    input wire rst,
    input wire stall,               // 暂停信号
    input wire [`ADDR_LEN-1:0] next_pc_normal, // 正常的下一PC值
    input wire [`ADDR_LEN-1:0] next_pc_branch, // 分支跳转的PC值
    input wire branch_taken,        // 分支是否跳转
    input wire jump_taken,          // 跳转是否执行
    input wire [`ADDR_LEN-1:0] jump_addr,      // 跳转地址
    
    output reg [`ADDR_LEN-1:0] pc,  // 当前PC值
    output reg [`ADDR_LEN-1:0] if_pc_plus4,  // IF阶段PC+4
    output reg [`DATA_LEN-1:0] if_inst       // IF阶段指令
);
    
    wire [`ADDR_LEN-1:0] next_pc_mux1;
    wire [`ADDR_LEN-1:0] next_pc_mux2;
    
    // PC值选择逻辑
    mux2 #(`ADDR_LEN) pc_branch_mux(
        .sel(branch_taken),
        .in0(next_pc_normal),
        .in1(next_pc_branch),
        .out(next_pc_mux1)
    );
    
    mux2 #(`ADDR_LEN) pc_jump_mux(
        .sel(jump_taken),
        .in0(next_pc_mux1),
        .in1(jump_addr),
        .out(next_pc_mux2)
    );
    
    // PC寄存器更新逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 32'b0;
        end
        else if (!stall) begin
            // 只有在不暂停时才更新PC
            pc <= next_pc_mux2;
        end
        // 如果stall=1，PC保持不变
    end
    
    // PC+4计算
    always @(*) begin
        if (!stall) begin
            if_pc_plus4 = pc + 4;
        end
        // 如果stall，PC+4保持不变
    end
    
endmodule