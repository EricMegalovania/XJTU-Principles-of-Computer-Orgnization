`timescale 1ns / 1ps

module reg_file (
    input wire clk,
    input wire we3,
    input wire [4:0] ra1,
    input wire [4:0] ra2,
    input wire [4:0] wa3,
    input wire [31:0] wd3,
    output wire [31:0] rd1,
    output wire [31:0] rd2
);

    reg [31:0] regs [0:31]; // 32个32位寄存器

    // 初始化全部清零
    initial begin
        integer i;
        for (i = 0; i < 32; i = i + 1) begin
            regs[i] = 32'b0;
        end
    end

    // 写操作（上升沿触发）
    always @(posedge clk)
    begin
        if (we3 && wa3 != 5'b0)
            regs[wa3] <= wd3;
    end

    // 读操作（组合逻辑）
    assign rd1 = (ra1 == 5'b0) ? 32'b0 : regs[ra1];
    assign rd2 = (ra2 == 5'b0) ? 32'b0 : regs[ra2];

endmodule