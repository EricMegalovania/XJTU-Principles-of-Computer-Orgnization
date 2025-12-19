`timescale 1ns / 1ps

module single_cycle_cpu (
    input wire clk,
    input wire rst
);

    // 内部信号定义
    wire [31:0] pc_out;
    wire [31:0] pc_next;
    wire [31:0] pc_plus4;
    wire [31:0] inst;
    wire [31:0] jump_addr;
    wire [31:0] branch_addr;
    wire [31:0] alu_in1;
    wire [31:0] alu_in2;
    wire [31:0] alu_out;
    wire [31:0] rd1;
    wire [31:0] rd2;
    wire [31:0] sign_extended;
    wire [31:0] mem_read_data;
    wire [31:0] write_data;
    wire [31:0] branch_target;
    wire [31:0] branch_plus4;
    wire [4:0] write_reg;
    wire [3:0] alu_op;
    wire reg_dst;
    wire jump;
    wire branch;
    wire mem_read;
    wire mem_to_reg;
    wire mem_write;
    wire alu_src;
    wire reg_write;
    wire zero;
    wire branch_taken;

    // 实例化PC模块
    pc pc_inst (
        .clk(clk),
        .rst(rst),
        .pc_next(pc_next),
        .pc_out(pc_out)
    );

    // 实例化指令存储器
    inst_mem inst_mem_inst (
        .addr(pc_out),
        .inst(inst)
    );

    // 实例化寄存器堆
    reg_file reg_file_inst (
        .clk(clk),
        .we3(reg_write),
        .ra1(inst[25:21]),
        .ra2(inst[20:16]),
        .wa3(write_reg),
        .wd3(write_data),
        .rd1(rd1),
        .rd2(rd2)
    );

    // ALU输入选择，特别是移位操作需要使用shamt字段
    assign alu_in1 = (inst[31:26] == 6'b000000) && ((inst[5:0] == 6'b000000) || (inst[5:0] == 6'b000010) || (inst[5:0] == 6'b000011)) ? {27'b0, inst[10:6]} : rd1;

    // 实例化ALU
    alu alu_inst (
        .a(alu_in1),
        .b(alu_in2),
        .alu_control(alu_op),
        .result(alu_out),
        .zero(zero)
    );

    // 实例化数据存储器
    data_mem data_mem_inst (
        .clk(clk),
        .we(mem_write),
        .addr(alu_out),
        .wd(rd2),
        .rd(mem_read_data)
    );

    // 实例化控制单元
    control control_inst (
        .opcode(inst[31:26]),
        .funct(inst[5:0]),
        .reg_dst(reg_dst),
        .jump(jump),
        .branch(branch),
        .mem_read(mem_read),
        .mem_to_reg(mem_to_reg),
        .alu_op(alu_op),
        .mem_write(mem_write),
        .alu_src(alu_src),
        .reg_write(reg_write)
    );

    // 程序计数器逻辑
    assign pc_plus4 = pc_out + 32'd4;
    assign jump_addr = {pc_plus4[31:28], inst[25:0], 2'b00};
    assign sign_extended = {{16{inst[15]}}, inst[15:0]};
    assign branch_target = pc_plus4 + (sign_extended << 2);
    assign branch_taken = branch & zero;
    assign branch_plus4 = branch_taken ? branch_target : pc_plus4;
    assign pc_next = jump ? jump_addr : branch_plus4;

    // ALU输入选择
    assign alu_in2 = alu_src ? sign_extended : rd2;

    // 写寄存器选择
    assign write_reg = reg_dst ? inst[15:11] : inst[20:16];

    // 写数据选择
    assign write_data = mem_to_reg ? mem_read_data : alu_out;

endmodule