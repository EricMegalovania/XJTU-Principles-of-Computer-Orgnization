`include "defines.v"

// 指令存储器模块
module inst_memory(
    input wire [`ADDR_LEN-1:0] addr,  // 指令地址
    output wire [`INSTR_LEN-1:0] inst  // 读出的指令
);
    
    // 指令存储器，大小为256条指令
    reg [`INSTR_LEN-1:0] inst_mem [0:255];
    
    // 初始化指令存储器
    initial begin
        // 这里可以添加测试指令
        // 例如：add $t0, $t1, $t2 -> opcode: 000000, rs: 01001, rt: 01010, rd: 01000, funct: 100000
        inst_mem[0] = 32'b000000_01001_01010_01000_00000_100000;
        // sub $t3, $t4, $t5 -> opcode: 000000, rs: 01010, rt: 01011, rd: 01011, funct: 100010
        inst_mem[1] = 32'b000000_01010_01011_01011_00000_100010;
        // and $t6, $t7, $s0 -> opcode: 000000, rs: 01111, rt: 10000, rd: 01110, funct: 100100
        inst_mem[2] = 32'b000000_01111_10000_01110_00000_100100;
        // or $s1, $s2, $s3 -> opcode: 000000, rs: 10010, rt: 10011, rd: 10001, funct: 100101
        inst_mem[3] = 32'b000000_10010_10011_10001_00000_100101;
        // addi $s4, $s5, 100 -> opcode: 001000, rs: 10101, rt: 10100, imm: 0000000001100100
        inst_mem[4] = 32'b001000_10101_10100_0000000001100100;
        // ori $s6, $s7, 255 -> opcode: 001101, rs: 10111, rt: 10110, imm: 0000000011111111
        inst_mem[5] = 32'b001101_10111_10110_0000000011111111;
    end
    
    // 读取指令，注意地址需要除以4，因为每条指令占4字节
    assign inst = inst_mem[addr[9:2]];
    
endmodule
