`timescale 1ns / 1ps

module inst_mem (
    input wire [31:0] addr,
    output wire [31:0] inst
);

    reg [31:0] mem [0:255]; // 256个32位存储单元

    // 初始化指令存储器（这里可以根据需要修改为具体的指令）
    initial begin
        $readmemh("D:/A_devcpp/Principles\ of\ Computer\ Organization/Z_Project/single_period/src/instructions.mem", mem);
    end

    assign inst = mem[addr[31:2]]; // 字对齐，忽略低2位

endmodule