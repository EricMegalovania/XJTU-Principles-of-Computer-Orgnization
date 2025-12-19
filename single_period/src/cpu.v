// CPU顶层模块
// 连接所有子模块，形成完整的数据通路

`include "defines.v"

module cpu (
    input  wire                     clk,      // 时钟信号
    input  wire                     rst,      // 复位信号
    output wire [`ADDR_LEN-1:0]     pc_out,   // 程序计数器输出（用于调试）
    output wire [`INSTR_LEN-1:0]    instr_out // 指令输出（用于调试）
);

    // 信号定义
    // PC相关信号
    wire [`ADDR_LEN-1:0]     pc;
    wire [`ADDR_LEN-1:0]     pc_next;
    wire                     branch;
    wire                     jump;
    wire                     zero;
    wire [`ADDR_LEN-1:0]     imm_ext;
    wire [`J_ADDR]           j_addr;

    // 指令存储器相关信号
    wire [`INSTR_LEN-1:0]    instr;

    // 控制单元相关信号
    wire                     reg_we;
    wire                     mem_we;
    wire [1:0]               reg_dst;
    wire                     alu_src;
    wire [1:0]               mem_to_reg;
    wire [3:0]               alu_op;
    wire                     sign_ext;

    // 寄存器堆相关信号
    wire [`REG_ADDR_LEN-1:0] r_addr1;
    wire [`REG_ADDR_LEN-1:0] r_addr2;
    wire [`DATA_LEN-1:0]     r_data1;
    wire [`DATA_LEN-1:0]     r_data2;
    wire [`REG_ADDR_LEN-1:0] w_addr;
    wire [`DATA_LEN-1:0]     w_data;

    // ALU相关信号
    wire [`DATA_LEN-1:0]     alu_a;
    wire [`DATA_LEN-1:0]     alu_b;
    wire [`DATA_LEN-1:0]     alu_result;
    wire [`REG_ADDR_LEN-1:0] shamt;

    // 数据存储器相关信号
    wire [`DATA_LEN-1:0]     mem_r_data;

    // 立即数扩展
    wire [15:0]              imm;
    assign imm = instr[15:0];
    assign imm_ext = sign_ext ? {{16{imm[15]}}, imm} : {{16{1'b0}}, imm};

    // 跳转地址提取
    assign j_addr = instr[`J_ADDR];

    // 寄存器堆地址和数据选择
    // 读地址直接从指令中提取
    assign r_addr1 = instr[`RS];
    assign r_addr2 = instr[`RT];
    assign shamt = instr[`SHAMT];

    // 寄存器写地址选择
    mux3 #(`REG_ADDR_LEN) reg_dst_mux (
        .a(instr[`RT]),        // I型指令：rt
        .b(instr[`RD]),        // R型指令：rd
        .c(5'd31),             // jal指令：$ra（未实现，预留）
        .sel(reg_dst),         // 选择信号
        .y(w_addr)             // 输出
    );

    // ALU第二个操作数选择
    mux2 #(`DATA_LEN) alu_src_mux (
        .a(r_data2),           // 来自寄存器rt
        .b(imm_ext),           // 来自扩展后的立即数
        .sel(alu_src),         // 选择信号
        .y(alu_b)              // 输出
    );

    // 寄存器写数据选择
    mux3 #(`DATA_LEN) mem_to_reg_mux (
        .a(alu_result),        // 来自ALU运算结果
        .b(mem_r_data),        // 来自数据存储器
        .c(pc + 4),            // 来自PC+4（未实现，预留）
        .sel(mem_to_reg),      // 选择信号
        .y(w_data)             // 输出
    );

    // 子模块实例化
    // 程序计数器
    program_counter pc_module (
        .clk(clk),
        .rst(rst),
        .branch(branch),
        .jump(jump),
        .zero(zero),
        .imm_ext(imm_ext),
        .j_addr(j_addr),
        .pc(pc)
    );

    // 指令存储器
    instruction_memory imem (
        .addr(pc),
        .instr(instr)
    );

    // 控制单元
    control_unit ctrl_unit (
        .instr(instr),
        .reg_we(reg_we),
        .mem_we(mem_we),
        .branch(branch),
        .jump(jump),
        .reg_dst(reg_dst),
        .alu_src(alu_src),
        .mem_to_reg(mem_to_reg),
        .alu_op(alu_op),
        .sign_ext(sign_ext)
    );

    // 寄存器堆
    register_file reg_file (
        .clk(clk),
        .rst(rst),
        .we(reg_we),
        .w_addr(w_addr),
        .w_data(w_data),
        .r_addr1(r_addr1),
        .r_addr2(r_addr2),
        .r_data1(r_data1),
        .r_data2(r_data2)
    );

    // ALU运算模块
    alu alu_module (
        .a(r_data1),
        .b(alu_b),
        .alu_op(alu_op),
        .shamt(shamt),
        .result(alu_result),
        .zero(zero)
    );

    // 数据存储器
    data_memory dmem (
        .clk(clk),
        .rst(rst),
        .we(mem_we),
        .addr(alu_result),
        .w_data(r_data2),
        .r_data(mem_r_data)
    );

    // 输出调试信号
    assign pc_out = pc;
    assign instr_out = instr;

endmodule

// 2选1多路选择器
module mux2 #(parameter WIDTH = 32) (
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire             sel,
    output wire [WIDTH-1:0] y
);
    assign y = sel ? b : a;
endmodule

// 3选1多路选择器
module mux3 #(parameter WIDTH = 32) (
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire [WIDTH-1:0] c,
    input  wire [1:0]       sel,
    output wire [WIDTH-1:0] y
);
    assign y = sel[1] ? c : (sel[0] ? b : a);
endmodule
