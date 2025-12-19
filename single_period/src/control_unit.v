// 控制单元模块
// 根据指令生成各种控制信号

`include "defines.v"

module control_unit (
    input  wire [`INSTR_LEN-1:0]     instr,     // 输入指令
    output reg                       reg_we,    // 寄存器堆写使能
    output reg                       mem_we,    // 数据存储器写使能
    output reg                       branch,    // 分支信号
    output reg                       jump,      // 跳转信号
    output reg [1:0]                 reg_dst,   // 寄存器堆写地址选择
    output reg                       alu_src,   // ALU第二个操作数选择
    output reg [1:0]                 mem_to_reg,// 寄存器堆写数据来源选择
    output reg [3:0]                 alu_op,    // ALU操作类型
    output reg                       sign_ext   // 立即数符号扩展控制
);

    // 指令的opcode和funct字段
    wire [5:0] opcode;
    wire [5:0] funct;

    assign opcode = instr[`OPCODE];
    assign funct = instr[`FUNCT];

    // 控制信号生成
    always @(*) begin
        // 默认控制信号
        reg_we = 1'b0;
        mem_we = 1'b0;
        branch = 1'b0;
        jump = 1'b0;
        reg_dst = 2'b00;
        alu_src = 1'b0;
        mem_to_reg = 2'b00;
        alu_op = `ALU_ADD;
        sign_ext = 1'b1;

        case (opcode)
            `OP_R_TYPE: begin
                // R型指令
                reg_we = 1'b1;           // 写寄存器堆
                reg_dst = 2'b01;         // 写地址选择rd
                alu_src = 1'b0;          // ALU第二个操作数来自寄存器rt
                mem_to_reg = 2'b00;      // 写寄存器数据来自ALU结果

                // 根据funct字段确定ALU操作
                case (funct)
                    `FUNCT_ADD: alu_op = `ALU_ADD;
                    `FUNCT_SUB: alu_op = `ALU_SUB;
                    `FUNCT_AND: alu_op = `ALU_AND;
                    `FUNCT_OR:  alu_op = `ALU_OR;
                    `FUNCT_XOR: alu_op = `ALU_XOR;
                    `FUNCT_SLL: alu_op = `ALU_SLL;
                    `FUNCT_SRL: alu_op = `ALU_SRL;
                    `FUNCT_SRA: alu_op = `ALU_SRA;
                    `FUNCT_SLT: alu_op = `ALU_SLT;
                    `FUNCT_SLTU: alu_op = `ALU_SLTU;
                    default: alu_op = `ALU_ADD; // 默认加法
                endcase
            end

            `OP_ADDI: begin
                // addi指令
                reg_we = 1'b1;           // 写寄存器堆
                reg_dst = 2'b00;         // 写地址选择rt
                alu_src = 1'b1;          // ALU第二个操作数来自立即数
                mem_to_reg = 2'b00;      // 写寄存器数据来自ALU结果
                alu_op = `ALU_ADD;       // ALU操作：加法
                sign_ext = 1'b1;         // 符号扩展立即数
            end

            `OP_ORI: begin
                // ori指令
                reg_we = 1'b1;           // 写寄存器堆
                reg_dst = 2'b00;         // 写地址选择rt
                alu_src = 1'b1;          // ALU第二个操作数来自立即数
                mem_to_reg = 2'b00;      // 写寄存器数据来自ALU结果
                alu_op = `ALU_OR;        // ALU操作：或
                sign_ext = 1'b0;         // 零扩展立即数
            end

            `OP_BEQ: begin
                // beq指令
                reg_we = 1'b0;           // 不写寄存器堆
                branch = 1'b1;           // 分支信号有效
                alu_src = 1'b0;          // ALU第二个操作数来自寄存器rt
                alu_op = `ALU_SUB;       // ALU操作：减法（用于比较）
                sign_ext = 1'b1;         // 符号扩展立即数
            end

            `OP_J: begin
                // j指令
                reg_we = 1'b0;           // 不写寄存器堆
                jump = 1'b1;             // 跳转信号有效
            end

            `OP_LW: begin
                // lw指令
                reg_we = 1'b1;           // 写寄存器堆
                reg_dst = 2'b00;         // 写地址选择rt
                alu_src = 1'b1;          // ALU第二个操作数来自立即数
                mem_to_reg = 2'b01;      // 写寄存器数据来自数据存储器
                alu_op = `ALU_LW_SW;     // ALU操作：加法（计算地址）
                sign_ext = 1'b1;         // 符号扩展立即数
            end

            `OP_SW: begin
                // sw指令
                reg_we = 1'b0;           // 不写寄存器堆
                mem_we = 1'b1;           // 写数据存储器
                alu_src = 1'b1;          // ALU第二个操作数来自立即数
                alu_op = `ALU_LW_SW;     // ALU操作：加法（计算地址）
                sign_ext = 1'b1;         // 符号扩展立即数
            end

            default: begin
                // 其他指令，默认空操作
                reg_we = 1'b0;
                mem_we = 1'b0;
                branch = 1'b0;
                jump = 1'b0;
                reg_dst = 2'b00;
                alu_src = 1'b0;
                mem_to_reg = 2'b00;
                alu_op = `ALU_ADD;
                sign_ext = 1'b1;
            end
        endcase
    end

endmodule