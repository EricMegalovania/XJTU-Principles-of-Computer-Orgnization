`timescale 1ns / 1ps

module control (
    input wire [5:0] opcode,
    input wire [5:0] funct,
    output wire reg_dst,
    output wire jump,
    output wire branch,
    output wire mem_read,
    output wire mem_to_reg,
    output wire [3:0] alu_op,
    output wire mem_write,
    output wire alu_src,
    output wire reg_write
);

    // 指令类型定义
    parameter R_TYPE = 6'b000000;
    parameter LW     = 6'b100011;
    parameter SW     = 6'b101011;
    parameter BEQ    = 6'b000100;
    parameter ADDI   = 6'b001000;
    parameter ORI    = 6'b001101;
    parameter J      = 6'b000010;

    // R型指令功能码
    parameter ADD = 6'b100000;
    parameter SUB = 6'b100010;
    parameter AND = 6'b100100;
    parameter OR  = 6'b100101;
    parameter XOR = 6'b100110;
    parameter SLL = 6'b000000;
    parameter SRL = 6'b000010;
    parameter SRA = 6'b000011;
    parameter SLT = 6'b101010;
    parameter SLTU = 6'b101011;

    // ALU控制信号
    parameter ALU_ADD = 4'b0000;
    parameter ALU_SUB = 4'b0001;
    parameter ALU_AND = 4'b0010;
    parameter ALU_OR  = 4'b0011;
    parameter ALU_XOR = 4'b0100;
    parameter ALU_SLL = 4'b0101;
    parameter ALU_SRL = 4'b0110;
    parameter ALU_SRA = 4'b0111;
    parameter ALU_SLT = 4'b1000;
    parameter ALU_SLTU = 4'b1001;

    // 主控制信号
    reg [9:0] controls;
    assign {reg_dst, jump, branch, mem_read, mem_to_reg, mem_write, alu_src, reg_write, alu_op} = controls;

    // 生成控制信号
    always @(*) begin
        case (opcode)
            R_TYPE: begin
                case (funct)
                    ADD: controls <= {1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, ALU_ADD};
                    SUB: controls <= {1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, ALU_SUB};
                    AND: controls <= {1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, ALU_AND};
                    OR:  controls <= {1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, ALU_OR};
                    XOR: controls <= {1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, ALU_XOR};
                    SLL: controls <= {1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, ALU_SLL};
                    SRL: controls <= {1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, ALU_SRL};
                    SRA: controls <= {1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, ALU_SRA};
                    SLT: controls <= {1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, ALU_SLT};
                    SLTU: controls <= {1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, ALU_SLTU};
                    default: controls <= 10'b0;
                endcase
            end
            LW:     controls <= {1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b1, ALU_ADD};
            SW:     controls <= {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, ALU_ADD};
            BEQ:    controls <= {1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, ALU_SUB};
            ADDI:   controls <= {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, ALU_ADD};
            ORI:    controls <= {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, ALU_OR};
            J:      controls <= {1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, ALU_ADD}; // jump信号为1
            default: controls <= 10'b0;
        endcase
    end

endmodule