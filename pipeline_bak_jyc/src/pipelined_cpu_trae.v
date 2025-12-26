`include "defines.v"

module pipelined_cpu(
    input wire clk,                   // 时钟信号
    input wire rst,                   // 复位信号，高电平有效
    output wire [`ADDR_LEN-1:0] pc,   // 程序计数器
    output wire [`DATA_LEN-1:0] inst  // 当前执行的指令
);

    // IF阶段信号
    wire [`ADDR_LEN-1:0] pc_if;
    wire [`INSTR_LEN-1:0] inst_if;
    wire [`ADDR_LEN-1:0] next_pc;
    
    // IF/ID流水线寄存器输出
    wire [`ADDR_LEN-1:0] pc_id;
    wire [`INSTR_LEN-1:0] inst_id;
    
    // ID阶段信号
    wire [`DATA_LEN-1:0] reg1_data;
    wire [`DATA_LEN-1:0] reg2_data;
    wire [`DATA_LEN-1:0] ext_imm;
    wire [`REG_ADDR_LEN-1:0] rs_addr_id, rt_addr_id, rd_addr_id;
    
    // 控制信号
    wire reg_dst_flag, alu_src_flag, mem_to_reg_flag;
    wire reg_write_flag, mem_read_flag, mem_write_flag;
    wire branch_flag, jump_flag;
    wire [`ALU_OPCODE] alu_op;
    
    // ID/EX流水线寄存器输出
    wire [`ADDR_LEN-1:0] pc_ex;
    wire [`DATA_LEN-1:0] reg1_data_ex, reg2_data_ex;
    wire [`REG_ADDR_LEN-1:0] rs_addr_ex, rt_addr_ex, rd_addr_ex;
    wire [`DATA_LEN-1:0] ext_imm_ex;
    wire reg_dst_flag_ex, alu_src_flag_ex, mem_to_reg_flag_ex;
    wire reg_write_flag_ex, mem_read_flag_ex, mem_write_flag_ex;
    wire branch_flag_ex, jump_flag_ex;
    wire [`ALU_OPCODE] alu_op_ex;
    
    // EX阶段信号
    wire [`DATA_LEN-1:0] alu_b;
    wire [`DATA_LEN-1:0] alu_result;
    wire zero;
    
    // EX/MEM流水线寄存器输出
    wire [`ADDR_LEN-1:0] pc_mem;
    wire [`DATA_LEN-1:0] alu_result_mem;
    wire zero_mem;
    wire [`DATA_LEN-1:0] reg2_data_mem;
    wire [`REG_ADDR_LEN-1:0] write_reg_addr_mem;
    wire mem_to_reg_flag_mem;
    wire reg_write_flag_mem, mem_read_flag_mem, mem_write_flag_mem;
    wire branch_flag_mem, jump_flag_mem;
    
    // MEM阶段信号
    wire [`DATA_LEN-1:0] mem_read_data;
    
    // MEM/WB流水线寄存器输出
    wire [`ADDR_LEN-1:0] pc_wb;
    wire [`DATA_LEN-1:0] alu_result_wb;
    wire [`DATA_LEN-1:0] mem_read_data_wb;
    wire [`REG_ADDR_LEN-1:0] write_reg_addr_wb;
    wire mem_to_reg_flag_wb;
    wire reg_write_flag_wb;
    
    // WB阶段信号
    wire [`DATA_LEN-1:0] write_back_data;
    
    // Stall控制信号
    wire stall;
    
    // 分支和跳转控制
    wire [`ADDR_LEN-1:0] branch_pc;
    wire [`ADDR_LEN-1:0] jump_pc;
    wire [`ADDR_LEN-1:0] next_pc_temp;
    
    // 提取寄存器地址
    assign rs_addr_id = inst_id[`RS];
    assign rt_addr_id = inst_id[`RT];
    assign rd_addr_id = inst_id[`RD];
    
    // IF阶段：程序计数器
    pc pc_inst(
        .clk(clk),
        .rst(rst),
        .in(next_pc),
        .out(pc_if)
    );
    
    // IF阶段：指令存储器
    inst_memory inst_mem(
        .addr(pc_if),
        .inst(inst_if)
    );
    
    // IF/ID 流水线寄存器
    pipeline_reg_if_id if_id_reg(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .pc(pc_if),
        .inst(inst_if),
        .pc_id(pc_id),
        .inst_id(inst_id)
    );
    
    // ID阶段：寄存器堆
    register_file_pipeline reg_file(
        .clk(clk),
        .rst(rst),
        .we(reg_write_flag_wb),
        .raddr1(rs_addr_id),
        .raddr2(rt_addr_id),
        .waddr(write_reg_addr_wb),
        .wdata(write_back_data),
        .rdata1(reg1_data),
        .rdata2(reg2_data)
    );
    
    // ID阶段：立即数符号扩展
    sign_extender sign_ext(
        .imm(inst_id[`IMM]),
        .ext_imm(ext_imm)
    );
    
    // ID阶段：控制单元（简化版，不需要状态机）
    control_sign_pipeline ctrl_sign(
        .opcode(inst_id[`OPCODE]),
        .funct(inst_id[`FUNCT]),
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
    
    // ID阶段：Stall控制器
    stall_controller stall_ctrl(
        .inst_id(inst_id),
        .rs_addr_id(rs_addr_id),
        .rt_addr_id(rt_addr_id),
        .reg_write_flag_ex(reg_write_flag_ex),
        .write_reg_addr_ex(rd_addr_ex), // EX阶段的写地址（来自ID/EX寄存器）
        .mem_read_flag_ex(mem_read_flag_ex),
        .reg_write_flag_mem(reg_write_flag_mem),
        .write_reg_addr_mem(write_reg_addr_mem),
        .stall(stall)
    );
    
    // ID/EX 流水线寄存器
    pipeline_reg_id_ex id_ex_reg(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .pc_id(pc_id),
        .inst_id(inst_id),
        .reg1_data(reg1_data),
        .reg2_data(reg2_data),
        .rs_addr(rs_addr_id),
        .rt_addr(rt_addr_id),
        .rd_addr(rd_addr_id),
        .ext_imm(ext_imm),
        .reg_dst_flag(reg_dst_flag),
        .alu_src_flag(alu_src_flag),
        .mem_to_reg_flag(mem_to_reg_flag),
        .reg_write_flag(reg_write_flag),
        .mem_read_flag(mem_read_flag),
        .mem_write_flag(mem_write_flag),
        .branch_flag(branch_flag),
        .jump_flag(jump_flag),
        .alu_op(alu_op),
        .pc_ex(pc_ex),
        .reg1_data_ex(reg1_data_ex),
        .reg2_data_ex(reg2_data_ex),
        .rs_addr_ex(rs_addr_ex),
        .rt_addr_ex(rt_addr_ex),
        .rd_addr_ex(rd_addr_ex),
        .ext_imm_ex(ext_imm_ex),
        .reg_dst_flag_ex(reg_dst_flag_ex),
        .alu_src_flag_ex(alu_src_flag_ex),
        .mem_to_reg_flag_ex(mem_to_reg_flag_ex),
        .reg_write_flag_ex(reg_write_flag_ex),
        .mem_read_flag_ex(mem_read_flag_ex),
        .mem_write_flag_ex(mem_write_flag_ex),
        .branch_flag_ex(branch_flag_ex),
        .jump_flag_ex(jump_flag_ex),
        .alu_op_ex(alu_op_ex)
    );
    
    // EX阶段：ALU源操作数选择
    mux2 #(`DATA_LEN) alu_src_mux(
        .sel(alu_src_flag_ex),
        .in0(reg2_data_ex),
        .in1(ext_imm_ex),
        .out(alu_b)
    );
    
    // EX阶段：ALU
    alu alu_inst(
        .a(reg1_data_ex),
        .b(alu_b),
        .alu_op(alu_op_ex),
        .result(alu_result),
        .zero(zero)
    );
    
    // EX/MEM 流水线寄存器
    pipeline_reg_ex_mem ex_mem_reg(
        .clk(clk),
        .rst(rst),
        .pc_ex(pc_ex),
        .reg1_data_ex(reg1_data_ex),
        .reg2_data_ex(reg2_data_ex),
        .rs_addr_ex(rs_addr_ex),
        .rt_addr_ex(rt_addr_ex),
        .rd_addr_ex(rd_addr_ex),
        .ext_imm_ex(ext_imm_ex),
        .reg_dst_flag_ex(reg_dst_flag_ex),
        .alu_src_flag_ex(alu_src_flag_ex),
        .mem_to_reg_flag_ex(mem_to_reg_flag_ex),
        .reg_write_flag_ex(reg_write_flag_ex),
        .mem_read_flag_ex(mem_read_flag_ex),
        .mem_write_flag_ex(mem_write_flag_ex),
        .branch_flag_ex(branch_flag_ex),
        .jump_flag_ex(jump_flag_ex),
        .alu_op_ex(alu_op_ex),
        .alu_result(alu_result),
        .zero(zero),
        .pc_mem(pc_mem),
        .alu_result_mem(alu_result_mem),
        .zero_mem(zero_mem),
        .reg2_data_mem(reg2_data_mem),
        .write_reg_addr_mem(write_reg_addr_mem),
        .mem_to_reg_flag_mem(mem_to_reg_flag_mem),
        .reg_write_flag_mem(reg_write_flag_mem),
        .mem_read_flag_mem(mem_read_flag_mem),
        .mem_write_flag_mem(mem_write_flag_mem),
        .branch_flag_mem(branch_flag_mem),
        .jump_flag_mem(jump_flag_mem)
    );
    
    // MEM阶段：数据存储器
    data_memory data_mem(
        .clk(clk),
        .rst(rst),
        .mem_read_flag(mem_read_flag_mem),
        .mem_write_flag(mem_write_flag_mem),
        .addr(alu_result_mem),
        .write_data(reg2_data_mem),
        .read_data(mem_read_data)
    );
    
    // MEM/WB 流水线寄存器
    pipeline_reg_mem_wb mem_wb_reg(
        .clk(clk),
        .rst(rst),
        .pc_mem(pc_mem),
        .alu_result_mem(alu_result_mem),
        .mem_read_data(mem_read_data),
        .write_reg_addr_mem(write_reg_addr_mem),
        .mem_to_reg_flag_mem(mem_to_reg_flag_mem),
        .reg_write_flag_mem(reg_write_flag_mem),
        .pc_wb(pc_wb),
        .alu_result_wb(alu_result_wb),
        .mem_read_data_wb(mem_read_data_wb),
        .write_reg_addr_wb(write_reg_addr_wb),
        .mem_to_reg_flag_wb(mem_to_reg_flag_wb),
        .reg_write_flag_wb(reg_write_flag_wb)
    );
    
    // WB阶段：写回数据选择
    mux2 #(`DATA_LEN) write_back_mux(
        .sel(mem_to_reg_flag_wb),
        .in0(alu_result_wb),
        .in1(mem_read_data_wb),
        .out(write_back_data)
    );
    
    // PC更新逻辑（分支和跳转处理）
    // 分支目标地址计算
    assign branch_pc = pc_id + (ext_imm << 2);
    mux2 #(`ADDR_LEN) branch_mux(
        .sel(branch_flag_mem && zero_mem),
        .in0(pc_if + 4),
        .in1(branch_pc),
        .out(next_pc_temp)
    );
    
    // 跳转目标地址计算
    assign jump_pc = {pc_id[31:28], inst_id[`J_ADDR], 2'b00};
    mux2 #(`ADDR_LEN) jump_mux(
        .sel(jump_flag),
        .in0(next_pc_temp),
        .in1(jump_pc),
        .out(next_pc)
    );
    
    // 输出信号
    assign pc = pc_if;
    assign inst = inst_if;

endmodule