`include "defines.v"

// 多周期CPU模块
module multi_period_cpu(
    input wire clk,                   // 时钟信号
    input wire rst,                   // 复位信号，高电平有效
    output wire [`ADDR_LEN-1:0] pc,   // 程序计数器
    output wire [`DATA_LEN-1:0] inst  // 当前执行的指令
);
    
    // 内部信号定义
    
    // 指令寄存器
    reg [`DATA_LEN-1:0] ir;
    assign inst = ir;
    
    // 流水线寄存器
    reg [`DATA_LEN-1:0] reg_data1;
    reg [`DATA_LEN-1:0] reg_data2;
    reg [`DATA_LEN-1:0] alu_out;
    reg [`DATA_LEN-1:0] mem_data;
    
    // 扩展立即数
    wire [`DATA_LEN-1:0] ext_imm;
    
    // ALU相关信号
    wire [`DATA_LEN-1:0] alu_a;
    wire [`DATA_LEN-1:0] alu_b;
    wire [`DATA_LEN-1:0] alu_result;
    wire zero;
    
    // 寄存器堆相关信号
    wire [`REG_ADDR_LEN-1:0] write_reg_addr;
    wire [`DATA_LEN-1:0] write_back_data;
    wire [`DATA_LEN-1:0] reg1_out;
    wire [`DATA_LEN-1:0] reg2_out;
    
    // PC相关信号
    wire [`ADDR_LEN-1:0] pc_next;
    wire [`ADDR_LEN-1:0] jump_addr;
    
    // 控制信号
    wire reg_dst_flag;
    wire alu_src_flag;
    wire mem_to_reg_flag;
    wire reg_write_flag;
    wire mem_read_flag;
    wire mem_write_flag;
    wire branch_flag;
    wire jump_flag;
    wire pc_write_flag;
    wire ir_write_flag;
    wire alu_out_write_flag;
    wire mem_data_write_flag;
    wire reg_data_write_flag;
    wire [`ALU_OPCODE] alu_op;
    wire [`ALU_SRC_A] alu_src_a;
    wire [`ALU_SRC_B] alu_src_b;
    wire [`PC_SRC] pc_src;
    
    // 指令存储器输出
    wire [`DATA_LEN-1:0] inst_mem_out;
    
    // 数据存储器输出
    wire [`DATA_LEN-1:0] mem_read_data;
    
    // 程序计数器模块
    pc pc_inst(
        .clk(clk),
        .rst(rst),
        .we(pc_write_flag),
        .in(pc_next),
        .out(pc)
    );
    
    // 指令存储器
    inst_memory inst_mem(
        .addr(pc),
        .inst(inst_mem_out)
    );
    
    // 指令寄存器写操作
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ir <= 32'h0;
        end else if (ir_write_flag) begin
            ir <= inst_mem_out;
        end
    end
    
    // 控制单元, 分析指令
    control_unit ctrl_unit(
        .clk(clk),
        .rst(rst),
        .opcode(ir[`OPCODE]),
        .funct(ir[`FUNCT]),
        .zero(zero),
        .reg_dst_flag(reg_dst_flag),
        .alu_src_flag(alu_src_flag),
        .mem_to_reg_flag(mem_to_reg_flag),
        .reg_write_flag(reg_write_flag),
        .mem_read_flag(mem_read_flag),
        .mem_write_flag(mem_write_flag),
        .branch_flag(branch_flag),
        .jump_flag(jump_flag),
        .pc_write_flag(pc_write_flag),
        .ir_write_flag(ir_write_flag),
        .alu_out_write_flag(alu_out_write_flag),
        .mem_data_write_flag(mem_data_write_flag),
        .reg_data_write_flag(reg_data_write_flag),
        .alu_op(alu_op),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .pc_src(pc_src)
    );
    
    // 寄存器堆
    register_file reg_file(
        .clk(clk),
        .rst(rst),
        .we(reg_write_flag),
        .raddr1(ir[`RS]),
        .raddr2(ir[`RT]),
        .waddr(write_reg_addr),
        .wdata(write_back_data),
        .rdata1(reg1_out),
        .rdata2(reg2_out)
    );
    
    // 寄存器数据寄存器写操作
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_data1 <= 32'h0;
            reg_data2 <= 32'h0;
        end else if (reg_data_write_flag) begin
            reg_data1 <= reg1_out;
            reg_data2 <= reg2_out;
        end
    end
    
    // 立即数符号扩展
    sign_extender sign_ext(
        .imm(ir[`IMM]),
        .ext_imm(ext_imm)
    );
    
    // ALU源操作数A选择器
    mux3 #(`DATA_LEN) alu_a_mux(
        .sel(alu_src_a),
        .in0(pc),
        .in1(reg_data1),
        .in2(32'h0),
        .out(alu_a)
    );
    
    // ALU源操作数B选择器
    mux4 #(`DATA_LEN) alu_b_mux(
        .sel(alu_src_b),
        .in0(32'h4),
        .in1(reg_data2),
        .in2(ext_imm),
        .in3(32'h0),
        .out(alu_b)
    );
    
    // ALU
    alu alu_inst(
        .a(alu_a),
        .b(alu_b),
        .alu_op(alu_op),
        .result(alu_result),
        .zero(zero)
    );
    
    // ALU输出寄存器写操作
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            alu_out <= 32'h0;
        end else if (alu_out_write_flag) begin
            alu_out <= alu_result;
        end
    end
    
    // 数据存储器
    data_memory data_mem(
        .clk(clk),
        .rst(rst),
        .mem_read_flag(mem_read_flag),
        .mem_write_flag(mem_write_flag),
        .addr(alu_out),
        .write_data(reg_data2),
        .read_data(mem_read_data)
    );
    
    // 内存数据寄存器写操作
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_data <= 32'h0;
        end else if (mem_data_write_flag) begin
            mem_data <= mem_read_data;
        end
    end
    
    // 写回数据选择器
    mux2 #(`DATA_LEN) write_back_mux(
        .sel(mem_to_reg_flag),
        .in0(alu_out),
        .in1(mem_data),
        .out(write_back_data)
    );
    
    // 写寄存器地址选择器
    mux2 #(`REG_ADDR_LEN) reg_dst_mux(
        .sel(reg_dst_flag),
        .in0(ir[`RT]),
        .in1(ir[`RD]),
        .out(write_reg_addr)
    );
    
    // 跳转地址计算
    assign jump_addr = {pc[31:28], ir[`J_ADDR], 2'b00};
    
    // PC下一地址选择器
    mux3 #(`ADDR_LEN) pc_mux(
        .sel(pc_src),
        .in0(alu_result),
        .in1(alu_out),
        .in2(jump_addr),
        .out(pc_next)
    );
    
endmodule