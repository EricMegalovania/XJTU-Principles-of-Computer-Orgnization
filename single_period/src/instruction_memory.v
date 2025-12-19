// 指令存储器模块
// 只读，32位宽，按字寻址

`include "defines.v"

module instruction_memory (
    input  wire [`ADDR_LEN-1:0]     addr,     // 指令地址
    output wire [`INSTR_LEN-1:0]     instr     // 读取的指令
);

    // 指令存储器大小：1024条指令（4KB）
    parameter IMEM_SIZE = 1024;

    // 指令存储器：IMEM_SIZE个32位指令
    reg [`INSTR_LEN-1:0] imem [IMEM_SIZE-1:0];

    // 循环变量声明
    integer i;

    // 初始化指令存储器（在仿真时可以通过$readmemh函数从文件加载指令）
    initial begin
        // 默认所有指令初始化为nop（空指令，R型指令中 funct=0 且其他字段为0）
        for (i = 0; i < IMEM_SIZE; i = i + 1) begin
            imem[i] = `INSTR_LEN'h0;
        end
    end

    // 读取指令：组合逻辑，地址变化时立即输出
    // 地址右移2位，将字节地址转换为字地址
    assign instr = imem[addr[31:2]];

endmodule
