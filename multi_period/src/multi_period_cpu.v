`include "defines.v"

module multi_period_cpu(
    input wire clk,                   // 时钟信号
    input wire rst,                   // 复位信号，高电平有效
    output wire [`ADDR_LEN-1:0] pc,   // 程序计数器
    output wire [`DATA_LEN-1:0] inst  // 当前执行的指令
);

    // 内部信号定义和连接
    wire [`DATA_LEN-1:0] reg1_data;
    wire [`DATA_LEN-1:0] reg2_data;
    wire [`DATA_LEN-1:0] alu_b;
    wire [`DATA_LEN-1:0] alu_result;
    wire [`DATA_LEN-1:0] mem_read_data;
    wire [`DATA_LEN-1:0] write_back_data;
    wire [`DATA_LEN-1:0] ext_imm;
    wire [`ADDR_LEN-1:0] next_pc;
    wire [`ADDR_LEN-1:0] branch_pc;
    wire [`ADDR_LEN-1:0] jump_pc;
    wire [`ADDR_LEN-1:0] next_pc_temp;
    
    // 控制信号
    wire reg_dst_flag;
    wire alu_src_flag;
    wire mem_to_reg_flag;
    wire reg_write_flag;
    wire mem_read_flag;
    wire mem_write_flag;
    wire branch_flag;
    wire jump_flag;
    wire zero;
    wire [`ALU_OPCODE] alu_op;
    wire [`REG_ADDR_LEN-1:0] write_reg_addr;
    
    // 程序计数器模块
    pc pc_inst(
        .clk(clk),
        .rst(rst),
        .in(next_pc),
        .out(pc)
    );
    
    // 指令存储器
    inst_memory inst_mem(
        .addr(pc),
        .inst(inst)
    );
    
    // 控制单元, 分析指令
    control_unit ctrl_unit(
        .opcode(inst[`OPCODE]),
        .funct(inst[`FUNCT]),
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
    
    // 寄存器堆
    register_file reg_file(
        .clk(clk),
        .rst(rst),
        .we(reg_write_flag),
        .raddr1(inst[`RS]),
        .raddr2(inst[`RT]),
        .waddr(write_reg_addr),
        .wdata(write_back_data),
        .rdata1(reg1_data),
        .rdata2(reg2_data)
    );
    
    // 立即数符号扩展
    sign_extender sign_ext(
        .imm(inst[`IMM]),
        .ext_imm(ext_imm)
    );
    
    // ALU 源操作数选择器
    mux2 #(`DATA_LEN) alu_src_mux(
        .sel(alu_src_flag),
        .in0(reg2_data),
        .in1(ext_imm),
        .out(alu_b)
    );
    
    // ALU
    alu alu_inst(
        .a(reg1_data),
        .b(alu_b),
        .alu_op(alu_op),
        .result(alu_result),
        .zero(zero)
    );
    
    // 数据存储器
    data_memory data_mem(
        .clk(clk),
        .rst(rst),
        .mem_read_flag(mem_read_flag),
        .mem_write_flag(mem_write_flag),
        .addr(alu_result),
        .write_data(reg2_data),
        .read_data(mem_read_data)
    );
    
    // 写回数据选择器
    mux2 #(`DATA_LEN) write_back_mux(
        .sel(mem_to_reg_flag),
        .in0(alu_result),
        .in1(mem_read_data),
        .out(write_back_data)
    );
    
    // 写寄存器地址选择器
    mux2 #(`REG_ADDR_LEN) reg_dst_mux(
        .sel(reg_dst_flag),
        .in0(inst[`RT]),
        .in1(inst[`RD]),
        .out(write_reg_addr)
    );
    
    // 下一条地址选择, 没写mux3, 用2个mux2来实现
    // 分支目标地址计算
    assign branch_pc = pc + (ext_imm << 2);
    mux2 #(`ADDR_LEN) branch_mux(
        .sel(branch_flag && zero),
        .in0(pc + 4),
        .in1(branch_pc),
        .out(next_pc_temp)
    );
    
    // 跳转目标地址计算
    assign jump_pc = {pc[31:28], inst[`J_ADDR], 2'b00};
    mux2 #(`ADDR_LEN) jump_mux(
        .sel(jump_flag),
        .in0(next_pc_temp),
        .in1(jump_pc),
        .out(next_pc)
    );
    
endmodule