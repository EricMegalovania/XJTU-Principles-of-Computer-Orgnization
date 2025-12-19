`timescale 1ns / 1ps

module data_mem (
    input wire clk,
    input wire we,
    input wire [31:0] addr,
    input wire [31:0] wd,
    output wire [31:0] rd
);

    reg [31:0] mem [0:255]; // 256个32位存储单元

    // 初始化数据存储器
    initial begin
        $readmemh("D:/A_devcpp/Principles\ of\ Computer\ Organization/Z_Project/single_period/src/data.mem", mem);
    end

    // 写操作（上升沿触发）
    always @(posedge clk)
    begin
        if (we)
            mem[addr[31:2]] <= wd;
    end

    // 读操作（组合逻辑）
    assign rd = mem[addr[31:2]];

endmodule