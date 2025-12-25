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
    
    // 指令锁存器，保存当前正在执行的指令
    reg [`DATA_LEN-1:0] inst_latch;
    
    // 中间结果锁存器
    reg [`DATA_LEN-1:0] reg1_data_latch;    // 寄存器1数据锁存
    reg [`DATA_LEN-1:0] reg2_data_latch;    // 寄存器2数据锁存
    reg [`DATA_LEN-1:0] ext_imm_latch;      // 符号扩展结果锁存
    reg [`DATA_LEN-1:0] alu_result_latch;   // ALU结果锁存
    reg [`DATA_LEN-1:0] mem_read_data_latch;// 存储器读数据锁存
    reg [`REG_ADDR_LEN-1:0] write_reg_addr_latch; // 写寄存器地址锁存
    
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
    
    // 指令锁存器，在取指阶段结束时锁存指令
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            inst_latch <= 32'b0;
        end
        else begin
            // 在取指阶段结束时锁存指令
            // 根据控制单元的状态，在IF阶段结束时锁存
            inst_latch <= inst;
        end
    end
    
    // 控制单元, 分析指令
    control_unit ctrl_unit(
        .clk(clk),
        .rst(rst),
        .opcode(inst_latch[`OPCODE]),
        .funct(inst_latch[`FUNCT]),
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
        .raddr1(inst_latch[`RS]),
        .raddr2(inst_latch[`RT]),
        .waddr(write_reg_addr_latch),
        .wdata(write_back_data),
        .rdata1(reg1_data),
        .rdata2(reg2_data)
    );
    
    // 立即数符号扩展
    sign_extender sign_ext(
        .imm(inst_latch[`IMM]),
        .ext_imm(ext_imm)
    );
    
    // 解码阶段锁存器，保存寄存器数据和符号扩展结果
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg1_data_latch <= 32'b0;
            reg2_data_latch <= 32'b0;
            ext_imm_latch <= 32'b0;
        end
        else begin
            // 在解码阶段结束时锁存数据
            reg1_data_latch <= reg1_data;
            reg2_data_latch <= reg2_data;
            ext_imm_latch <= ext_imm;
        end
    end
    
    // ALU 源操作数选择器
    mux2 #(`DATA_LEN) alu_src_mux(
        .sel(alu_src_flag),
        .in0(reg2_data_latch),
        .in1(ext_imm_latch),
        .out(alu_b)
    );
    
    // ALU
    alu alu_inst(
        .a(reg1_data_latch),
        .b(alu_b),
        .alu_op(alu_op),
        .result(alu_result),
        .zero(zero)
    );
    
    // 执行阶段锁存器，保存ALU结果和写寄存器地址
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            alu_result_latch <= 32'b0;
            write_reg_addr_latch <= 5'b0;
        end
        else begin
            // 在执行阶段结束时锁存数据
            alu_result_latch <= alu_result;
            write_reg_addr_latch <= write_reg_addr;
        end
    end
    
    // 数据存储器
    data_memory data_mem(
        .clk(clk),
        .rst(rst),
        .mem_read_flag(mem_read_flag),
        .mem_write_flag(mem_write_flag),
        .addr(alu_result_latch),
        .write_data(reg2_data_latch),
        .read_data(mem_read_data)
    );
    
    // 访存阶段锁存器，保存存储器读数据
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_read_data_latch <= 32'b0;
        end
        else begin
            // 在访存阶段结束时锁存数据
            mem_read_data_latch <= mem_read_data;
        end
    end
    
    // 写回数据选择器
    mux2 #(`DATA_LEN) write_back_mux(
        .sel(mem_to_reg_flag),
        .in0(alu_result_latch),
        .in1(mem_read_data_latch),
        .out(write_back_data)
    );
    
    // 写寄存器地址选择器
    mux2 #(`REG_ADDR_LEN) reg_dst_mux(
        .sel(reg_dst_flag),
        .in0(inst_latch[`RT]),
        .in1(inst_latch[`RD]),
        .out(write_reg_addr)
    );
    
    // 下一条地址选择, 没写mux3, 用2个mux2来实现
    // 分支目标地址计算
    assign branch_pc = pc + (ext_imm_latch << 2);
    mux2 #(`ADDR_LEN) branch_mux(
        .sel(branch_flag && zero),
        .in0(pc + 4),
        .in1(branch_pc),
        .out(next_pc_temp)
    );
    
    // 跳转目标地址计算
    assign jump_pc = {pc[31:28], inst_latch[`J_ADDR], 2'b00};
    mux2 #(`ADDR_LEN) jump_mux(
        .sel(jump_flag),
        .in0(next_pc_temp),
        .in1(jump_pc),
        .out(next_pc)
    );
    
endmodule