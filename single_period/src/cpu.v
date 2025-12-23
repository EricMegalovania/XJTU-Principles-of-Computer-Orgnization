`include "defines.v"

module cpu(
    input wire clk,                   // 时钟信号
    input wire rst_n,                 // 复位信号，低电平有效
    output wire [`ADDR_LEN-1:0] pc,   // 程序计数器
    output wire [`DATA_LEN-1:0] inst  // 当前执行的指令
);

    // 内部信号连接
    wire [`DATA_LEN-1:0] reg1_data;
    wire [`DATA_LEN-1:0] reg2_data;
    wire [`DATA_LEN-1:0] alu_src2;
    wire [`DATA_LEN-1:0] alu_result;
    wire [`DATA_LEN-1:0] mem_read_data;
    wire [`DATA_LEN-1:0] write_back_data;
    wire [`DATA_LEN-1:0] ext_imm;
    wire [`ADDR_LEN-1:0] next_pc;
    wire [`ADDR_LEN-1:0] branch_pc;
    wire [`ADDR_LEN-1:0] jump_pc;
    wire [`ADDR_LEN-1:0] next_pc_temp;
    
    // 控制信号
    wire reg_dst;
    wire alu_src;
    wire mem_to_reg;
    wire reg_write;
    wire mem_read;
    wire mem_write;
    wire branch;
    wire jump;
    wire zero;
    wire [`ALU_OPCODE] alu_op;
    wire [`REG_ADDR_LEN-1:0] write_reg_addr;
    
    // 程序计数器模块
    pc pc_inst(
        .clk(clk),
        .rst_n(rst_n),
        .next_pc(next_pc),
        .pc(pc)
    );
    
    // 指令存储器
    inst_memory inst_mem(
        .addr(pc),
        .inst(inst)
    );
    
    // 控制单元
    control_unit ctrl_unit(
        .opcode(inst[`OPCODE]),
        .funct(inst[`FUNCT]),
        .reg_dst(reg_dst),
        .alu_src(alu_src),
        .mem_to_reg(mem_to_reg),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .branch(branch),
        .jump(jump),
        .alu_op(alu_op)
    );
    
    // 寄存器堆
    register_file reg_file(
        .clk(clk),
        .rst_n(rst_n),
        .we(reg_write),
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
        .sel(alu_src),
        .in0(reg2_data),
        .in1(ext_imm),
        .out(alu_src2)
    );
    
    // ALU
    alu alu_inst(
        .a(reg1_data),
        .b(alu_src2),
        .alu_op(alu_op),
        .result(alu_result),
        .zero(zero)
    );
    
    // 数据存储器
    data_memory data_mem(
        .clk(clk),
        .rst_n(rst_n),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .addr(alu_result),
        .write_data(reg2_data),
        .read_data(mem_read_data)
    );
    
    // 写回数据选择器
    mux2 #(`DATA_LEN) write_back_mux(
        .sel(mem_to_reg),
        .in0(alu_result),
        .in1(mem_read_data),
        .out(write_back_data)
    );
    
    // 写寄存器地址选择器
    mux2 #(`REG_ADDR_LEN) reg_dst_mux(
        .sel(reg_dst),
        .in0(inst[`RT]),
        .in1(inst[`RD]),
        .out(write_reg_addr)
    );
    
    // 分支目标地址计算
    assign branch_pc = pc + 4 + (ext_imm << 2);
    
    // 跳转目标地址计算
    assign jump_pc = {pc[31:28], inst[`J_ADDR], 2'b00};
    
    // 下一条 PC 选择
    wire branch_taken = branch && zero;
    mux2 #(`ADDR_LEN) branch_mux(
        .sel(branch_taken),
        .in0(pc + 4),
        .in1(branch_pc),
        .out(next_pc_temp)
    );
    
    mux2 #(`ADDR_LEN) jump_mux(
        .sel(jump),
        .in0(next_pc_temp),
        .in1(jump_pc),
        .out(next_pc)
    );
    
endmodule
