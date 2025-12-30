`include "defines.v"

// 流水线CPU顶层模块
module pipelined_cpu(
    input wire clk,
    input wire rst,
    output wire [`ADDR_LEN-1:0] pc,
    output wire [`INSTR_LEN-1:0] inst
);

    // ==================== 流水线寄存器定义 ====================
    // IF/ID 流水线寄存器
    reg [`ADDR_LEN-1:0] if_id_pc_plus_4;
    reg [`INSTR_LEN-1:0] if_id_inst;
    reg if_id_valid;
    
    // ID/EX 流水线寄存器
    reg [`ADDR_LEN-1:0] id_ex_pc_plus_4;
    reg id_ex_reg_write_flag;
    reg id_ex_mem_to_reg_flag;
    reg id_ex_branch_flag;
    reg id_ex_mem_read_flag;
    reg id_ex_mem_write_flag;
    reg id_ex_alu_src_flag;
    reg id_ex_reg_dst_flag;
    reg id_ex_jump_flag;
    reg [`ALU_OPCODE] id_ex_alu_op;
    reg [`DATA_LEN-1:0] id_ex_read_data1;
    reg [`DATA_LEN-1:0] id_ex_read_data2;
    reg [`DATA_LEN-1:0] id_ex_imm_ext;
    reg [`REG_ADDR_LEN-1:0] id_ex_rt;
    reg [`REG_ADDR_LEN-1:0] id_ex_rd;
    reg [`REG_ADDR_LEN-1:0] id_ex_rs;
    reg id_ex_valid;
    reg [`REG_ADDR_LEN-1:0] id_ex_write_reg_addr;
    
    // EX/MEM 流水线寄存器
    reg ex_mem_reg_write_flag;
    reg ex_mem_mem_to_reg_flag;
    reg ex_mem_branch_flag;
    reg ex_mem_mem_read_flag;
    reg ex_mem_mem_write_flag;
    reg ex_mem_jump_flag;
    reg [`DATA_LEN-1:0] ex_mem_alu_result;
    reg [`DATA_LEN-1:0] ex_mem_read_data2;
    reg [`REG_ADDR_LEN-1:0] ex_mem_write_reg_addr;
    reg [`ADDR_LEN-1:0] ex_mem_pc_plus_4;
    reg [`DATA_LEN-1:0] ex_mem_branch_target;
    reg ex_mem_zero;
    reg ex_mem_valid;
    
    // MEM/WB 流水线寄存器
    reg mem_wb_reg_write_flag;
    reg mem_wb_mem_to_reg_flag;
    reg [`DATA_LEN-1:0] mem_wb_alu_result;
    reg [`DATA_LEN-1:0] mem_wb_mem_read_data;
    reg [`REG_ADDR_LEN-1:0] mem_wb_write_reg_addr;
    reg mem_wb_valid;

    // ==================== 信号定义 ====================
    // PC相关信号
    reg [`ADDR_LEN-1:0] pc_reg;
    wire [`ADDR_LEN-1:0] next_pc;
    reg pc_write;  // PC写使能，用于流水线暂停
    
    // 冒险检测信号
    reg stall_if;
    reg stall_id;
    reg flush_id;
    reg flush_ex;
    
    // 数据存储器接口信号
    wire [`DATA_LEN-1:0] mem_read_data;
    
    // 寄存器文件接口信号
    wire [`DATA_LEN-1:0] reg_read_data1;
    wire [`DATA_LEN-1:0] reg_read_data2;
    
    // ALU接口信号
    wire [`DATA_LEN-1:0] alu_result;
    wire alu_zero;
    
    // 其他中间信号
    wire [`ADDR_LEN-1:0] pc_plus_4;
    wire [`DATA_LEN-1:0] imm_ext;
    wire [`DATA_LEN-1:0] ex_branch_target;  // EX阶段计算的分支目标地址
    
    // 控制单元信号
    wire reg_dst_flag;
    wire alu_src_flag;
    wire mem_to_reg_flag;
    wire reg_write_flag;
    wire mem_read_flag;
    wire mem_write_flag;
    wire branch_flag;
    wire jump_flag;
    wire [`ALU_OPCODE] alu_op;
    
    // 写回寄存器地址选择信号
    wire [`REG_ADDR_LEN-1:0] id_write_reg_addr;
    
    // ==================== 冒险检测单元 ====================
    // 完整的冒险检测逻辑
    wire data_hazard;
    wire load_use_hazard;
    wire control_hazard;
    
    // 检测EX阶段的数据冒险
    wire data_hazard_ex;
    assign data_hazard_ex = (id_ex_valid && id_ex_reg_write_flag && id_ex_write_reg_addr != 0) &&
                           ((id_ex_write_reg_addr == if_id_inst[`RS]) || 
                            (id_ex_write_reg_addr == if_id_inst[`RT]));
    
    // 检测MEM阶段的数据冒险
    wire data_hazard_mem;
    assign data_hazard_mem = (ex_mem_valid && ex_mem_reg_write_flag && ex_mem_write_reg_addr != 0) &&
                            ((ex_mem_write_reg_addr == if_id_inst[`RS]) || 
                             (ex_mem_write_reg_addr == if_id_inst[`RT]));
    
    // 检测WB阶段的数据冒险（写回正在进行）
    wire data_hazard_wb;
    assign data_hazard_wb = (mem_wb_valid && mem_wb_reg_write_flag && mem_wb_write_reg_addr != 0) &&
                           ((mem_wb_write_reg_addr == if_id_inst[`RS]) || 
                            (mem_wb_write_reg_addr == if_id_inst[`RT]));
    
    // 总的数据冒险
    assign data_hazard = data_hazard_ex || data_hazard_mem || data_hazard_wb;
    
    // load-use冒险：特殊的load指令数据冒险
    assign load_use_hazard = (id_ex_valid && id_ex_mem_read_flag && id_ex_write_reg_addr != 0) &&
                            ((id_ex_write_reg_addr == if_id_inst[`RS]) || 
                             (id_ex_write_reg_addr == if_id_inst[`RT]));
    
    // 控制冒险：分支/跳转指令
    assign control_hazard = (id_ex_valid && (id_ex_branch_flag || id_ex_jump_flag)) ||
                            (ex_mem_valid && (ex_mem_branch_flag || ex_mem_jump_flag));
    
    // 流水线控制信号
    always @(*) begin
        stall_if = 1'b0;
        stall_id = 1'b0;
        flush_id = 1'b0;
        flush_ex = 1'b0;
        pc_write = 1'b1;
        
        // load-use冒险：暂停流水线
        if (load_use_hazard) begin
            stall_if = 1'b1;
            stall_id = 1'b1;
            pc_write = 1'b0;
        end
        // 数据冒险：暂停流水线
        else if (data_hazard) begin
            stall_if = 1'b1;
            stall_id = 1'b1;
            pc_write = 1'b0;
        end
        // 控制冒险：清空流水线
        if (control_hazard && id_ex_valid) begin
            flush_id = 1'b1;
            flush_ex = 1'b1;
        end
    end
    
    // ==================== IF阶段 ====================
    assign pc = pc_reg;
    assign pc_plus_4 = pc_reg + 32'd4;
    
    // PC更新
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_reg <= 32'b0;
        end
        else if (pc_write) begin
            if (ex_mem_valid && ex_mem_jump_flag) begin
                // 跳转指令
                pc_reg <= {ex_mem_pc_plus_4[31:28], if_id_inst[`J_ADDR], 2'b00};
            end
            else if (ex_mem_valid && ex_mem_branch_flag && ex_mem_zero) begin
                // 分支指令
                pc_reg <= ex_mem_branch_target;
            end
            else begin
                pc_reg <= pc_plus_4;
            end
        end
    end
    
    // 指令存储器
    inst_memory inst_mem(
        .addr(pc_reg),
        .inst(inst)
    );
    
    // IF/ID流水线寄存器更新
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            if_id_pc_plus_4 <= 32'b0;
            if_id_inst <= 32'b0;
            if_id_valid <= 1'b0;
        end
        else if (stall_if) begin
            // 暂停：保持原值
            if_id_pc_plus_4 <= if_id_pc_plus_4;
            if_id_inst <= if_id_inst;
            if_id_valid <= if_id_valid;
        end
        else if (flush_id) begin
            // 清空：插入气泡
            if_id_pc_plus_4 <= 32'b0;
            if_id_inst <= 32'b0;
            if_id_valid <= 1'b0;
        end
        else begin
            // 正常更新
            if_id_pc_plus_4 <= pc_plus_4;
            if_id_inst <= inst;
            if_id_valid <= 1'b1;
        end
    end
    
    // ==================== ID阶段 ====================
    // 控制单元
    control_unit ctrl_unit(
        .opcode(if_id_inst[`OPCODE]),
        .funct(if_id_inst[`FUNCT]),
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
    
    // 写回寄存器地址选择（ID阶段）
    assign id_write_reg_addr = reg_dst_flag ? if_id_inst[`RD] : if_id_inst[`RT];
    
    // 写回数据选择
    wire [`DATA_LEN-1:0] write_back_data;
    assign write_back_data = mem_wb_mem_to_reg_flag ? mem_wb_mem_read_data : mem_wb_alu_result;
    
    // 寄存器文件
    register_file reg_file(
        .clk(clk),
        .rst(rst),
        .we(mem_wb_valid && mem_wb_reg_write_flag),
        .raddr1(if_id_inst[`RS]),
        .raddr2(if_id_inst[`RT]),
        .waddr(mem_wb_write_reg_addr),
        .wdata(write_back_data),
        .rdata1(reg_read_data1),
        .rdata2(reg_read_data2)
    );
    
    // 符号扩展器
    sign_extender sign_ext(
        .imm(if_id_inst[`IMM]),
        .ext_imm(imm_ext)
    );
    
    // ID/EX流水线寄存器更新
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            id_ex_pc_plus_4 <= 32'b0;
            id_ex_reg_write_flag <= 1'b0;
            id_ex_mem_to_reg_flag <= 1'b0;
            id_ex_branch_flag <= 1'b0;
            id_ex_mem_read_flag <= 1'b0;
            id_ex_mem_write_flag <= 1'b0;
            id_ex_alu_src_flag <= 1'b0;
            id_ex_reg_dst_flag <= 1'b0;
            id_ex_jump_flag <= 1'b0;
            id_ex_alu_op <= `ALU_DEFAULT;
            id_ex_read_data1 <= 32'b0;
            id_ex_read_data2 <= 32'b0;
            id_ex_imm_ext <= 32'b0;
            id_ex_rt <= 5'b0;
            id_ex_rd <= 5'b0;
            id_ex_rs <= 5'b0;
            id_ex_valid <= 1'b0;
            id_ex_write_reg_addr <= 5'b0;
        end
        else if (stall_id) begin
            // 暂停：插入气泡
            id_ex_pc_plus_4 <= 32'b0;
            id_ex_reg_write_flag <= 1'b0;
            id_ex_mem_to_reg_flag <= 1'b0;
            id_ex_branch_flag <= 1'b0;
            id_ex_mem_read_flag <= 1'b0;
            id_ex_mem_write_flag <= 1'b0;
            id_ex_alu_src_flag <= 1'b0;
            id_ex_reg_dst_flag <= 1'b0;
            id_ex_jump_flag <= 1'b0;
            id_ex_alu_op <= `ALU_DEFAULT;
            id_ex_read_data1 <= 32'b0;
            id_ex_read_data2 <= 32'b0;
            id_ex_imm_ext <= 32'b0;
            id_ex_rt <= 5'b0;
            id_ex_rd <= 5'b0;
            id_ex_rs <= 5'b0;
            id_ex_valid <= 1'b0;
            id_ex_write_reg_addr <= 5'b0;
        end
        else if (flush_ex) begin
            // 清空：插入气泡
            id_ex_pc_plus_4 <= 32'b0;
            id_ex_reg_write_flag <= 1'b0;
            id_ex_mem_to_reg_flag <= 1'b0;
            id_ex_branch_flag <= 1'b0;
            id_ex_mem_read_flag <= 1'b0;
            id_ex_mem_write_flag <= 1'b0;
            id_ex_alu_src_flag <= 1'b0;
            id_ex_reg_dst_flag <= 1'b0;
            id_ex_jump_flag <= 1'b0;
            id_ex_alu_op <= `ALU_DEFAULT;
            id_ex_read_data1 <= 32'b0;
            id_ex_read_data2 <= 32'b0;
            id_ex_imm_ext <= 32'b0;
            id_ex_rt <= 5'b0;
            id_ex_rd <= 5'b0;
            id_ex_rs <= 5'b0;
            id_ex_valid <= 1'b0;
            id_ex_write_reg_addr <= 5'b0;
        end
        else begin
            // 正常更新
            id_ex_pc_plus_4 <= if_id_pc_plus_4;
            id_ex_reg_write_flag <= reg_write_flag;
            id_ex_mem_to_reg_flag <= mem_to_reg_flag;
            id_ex_branch_flag <= branch_flag;
            id_ex_mem_read_flag <= mem_read_flag;
            id_ex_mem_write_flag <= mem_write_flag;
            id_ex_alu_src_flag <= alu_src_flag;
            id_ex_reg_dst_flag <= reg_dst_flag;
            id_ex_jump_flag <= jump_flag;
            id_ex_alu_op <= alu_op;
            id_ex_read_data1 <= reg_read_data1;
            id_ex_read_data2 <= reg_read_data2;
            id_ex_imm_ext <= imm_ext;
            id_ex_rt <= if_id_inst[`RT];
            id_ex_rd <= if_id_inst[`RD];
            id_ex_rs <= if_id_inst[`RS];
            id_ex_valid <= if_id_valid;
            id_ex_write_reg_addr <= id_write_reg_addr;
        end
    end
    
    // ==================== EX阶段 ====================
    // ALU第二个操作数选择
    wire [`DATA_LEN-1:0] alu_src_b;
    assign alu_src_b = id_ex_alu_src_flag ? id_ex_imm_ext : id_ex_read_data2;
    
    // ALU
    alu alu_unit(
        .a(id_ex_read_data1),
        .b(alu_src_b),
        .alu_op(id_ex_alu_op),
        .result(alu_result),
        .zero(alu_zero)
    );
    
    // 分支目标地址计算
    assign ex_branch_target = id_ex_pc_plus_4 + {id_ex_imm_ext[29:0], 2'b00};
    
    // 写回寄存器地址选择（EX阶段）
    wire [`REG_ADDR_LEN-1:0] ex_write_reg_addr;
    assign ex_write_reg_addr = id_ex_write_reg_addr;
    
    // EX/MEM流水线寄存器更新
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ex_mem_reg_write_flag <= 1'b0;
            ex_mem_mem_to_reg_flag <= 1'b0;
            ex_mem_branch_flag <= 1'b0;
            ex_mem_mem_read_flag <= 1'b0;
            ex_mem_mem_write_flag <= 1'b0;
            ex_mem_jump_flag <= 1'b0;
            ex_mem_alu_result <= 32'b0;
            ex_mem_read_data2 <= 32'b0;
            ex_mem_write_reg_addr <= 5'b0;
            ex_mem_pc_plus_4 <= 32'b0;
            ex_mem_branch_target <= 32'b0;
            ex_mem_zero <= 1'b0;
            ex_mem_valid <= 1'b0;
        end
        else begin
            ex_mem_reg_write_flag <= id_ex_reg_write_flag;
            ex_mem_mem_to_reg_flag <= id_ex_mem_to_reg_flag;
            ex_mem_branch_flag <= id_ex_branch_flag;
            ex_mem_mem_read_flag <= id_ex_mem_read_flag;
            ex_mem_mem_write_flag <= id_ex_mem_write_flag;
            ex_mem_jump_flag <= id_ex_jump_flag;
            ex_mem_alu_result <= alu_result;
            ex_mem_read_data2 <= id_ex_read_data2;
            ex_mem_write_reg_addr <= ex_write_reg_addr;
            ex_mem_pc_plus_4 <= id_ex_pc_plus_4;
            ex_mem_branch_target <= ex_branch_target;
            ex_mem_zero <= alu_zero;
            ex_mem_valid <= id_ex_valid;
        end
    end
    
    // ==================== MEM阶段 ====================
    // 数据存储器
    data_memory data_mem(
        .clk(clk),
        .rst(rst),
        .mem_read_flag(ex_mem_mem_read_flag),
        .mem_write_flag(ex_mem_mem_write_flag),
        .addr(ex_mem_alu_result),
        .write_data(ex_mem_read_data2),
        .read_data(mem_read_data)
    );
    
    // MEM/WB流水线寄存器更新
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_wb_reg_write_flag <= 1'b0;
            mem_wb_mem_to_reg_flag <= 1'b0;
            mem_wb_alu_result <= 32'b0;
            mem_wb_mem_read_data <= 32'b0;
            mem_wb_write_reg_addr <= 5'b0;
            mem_wb_valid <= 1'b0;
        end
        else begin
            mem_wb_reg_write_flag <= ex_mem_reg_write_flag;
            mem_wb_mem_to_reg_flag <= ex_mem_mem_to_reg_flag;
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_mem_read_data <= mem_read_data;
            mem_wb_write_reg_addr <= ex_mem_write_reg_addr;
            mem_wb_valid <= ex_mem_valid;
        end
    end
    
    // ==================== WB阶段 ====================
    // WB阶段的逻辑已经在ID阶段中实现（写回数据选择和写回寄存器选择）
    
endmodule