`include "defines.v"

// 多周期CPU顶层模块
module multi_period_cpu(
    input wire clk,  // 时钟信号
    input wire rst   // 复位信号
);
    
    // -------------------------- 内部信号定义 --------------------------
    
    // PC相关信号
    wire [`ADDR_LEN-1:0] pc_current;    // 当前PC值
    wire [`ADDR_LEN-1:0] pc_next;        // 下一个PC值
    wire [`ADDR_LEN-1:0] pc_plus4;       // PC+4
    wire [`ADDR_LEN-1:0] pc_branch;      // 分支选择后的PC值
    
    // 指令相关信号
    wire [`INSTR_LEN-1:0] inst;          // 当前指令
    wire [`INSTR_LEN-1:0] inst_reg;      // 指令寄存器
    
    // 寄存器堆相关信号
    wire [`REG_ADDR_LEN-1:0] reg_raddr1; // 寄存器读地址1
    wire [`REG_ADDR_LEN-1:0] reg_raddr2; // 寄存器读地址2
    wire [`REG_ADDR_LEN-1:0] reg_waddr;  // 寄存器写地址
    wire [`DATA_LEN-1:0] reg_rdata1;     // 寄存器读数据1
    wire [`DATA_LEN-1:0] reg_rdata2;     // 寄存器读数据2
    wire [`DATA_LEN-1:0] reg_wdata;      // 寄存器写数据
    wire [`DATA_LEN-1:0] reg_data1_reg;  // 寄存器读数据1寄存器
    wire [`DATA_LEN-1:0] reg_data2_reg;  // 寄存器读数据2寄存器
    
    // 立即数扩展相关信号
    wire [`DATA_LEN-1:0] ext_imm;        // 扩展后的立即数
    wire [`DATA_LEN-1:0] imm_reg;        // 立即数寄存器
    
    // ALU相关信号
    wire [`DATA_LEN-1:0] alu_a;          // ALU操作数A
    wire [`DATA_LEN-1:0] alu_b;          // ALU操作数B
    wire [`DATA_LEN-1:0] alu_result;     // ALU运算结果
    wire [`DATA_LEN-1:0] alu_result_reg; // ALU结果寄存器
    wire zero;                           // ALU零标志位
    
    // 数据存储器相关信号
    wire [`DATA_LEN-1:0] mem_read_data;  // 存储器读数据
    wire [`DATA_LEN-1:0] mem_read_data_reg; // 存储器读数据寄存器
    
    // 分支和跳转相关信号
    wire [`ADDR_LEN-1:0] branch_target;  // 分支目标地址
    wire [`ADDR_LEN-1:0] jump_target;    // 跳转目标地址
    wire branch_taken;                   // 是否执行分支
    
    // 控制信号
    wire reg_dst_flag;                   // 寄存器目标选择
    wire alu_src_flag;                   // ALU源选择
    wire mem_to_reg_flag;                // 存储器到寄存器
    wire reg_write_flag;                 // 寄存器写使能
    wire mem_read_flag;                  // 存储器读使能
    wire mem_write_flag;                 // 存储器写使能
    wire branch_flag;                    // 分支标志
    wire jump_flag;                      // 跳转标志
    wire [`ALU_OPCODE] alu_op;           // ALU操作码
    wire [2:0] state;                    // 当前状态
    
    // -------------------------- 模块实例化 --------------------------
    
    // 程序计数器（PC）
    pc pc_inst (
        .clk(clk),
        .rst(rst),
        .in(pc_next),
        .out(pc_current)
    );
    
    // 指令存储器
    inst_memory inst_memory_inst (
        .addr(pc_current),
        .inst(inst)
    );
    
    // 寄存器堆
    register_file register_file_inst (
        .clk(clk),
        .rst(rst),
        .we(reg_write_flag),
        .raddr1(reg_raddr1),
        .raddr2(reg_raddr2),
        .waddr(reg_waddr),
        .wdata(reg_wdata),
        .rdata1(reg_rdata1),
        .rdata2(reg_rdata2)
    );
    
    // 符号扩展器
    sign_extender sign_extender_inst (
        .imm(inst_reg[`IMM]),
        .ext_imm(ext_imm)
    );
    
    // ALU
    alu alu_inst (
        .a(alu_a),
        .b(alu_b),
        .alu_op(alu_op),
        .result(alu_result),
        .zero(zero)
    );
    
    // 数据存储器
    data_memory data_memory_inst (
        .clk(clk),
        .rst(rst),
        .mem_read_flag(mem_read_flag),
        .mem_write_flag(mem_write_flag),
        .addr(alu_result_reg),
        .write_data(reg_data2_reg),
        .read_data(mem_read_data)
    );
    
    // 控制单元
    control_unit control_unit_inst (
        .clk(clk),
        .rst(rst),
        .inst(inst_reg),
        .zero(zero),
        .reg_dst_flag(reg_dst_flag),
        .alu_src_flag(alu_src_flag),
        .mem_to_reg_flag(mem_to_reg_flag),
        .reg_write_flag(reg_write_flag),
        .mem_read_flag(mem_read_flag),
        .mem_write_flag(mem_write_flag),
        .branch_flag(branch_flag),
        .jump_flag(jump_flag),
        .alu_op(alu_op),
        .state(state)
    );
    
    // 多路选择器实例化
    mux2 #(5) mux_reg_dst (
        .sel(reg_dst_flag),
        .in0(inst_reg[`RT]),
        .in1(inst_reg[`RD]),
        .out(reg_waddr)
    );
    
    mux2 #(32) mux_alu_src (
        .sel(alu_src_flag),
        .in0(reg_data2_reg),
        .in1(imm_reg),
        .out(alu_b)
    );
    
    mux2 #(32) mux_mem_to_reg (
        .sel(mem_to_reg_flag),
        .in0(alu_result_reg),
        .in1(mem_read_data_reg),
        .out(reg_wdata)
    );
    
    mux2 #(32) mux_pc_branch (
        .sel(branch_taken),
        .in0(pc_plus4),
        .in1(branch_target),
        .out(pc_branch)
    );
    
    mux2 #(32) mux_pc_jump (
        .sel(jump_flag),
        .in0(pc_branch),
        .in1(jump_target),
        .out(pc_next)
    );
    
    // -------------------------- 多周期执行逻辑 --------------------------
    
    // PC+4计算
    assign pc_plus4 = pc_current + 32'd4;
    
    // 分支目标地址计算
    assign branch_target = pc_plus4 + (imm_reg << 2);
    
    // 跳转目标地址计算
    assign jump_target = {pc_plus4[31:28], inst_reg[`J_ADDR], 2'b00};
    
    // 分支条件判断
    assign branch_taken = branch_flag & zero;
    
    // ALU操作数A选择
    assign alu_a = reg_data1_reg;
    
    // 寄存器读地址1和读地址2
    assign reg_raddr1 = inst_reg[`RS];
    assign reg_raddr2 = inst_reg[`RT];
    
    // -------------------------- 内部寄存器 --------------------------
    
    // 指令寄存器，在ID阶段锁存指令
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            inst_reg <= 32'b0;
        end
        else if (state == 3'b000) begin // IF阶段结束时锁存指令
            inst_reg <= inst;
        end
    end
    
    // 寄存器读数据1寄存器，在ID阶段锁存
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_data1_reg <= 32'b0;
        end
        else if (state == 3'b001) begin // ID阶段结束时锁存
            reg_data1_reg <= reg_rdata1;
        end
    end
    
    // 寄存器读数据2寄存器，在ID阶段锁存
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_data2_reg <= 32'b0;
        end
        else if (state == 3'b001) begin // ID阶段结束时锁存
            reg_data2_reg <= reg_rdata2;
        end
    end
    
    // 立即数寄存器，在ID阶段锁存
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            imm_reg <= 32'b0;
        end
        else if (state == 3'b001) begin // ID阶段结束时锁存
            imm_reg <= ext_imm;
        end
    end
    
    // ALU结果寄存器，在EX阶段锁存
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            alu_result_reg <= 32'b0;
        end
        else if (state == 3'b010) begin // EX阶段结束时锁存
            alu_result_reg <= alu_result;
        end
    end
    
    // 存储器读数据寄存器，在MEM阶段锁存
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_read_data_reg <= 32'b0;
        end
        else if (state == 3'b011) begin // MEM阶段结束时锁存
            mem_read_data_reg <= mem_read_data;
        end
    end
    
endmodule
