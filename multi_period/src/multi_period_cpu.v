`include "defines.v"

// 多周期CPU模块
module multi_period_cpu(
    input wire clk,                   // 时钟信号
    input wire rst,                   // 复位信号，高电平有效
    output wire [`ADDR_LEN-1:0] pc,   // 程序计数器
    output wire [`DATA_LEN-1:0] inst  // 当前执行的指令
);

    // 状态定义
    parameter [3:0] STATE_IF   = 4'b0001; // 取指阶段
    parameter [3:0] STATE_ID   = 4'b0010; // 译码阶段
    parameter [3:0] STATE_EX   = 4'b0100; // 执行阶段
    parameter [3:0] STATE_MEM  = 4'b1000; // 访存阶段
    parameter [3:0] STATE_WB   = 4'b1001; // 写回阶段

    // 状态寄存器
    reg [3:0] current_state;
    reg [3:0] next_state;

    // 流水线寄存器
    reg [`ADDR_LEN-1:0] pc_reg;            // PC寄存器
    reg [`DATA_LEN-1:0] inst_reg;          // 指令寄存器
    reg [`DATA_LEN-1:0] reg1_data_reg;     // 寄存器1数据
    reg [`DATA_LEN-1:0] reg2_data_reg;     // 寄存器2数据
    reg [`DATA_LEN-1:0] ext_imm_reg;       // 扩展后的立即数
    reg [`REG_ADDR_LEN-1:0] rt_reg;        // rt字段
    reg [`REG_ADDR_LEN-1:0] rd_reg;        // rd字段
    reg [`ALU_OPCODE] alu_op_reg;          // ALU操作码
    reg [`DATA_LEN-1:0] alu_result_reg;    // ALU结果
    reg zero_reg;                          // 零标志
    reg [`DATA_LEN-1:0] mem_read_data_reg; // 内存读取数据

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

    // 状态机的下一状态逻辑
    always @(*) begin
        case (current_state)
            STATE_IF: begin
                next_state = STATE_ID;
            end
            STATE_ID: begin
                next_state = STATE_EX;
            end
            STATE_EX: begin
                // 根据指令类型决定下一状态
                if (inst_reg[`OPCODE] == `OP_LW || inst_reg[`OPCODE] == `OP_SW) begin
                    next_state = STATE_MEM;
                end else if (inst_reg[`OPCODE] == `OP_R_TYPE || inst_reg[`OPCODE] == `OP_ADDI || inst_reg[`OPCODE] == `OP_ORI) begin
                    next_state = STATE_WB;
                end else if (inst_reg[`OPCODE] == `OP_BEQ || inst_reg[`OPCODE] == `OP_J) begin
                    next_state = STATE_IF; // 分支和跳转指令直接回到取指阶段
                end else begin
                    next_state = STATE_IF;
                end
            end
            STATE_MEM: begin
                if (inst_reg[`OPCODE] == `OP_LW) begin
                    next_state = STATE_WB;
                end else begin
                    next_state = STATE_IF; // SW指令执行完访存后直接回到取指阶段
                end
            end
            STATE_WB: begin
                next_state = STATE_IF;
            end
            default: begin
                next_state = STATE_IF;
            end
        endcase
    end

    // 状态机的状态寄存器更新
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= STATE_IF;
        end else begin
            current_state <= next_state;
        end
    end

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
        .opcode(inst_reg[`OPCODE]),
        .funct(inst_reg[`FUNCT]),
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
        .we(reg_write_flag && (current_state == STATE_WB)),
        .raddr1(inst_reg[`RS]),
        .raddr2(inst_reg[`RT]),
        .waddr(write_reg_addr),
        .wdata(write_back_data),
        .rdata1(reg1_data),
        .rdata2(reg2_data)
    );

    // 立即数符号扩展
    sign_extender sign_ext(
        .imm(inst_reg[`IMM]),
        .ext_imm(ext_imm)
    );

    // ALU 源操作数选择器
    mux2 #(`DATA_LEN) alu_src_mux(
        .sel(alu_src_flag),
        .in0(reg2_data_reg),
        .in1(ext_imm_reg),
        .out(alu_b)
    );

    // ALU
    alu alu_inst(
        .a(reg1_data_reg),
        .b(alu_b),
        .alu_op(alu_op_reg),
        .result(alu_result),
        .zero(zero)
    );

    // 数据存储器
    data_memory data_mem(
        .clk(clk),
        .rst(rst),
        .mem_read_flag(mem_read_flag && (current_state == STATE_MEM)),
        .mem_write_flag(mem_write_flag && (current_state == STATE_MEM)),
        .addr(alu_result_reg),
        .write_data(reg2_data_reg),
        .read_data(mem_read_data)
    );

    // 写回数据选择器
    mux2 #(`DATA_LEN) write_back_mux(
        .sel(mem_to_reg_flag),
        .in0(alu_result_reg),
        .in1(mem_read_data_reg),
        .out(write_back_data)
    );

    // 写寄存器地址选择器
    mux2 #(`REG_ADDR_LEN) reg_dst_mux(
        .sel(reg_dst_flag),
        .in0(rt_reg),
        .in1(rd_reg),
        .out(write_reg_addr)
    );

    // 下一条地址选择, 用2个mux2来实现
    // 分支目标地址计算
    assign branch_pc = pc_reg + (ext_imm_reg << 2);
    mux2 #(`ADDR_LEN) branch_mux(
        .sel(branch_flag && zero_reg),
        .in0(pc_reg + 4),
        .in1(branch_pc),
        .out(next_pc_temp)
    );

    // 跳转目标地址计算
    assign jump_pc = {pc_reg[31:28], inst_reg[`J_ADDR], 2'b00};
    mux2 #(`ADDR_LEN) jump_mux(
        .sel(jump_flag),
        .in0(next_pc_temp),
        .in1(jump_pc),
        .out(next_pc)
    );

    // 状态机控制的数据通路
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_reg            <= 32'b0;
            inst_reg          <= 32'b0;
            reg1_data_reg     <= 32'b0;
            reg2_data_reg     <= 32'b0;
            ext_imm_reg       <= 32'b0;
            rt_reg            <= 5'b0;
            rd_reg            <= 5'b0;
            alu_op_reg        <= `ALU_DEFAULT;
            alu_result_reg    <= 32'b0;
            zero_reg          <= 1'b0;
            mem_read_data_reg <= 32'b0;
        end else begin
            case (current_state)
                STATE_IF: begin
                    // 取指阶段：将PC值和指令存入寄存器
                    pc_reg <= pc;
                    inst_reg <= inst;
                end
                
                STATE_ID: begin
                    // 译码阶段：读取寄存器，扩展立即数，保存相关字段
                    reg1_data_reg <= reg1_data;
                    reg2_data_reg <= reg2_data;
                    ext_imm_reg <= ext_imm;
                    rt_reg <= inst_reg[`RT];
                    rd_reg <= inst_reg[`RD];
                    alu_op_reg <= alu_op;
                end
                
                STATE_EX: begin
                    // 执行阶段：保存ALU结果和零标志
                    alu_result_reg <= alu_result;
                    zero_reg <= zero;
                end
                
                STATE_MEM: begin
                    // 访存阶段：保存内存读取数据
                    if (mem_read_flag) begin
                        mem_read_data_reg <= mem_read_data;
                    end
                end
                
                STATE_WB: begin
                    // 写回阶段：数据已经通过write_back_data写回寄存器，无需额外操作
                end
            endcase
        end
    end

    // 输出当前PC和指令
    assign pc = pc_reg;
    assign inst = inst_reg;

endmodule