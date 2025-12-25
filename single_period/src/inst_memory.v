`include "defines.v"

// 指令存储器模块
module inst_memory(
    input wire [`ADDR_LEN-1:0] addr,   // 指令地址
    output wire [`INSTR_LEN-1:0] inst  // 读出的指令
);
    
    // 256条指令的指令存储器
    reg [`INSTR_LEN-1:0] inst_mem [0:255];
    
    // 初始化测试指令
    initial begin
        inst_mem[0]  = 32'h34000000;
        inst_mem[1]  = 32'h20010001;
        inst_mem[2]  = 32'h34020002;
        inst_mem[3]  = 32'h00221820;
        inst_mem[4]  = 32'h00412022;
        inst_mem[5]  = 32'h10640004;
        inst_mem[6]  = 32'h00222825;
        inst_mem[7]  = 32'h10650002;
        inst_mem[8]  = 32'h08000000;
        inst_mem[9]  = 32'h0800000B;
        inst_mem[10] = 32'h08000000;
        inst_mem[11] = 32'h00A13024;
        inst_mem[12] = 32'h10260003;
        inst_mem[13] = 32'h08000000;
        inst_mem[14] = 32'h08000000;
        inst_mem[15] = 32'hAC26000F;
        inst_mem[16] = 32'h8CA7000D;
    end
    
    // 读取指令, 每条指令32位占4字节, 所以地址需要除以4
    assign inst = inst_mem[addr[`ADDR_LEN-1:2]];
    
endmodule
