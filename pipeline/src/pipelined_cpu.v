`include "defines.v"

module pipelined_cpu(
    input wire clk,                   // 时钟信号
    input wire rst,                   // 复位信号，高电平有效
    output wire [`ADDR_LEN-1:0] pc,   // 程序计数器
    output wire [`DATA_LEN-1:0] inst  // 当前执行的指令（用于调试）
);

    // ================================
    // IF阶段信号
    // ================================
    wire [`ADDR_LEN-1:0] if_pc;
    wire [`ADDR_LEN-1:0] if_pc_plus4;
    wire [`DATA_LEN-1:0] if_inst;
    
    // ================================
    // ID阶段信号
    // ================================
    wire [`DATA_LEN-1:0] id_inst;
    wire [`ADDR_LEN-1:0] id_pc_plus4;
    wire [`DATA_LEN-1:0] id_reg1_data;
    wire [`DATA_LEN-1:0] id_reg2_data;
    wire [`DATA_LEN-1:0] id_ext_imm;
    wire [`REG_ADDR_LEN-1:0] id_inst_rs;
    wire [`REG_ADDR_LEN-1:0] id_inst_rt;
    wire [`REG_ADDR_LEN-1:0] id_inst_rd;
    wire [`DATA_LEN-1:0] id_jump_addr;
    
    // ID阶段控制信号
    wire id_reg_dst_flag;
    wire id_alu_src_flag;
    wire id_mem_to_reg_flag;
    wire id_reg_write_flag;
    wire id_mem_read_flag;
    wire id_mem_write_flag;
    wire id_branch_flag;
    wire id_jump_flag;
    wire [`ALU_OPCODE] id_alu_op;
    
    // ================================
    // EX阶段信号
    // ================================
    // EX阶段控制信号
    wire ex_reg_dst_flag;
    wire ex_alu_src_flag;
    wire ex_mem_to_reg_flag;
    wire ex_reg_write_flag;
    wire ex_mem_read_flag;
    wire ex_mem_write_flag;
    wire ex_branch_flag;
    wire ex_jump_flag;
    wire [`ALU_OPCODE] ex_alu_op;
    
    // EX阶段数据
    wire [`DATA_LEN-1:0] ex_reg1_data;
    wire [`DATA_LEN-1:0] ex_reg2_data;
    wire [`DATA_LEN-1:0] ex_ext_imm;
    wire [`REG_ADDR_LEN-1:0] ex_inst_rs;
    wire [`REG_ADDR_LEN-1:0] ex_inst_rt;
    wire [`REG_ADDR_LEN-1:0] ex_inst_rd;
    wire [`DATA_LEN-1:0] ex_jump_addr;
    wire [`DATA_LEN-1:0] ex_pc_plus4;
    
    // EX阶段计算结果
    wire [`DATA_LEN-1:0] ex_alu_result;
    wire ex_zero;
    wire [`DATA_LEN-1:0] ex_alu_b;
    wire [`REG_ADDR_LEN-1:0] ex_write_reg_addr;
    
    // ================================
    // MEM阶段信号
    // ================================
    // MEM阶段控制信号
    wire mem_mem_to_reg_flag;
    wire mem_reg_write_flag;
    wire mem_mem_read_flag;
    wire mem_mem_write_flag;
    wire mem_branch_flag;
    wire mem_jump_flag;
    
    // MEM阶段数据
    wire [`DATA_LEN-1:0] mem_alu_result;
    wire [`DATA_LEN-1:0] mem_reg2_data;
    wire [`REG_ADDR_LEN-1:0] mem_write_reg_addr;
    wire [`DATA_LEN-1:0] mem_pc_plus4;
    wire [`DATA_LEN-1:0] mem_jump_addr;
    
    // MEM阶段计算结果
    wire [`DATA_LEN-1:0] mem_mem_read_data;
    wire mem_zero;
    
    // ================================
    // WB阶段信号
    // ================================
    // WB阶段控制信号
    wire wb_mem_to_reg_flag;
    wire wb_reg_write_flag;
    
    // WB阶段数据
    wire [`DATA_LEN-1:0] wb_alu_result;
    wire [`DATA_LEN-1:0] wb_mem_read_data;
    wire [`REG_ADDR_LEN-1:0] wb_write_reg_addr;
    
    // WB阶段计算结果
    wire [`DATA_LEN-1:0] write_back_data;
    
    // ================================
    // 流水线控制信号
    // ================================
    wire if_stall;
    wire id_stall;
    wire flush_if_id;
    wire flush_id_ex;
    
    // 分支和跳转信号
    wire branch_taken;
    wire jump_taken;
    
    // ================================
    // IF阶段 (Instruction Fetch)
    // ================================
    
    // 程序计数器控制模块
    pc_if_id_control pc_control(
        .clk(clk),
        .rst(rst),
        .stall(id_stall),  // 使用ID阶段的暂停信号
        .next_pc_normal(if_pc_plus4),
        .next_pc_branch(ex_pc_plus4 + (ex_ext_imm << 2)),
        .branch_taken(ex_branch_flag && ex_zero),
        .jump_taken(ex_jump_flag),
        .jump_addr(ex_jump_addr),
        .pc(if_pc),
        .if_pc_plus4(if_pc_plus4),
        .if_inst(if_inst)
    );
    
    // 指令存储器
    inst_memory inst_mem(
        .addr(if_pc),
        .inst(if_inst)
    );
    
    // ================================
    // IF/ID 流水线寄存器
    // ================================
    
    pipeline_reg_if_id if_id_reg(
        .clk(clk),
        .rst(rst),
        .flush(flush_if_id),
        .stall(id_stall),
        .if_pc_plus4(if_pc_plus4),
        .if_inst(if_inst),
        .id_pc_plus4(id_pc_plus4),
        .id_inst(id_inst)
    );
    
    // ================================
    // ID阶段 (Instruction Decode)
    // ================================
    
    // 寄存器堆
    register_file reg_file(
        .clk(clk),
        .rst(rst),
        .we(wb_reg_write_flag),
        .raddr1(id_inst[`RS]),
        .raddr2(id_inst[`RT]),
        .waddr(wb_write_reg_addr),
        .wdata(write_back_data),
        .rdata1(id_reg1_data),
        .rdata2(id_reg2_data)
    );
    
    // 立即数符号扩展
    sign_extender sign_ext(
        .imm(id_inst[`IMM]),
        .ext_imm(id_ext_imm)
    );
    
    // 跳转地址计算
    assign id_jump_addr = {id_pc_plus4[31:28], id_inst[`J_ADDR], 2'b00};
    
    // 指令字段提取
    assign id_inst_rs = id_inst[`RS];
    assign id_inst_rt = id_inst[`RT];
    assign id_inst_rd = id_inst[`RD];
    
    // 控制单元
    control_unit id_control_unit(
        .opcode(id_inst[`OPCODE]),
        .funct(id_inst[`FUNCT]),
        .reg_dst_flag(id_reg_dst_flag),
        .alu_src_flag(id_alu_src_flag),
        .mem_to_reg_flag(id_mem_to_reg_flag),
        .reg_write_flag(id_reg_write_flag),
        .mem_read_flag(id_mem_read_flag),
        .mem_write_flag(id_mem_write_flag),
        .branch_flag(id_branch_flag),
        .jump_flag(id_jump_flag),
        .alu_op(id_alu_op)
    );
    
    // ================================
    // ID/EX 流水线寄存器
    // ================================
    
    pipeline_reg_id_ex id_ex_reg(
        .clk(clk),
        .rst(rst),
        .flush(flush_id_ex),
        .stall(id_stall),
        .id_reg_dst_flag(id_reg_dst_flag),
        .id_alu_src_flag(id_alu_src_flag),
        .id_mem_to_reg_flag(id_mem_to_reg_flag),
        .id_reg_write_flag(id_reg_write_flag),
        .id_mem_read_flag(id_mem_read_flag),
        .id_mem_write_flag(id_mem_write_flag),
        .id_branch_flag(id_branch_flag),
        .id_jump_flag(id_jump_flag),
        .id_alu_op(id_alu_op),
        .id_pc_plus4(id_pc_plus4),
        .id_reg1_data(id_reg1_data),
        .id_reg2_data(id_reg2_data),
        .id_ext_imm(id_ext_imm),
        .id_inst_rs(id_inst_rs),
        .id_inst_rt(id_inst_rt),
        .id_inst_rd(id_inst_rd),
        .id_jump_addr(id_jump_addr),
        .ex_reg_dst_flag(ex_reg_dst_flag),
        .ex_alu_src_flag(ex_alu_src_flag),
        .ex_mem_to_reg_flag(ex_mem_to_reg_flag),
        .ex_reg_write_flag(ex_reg_write_flag),
        .ex_mem_read_flag(ex_mem_read_flag),
        .ex_mem_write_flag(ex_mem_write_flag),
        .ex_branch_flag(ex_branch_flag),
        .ex_jump_flag(ex_jump_flag),
        .ex_alu_op(ex_alu_op),
        .ex_pc_plus4(ex_pc_plus4),
        .ex_reg1_data(ex_reg1_data),
        .ex_reg2_data(ex_reg2_data),
        .ex_ext_imm(ex_ext_imm),
        .ex_inst_rs(ex_inst_rs),
        .ex_inst_rt(ex_inst_rt),
        .ex_inst_rd(ex_inst_rd),
        .ex_jump_addr(ex_jump_addr)
    );
    
    // ================================
    // EX阶段 (Execute)
    // ================================
    
    // ALU源操作数选择器
    mux2 #(`DATA_LEN) alu_src_mux(
        .sel(ex_alu_src_flag),
        .in0(ex_reg2_data),
        .in1(ex_ext_imm),
        .out(ex_alu_b)
    );
    
    // ALU
    alu alu_inst(
        .a(ex_reg1_data),
        .b(ex_alu_b),
        .alu_op(ex_alu_op),
        .result(ex_alu_result),
        .zero(ex_zero)
    );
    
    // 写寄存器地址选择器
    mux2 #(`REG_ADDR_LEN) reg_dst_mux(
        .sel(ex_reg_dst_flag),
        .in0(ex_inst_rt),
        .in1(ex_inst_rd),
        .out(ex_write_reg_addr)
    );
    
    // ================================
    // EX/MEM 流水线寄存器
    // ================================
    
    pipeline_reg_ex_mem ex_mem_reg(
        .clk(clk),
        .rst(rst),
        .flush(1'b0),  // EX/MEM阶段不需要冲刷
        .stall(id_stall),
        .ex_mem_to_reg_flag(ex_mem_to_reg_flag),
        .ex_reg_write_flag(ex_reg_write_flag),
        .ex_mem_read_flag(ex_mem_read_flag),
        .ex_mem_write_flag(ex_mem_write_flag),
        .ex_branch_flag(ex_branch_flag),
        .ex_jump_flag(ex_jump_flag),
        .ex_alu_result(ex_alu_result),
        .ex_reg2_data(ex_reg2_data),
        .ex_write_reg_addr(ex_write_reg_addr),
        .ex_pc_plus4(ex_pc_plus4),
        .ex_jump_addr(ex_jump_addr),
        .mem_mem_to_reg_flag(mem_mem_to_reg_flag),
        .mem_reg_write_flag(mem_reg_write_flag),
        .mem_mem_read_flag(mem_mem_read_flag),
        .mem_mem_write_flag(mem_mem_write_flag),
        .mem_branch_flag(mem_branch_flag),
        .mem_jump_flag(mem_jump_flag),
        .mem_alu_result(mem_alu_result),
        .mem_reg2_data(mem_reg2_data),
        .mem_write_reg_addr(mem_write_reg_addr),
        .mem_pc_plus4(mem_pc_plus4),
        .mem_jump_addr(mem_jump_addr)
    );
    
    // ================================
    // MEM阶段 (Memory Access)
    // ================================
    
    // 数据存储器
    data_memory data_mem(
        .clk(clk),
        .rst(rst),
        .mem_read_flag(mem_mem_read_flag),
        .mem_write_flag(mem_mem_write_flag),
        .addr(mem_alu_result),
        .write_data(mem_reg2_data),
        .read_data(mem_mem_read_data)
    );
    
    // ================================
    // MEM/WB 流水线寄存器
    // ================================
    
    pipeline_reg_mem_wb mem_wb_reg(
        .clk(clk),
        .rst(rst),
        .flush(1'b0),  // MEM/WB阶段不需要冲刷
        .stall(id_stall),
        .mem_mem_to_reg_flag(mem_mem_to_reg_flag),
        .mem_reg_write_flag(mem_reg_write_flag),
        .mem_alu_result(mem_alu_result),
        .mem_mem_read_data(mem_mem_read_data),
        .mem_write_reg_addr(mem_write_reg_addr),
        .wb_mem_to_reg_flag(wb_mem_to_reg_flag),
        .wb_reg_write_flag(wb_reg_write_flag),
        .wb_alu_result(wb_alu_result),
        .wb_mem_read_data(wb_mem_read_data),
        .wb_write_reg_addr(wb_write_reg_addr)
    );
    
    // ================================
    // WB阶段 (Write Back)
    // ================================
    
    // 写回数据选择器
    mux2 #(`DATA_LEN) write_back_mux(
        .sel(wb_mem_to_reg_flag),
        .in0(wb_alu_result),
        .in1(wb_mem_read_data),
        .out(write_back_data)
    );
    
    // ================================
    // 流水线控制单元 (只处理Load-Use冒险)
    // ================================
    
    pipeline_control hazard_unit(
        .id_rs(id_inst_rs),
        .id_rt(id_inst_rt),
        .ex_rt(ex_inst_rt),
        .ex_mem_read_flag(ex_mem_read_flag),
        .ex_reg_write_flag(ex_reg_write_flag),
        .if_stall(if_stall),
        .id_stall(id_stall),
        .flush_if_id(flush_if_id),
        .flush_id_ex(flush_id_ex)
    );
    
    // 分支和跳转的冲刷逻辑
    // 分支跳转的条件：BEQ且相等，或者Jump指令
    wire flush_branch_jump;
    assign flush_branch_jump = (id_branch_flag && ex_zero) || id_jump_flag;
    assign flush_if_id = flush_branch_jump;
    
    // 调试输出
    assign pc = if_pc;
    assign inst = if_inst;
    
endmodule