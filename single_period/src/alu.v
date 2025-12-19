`timescale 1ns / 1ps

module alu (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [3:0] alu_control,
    output reg [31:0] result,
    output wire zero
);

    // ALU控制信号定义
    parameter ADD = 4'b0000;
    parameter SUB = 4'b0001;
    parameter AND = 4'b0010;
    parameter OR  = 4'b0011;
    parameter XOR = 4'b0100;
    parameter SLL = 4'b0101;
    parameter SRL = 4'b0110;
    parameter SRA = 4'b0111;
    parameter SLT = 4'b1000;
    parameter SLTU = 4'b1001;

    // 执行运算
    always @(*) begin
        case (alu_control)
            ADD: result = a + b;
            SUB: result = a - b;
            AND: result = a & b;
            OR:  result = a | b;
            XOR: result = a ^ b;
            SLL: result = b << a[4:0]; // 逻辑左移
            SRL: result = b >> a[4:0]; // 逻辑右移
            SRA: result = $signed(b) >>> a[4:0]; // 算术右移
            SLT: result = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0;
            SLTU: result = (a < b) ? 32'b1 : 32'b0;
            default: result = 32'b0;
        endcase
    end

    // 零标志位
    assign zero = (result == 32'b0);

endmodule