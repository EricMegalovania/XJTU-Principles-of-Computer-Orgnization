`include "defines.v"

module multi_period_cpu(
    input wire clk,                   // 时钟信号
    input wire rst,                   // 复位信号，高电平有效
    output wire [`ADDR_LEN-1:0] pc,   // 程序计数器
    output wire [`DATA_LEN-1:0] inst  // 当前执行的指令
);

    // 状态定义
    localparam IF  = 3'b000;  // 取指阶段
    localparam ID  = 3'b001;  // 译码阶段  
    localparam EX  = 3'b010;  // 执行阶段
    localparam MEM = 3'b011;  // 存储器访问阶段
    localparam WB  = 3'b100;  // 写回阶段
    
    reg [2:0] current_state;
    reg [2:0] next_state;
    
    // 阶段间寄存器
    reg [`ADDR_LEN-1:0] pc_reg;
    reg [`DATA_LEN-1:0] inst_reg;
    reg [`DATA_LEN-1:0] reg1_data_reg;
    reg [`DATA_LEN-1:0] reg2_data_reg;
    reg [`DATA_LEN-1:0] ext_imm_reg;
    reg [`DATA_LEN-1:0] alu_result_reg;
    reg [`DATA_LEN-1:0] mem_read_data_reg;
    reg [`REG_ADDR_LEN-1:0] write_reg_addr_reg;
    
    // 控制信号寄存器
    reg reg_dst_flag_reg;
    reg alu_src_flag_reg;
    reg mem_to_reg_flag_reg;
    reg reg_write_flag_reg;
    reg mem_read_flag_reg;
    reg mem_write_flag_reg;
    reg branch_flag_reg;
    reg jump_flag_reg;
    reg [`ALU_OPCODE] alu_op_reg;
    
    // 内部信号
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
    wire zero;
    
    // 控制信号
    wire reg_dst_flag;
    wire alu_src_flag;
    wire mem_to_reg_flag;
    wire reg_write_flag;
    wire mem_read_flag;
    wire mem_write_flag;
    wire branch_flag;
    wire jump_flag;
    wire [`ALU_OPCODE] alu_op;
    
    // 状态机
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IF;
        end else begin
            current_state <= next_state;
        end
    end
    
    // 下一状态逻辑
    always @(*) begin
        case (current_state)
            IF: next_state = ID;
            ID: next_state = EX;
            EX: begin
                if (mem_read_flag_reg || mem_write_flag_reg) begin
                    next_state = MEM;
                end else if (reg_write_flag_reg) begin
                    next_state = WB;
                end else begin
                    next_state = IF;  // 对于跳转指令，直接回到IF
                end
            end
            MEM: next_state = WB;
            WB: next_state = IF;
            default: next_state = IF;
        endcase
    end
    
    // 阶段寄存器更新
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_reg <= 0;
            inst_reg <= 0;
            reg1_data_reg <= 0;
            reg2_data_reg <= 0;
            ext_imm_reg <= 0;
            alu_result_reg <= 0;
            mem_read_data_reg <= 0;
            write_reg_addr_reg <= 0;
            
            // 控制信号寄存器清零
            reg_dst_flag_reg <= 0;
            alu_src_flag_reg <= 0;
            mem_to_reg_flag_reg <= 0;
            reg_write_flag_reg <= 0;
            mem_read_flag_reg <= 0;
            mem_write_flag_reg <= 0;
            branch_flag_reg <= 0;
            jump_flag_reg <= 0;
            alu_op_reg <= 0;
        end else begin
            case (current_state)
                IF: begin
                    inst_reg <= inst;
                    pc_reg <= pc;
                end
                ID: begin
                    reg1_data_reg <= reg1_data;
                    reg2_data_reg <= reg2_data;
                    ext_imm_reg <= ext_imm;
                    write_reg_addr_reg <= write_reg_addr;
                    
                    // 锁存控制信号
                    reg_dst_flag_reg <= reg_dst_flag;
                    alu_src_flag_reg <= alu_src_flag;
                    mem_to_reg_flag_reg <= mem_to_reg_flag;
                    reg_write_flag_reg <= reg_write_flag;
                    mem_read_flag_reg <= mem_read_flag;
                    mem_write_flag_reg <= mem_write_flag;
                    branch_flag_reg <= branch_flag;
                    jump_flag_reg <= jump_flag;
                    alu_op_reg <= alu_op;
                end
                EX: begin
                    alu_result_reg <= alu_result;
                end
                MEM: begin
                    mem_read_data_reg <= mem_read_data;
                end
            endcase
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
    
    // 控制单元
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
        .we(current_state == WB && reg_write_flag_reg),  // 只在WB阶段写寄存器
        .raddr1(inst_reg[`RS]),
        .raddr2(inst_reg[`RT]),
        .waddr(write_reg_addr_reg),
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
        .sel(alu_src_flag_reg),
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
        .mem_read_flag(current_state == MEM && mem_read_flag_reg),
        .mem_write_flag(current_state == MEM && mem_write_flag_reg),
        .addr(alu_result_reg),
        .write_data(reg2_data_reg),
        .read_data(mem_read_data)
    );
    
    // 写回数据选择器
    mux2 #(`DATA_LEN) write_back_mux(
        .sel(mem_to_reg_flag_reg),
        .in0(alu_result_reg),
        .in1(mem_read_data_reg),
        .out(write_back_data)
    );
    
    // 写寄存器地址选择器
    mux2 #(`REG_ADDR_LEN) reg_dst_mux(
        .sel(reg_dst_flag_reg),
        .in0(inst_reg[`RT]),
        .in1(inst_reg[`RD]),
        .out(write_reg_addr)
    );
    
    // 下一条PC计算
    assign branch_pc = pc_reg + (ext_imm_reg << 2);
    mux2 #(`ADDR_LEN) branch_mux(
        .sel((current_state == EX) && branch_flag_reg && zero),
        .in0(pc_reg + 4),
        .in1(branch_pc),
        .out(next_pc_temp)
    );
    
    assign jump_pc = {pc_reg[31:28], inst_reg[`J_ADDR], 2'b00};
    mux2 #(`ADDR_LEN) jump_mux(
        .sel((current_state == EX) && jump_flag_reg),
        .in0(next_pc_temp),
        .in1(jump_pc),
        .out(next_pc)
    );
    
    // 输出当前指令
    assign inst = inst_reg;
    
endmodule