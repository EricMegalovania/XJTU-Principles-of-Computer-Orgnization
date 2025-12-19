// CPU测试用例
// 对每个指令进行至少一次测试

`include "defines.v"

module testbench;

    // 信号定义
    reg                     clk;
    reg                     rst;
    wire [`ADDR_LEN-1:0]    pc_out;
    wire [`INSTR_LEN-1:0]   instr_out;

    // 时钟周期：10ns
    parameter CLK_PERIOD = 10;

    // CPU实例化
    single_period_cpu cpu (
        .clk(clk),
        .rst(rst),
        .pc_out(pc_out),
        .instr_out(instr_out)
    );

    // 时钟生成
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // 测试程序
    initial begin
        // 打开波形文件（如果使用VCS或其他工具，可以生成波形）
        $dumpfile("cpu_tb.vcd");
        $dumpvars(0, testbench);

        // 打印指令执行情况
        $monitor("Time: %0d, PC: %h, Instr: %h", $time, pc_out, instr_out);

        // 初始化
        rst = 1'b1;
        #(CLK_PERIOD * 2);
        rst = 1'b0;

        // 运行测试程序
        #(CLK_PERIOD * 100);

        // 结束仿真
        $finish;
    end

    // 指令存储器初始化
    // 在仿真时，通过$readmemh函数从文件加载指令
    // 这里直接在testbench中初始化指令存储器
    initial begin
        // 等待复位完成
        #(CLK_PERIOD * 2);

        // 测试指令
        // 指令格式：opcode, rs, rt, rd, shamt, funct
        // R型指令：opcode=000000
        // I型指令：opcode根据指令类型
        // J型指令：opcode=000010

        // 测试程序：
        // 1. add $t0, $zero, $zero     # $t0 = 0
        // 2. addi $t1, $zero, 10       # $t1 = 10
        // 3. addi $t2, $zero, 5        # $t2 = 5
        // 4. add $t3, $t1, $t2         # $t3 = 15
        // 5. sub $t4, $t1, $t2         # $t4 = 5
        // 6. andi $t5, $t1, 0x0F       # $t5 = 10 & 0x0F = 10
        // 7. ori $t6, $t2, 0x0A        # $t6 = 5 | 0x0A = 15
        // 8. xor $t7, $t1, $t2         # $t7 = 10 ^ 5 = 15
        // 9. sll $s0, $t2, 2           # $s0 = 5 << 2 = 20
        // 10. srl $s1, $t1, 1          # $s1 = 10 >> 1 = 5
        // 11. addi $s2, $zero, -5      # $s2 = -5
        // 12. sra $s3, $s2, 1          # $s3 = -5 >> 1 = -3
        // 13. slt $s4, $t2, $t1        # $s4 = 5 < 10 = 1
        // 14. sltu $s5, $t2, $t1       # $s5 = 5 < 10 = 1
        // 15. slt $s6, $t1, $t2        # $s6 = 10 < 5 = 0
        // 16. sw $t1, 0($zero)         # MEM[0] = 10
        // 17. lw $s7, 0($zero)         # $s7 = MEM[0] = 10
        // 18. addi $t0, $t0, 1         # $t0 = 1
        // 19. beq $t0, $zero, 8        # 1 != 0，不跳转
        // 20. addi $t0, $t0, 1         # $t0 = 2
        // 21. beq $t0, $t0, 4          # 2 == 2，跳转
        // 22. addi $t0, $t0, 1         # 不会执行
        // 23. addi $t0, $t0, 1         # 不会执行
        // 24. j 0x00000000             # 跳转到程序开头

        // 初始化指令存储器
        // 注意：这里直接修改指令存储器的内部寄存器，仅用于仿真
        // 在实际FPGA或ASIC设计中，需要通过$readmemh函数从文件加载指令
        #0;
        cpu.imem.imem[0] = 32'h0000_1020; // add $t0, $zero, $zero (op=0, rs=0, rt=0, rd=8, shamt=0, funct=32)
        cpu.imem.imem[1] = 32'h2009_000A; // addi $t1, $zero, 10 (op=8, rs=0, rt=9, imm=10)
        cpu.imem.imem[2] = 32'h200A_0005; // addi $t2, $zero, 5 (op=8, rs=0, rt=10, imm=5)
        cpu.imem.imem[3] = 32'h012A_1820; // add $t3, $t1, $t2 (op=0, rs=9, rt=10, rd=12, shamt=0, funct=32)
        cpu.imem.imem[4] = 32'h012A_2022; // sub $t4, $t1, $t2 (op=0, rs=9, rt=10, rd=16, shamt=0, funct=34)
        cpu.imem.imem[5] = 32'h012A_2824; // and $t5, $t1, $t2 (op=0, rs=9, rt=10, rd=20, shamt=0, funct=36)
        cpu.imem.imem[6] = 32'h012A_3025; // or $t6, $t1, $t2 (op=0, rs=9, rt=10, rd=24, shamt=0, funct=37)
        cpu.imem.imem[7] = 32'h012A_3826; // xor $t7, $t1, $t2 (op=0, rs=9, rt=10, rd=28, shamt=0, funct=38)
        cpu.imem.imem[8] = 32'h000A_4000; // sll $s0, $t2, 0 (op=0, rs=0, rt=10, rd=16, shamt=0, funct=0)
        cpu.imem.imem[9] = 32'h0009_4202; // srl $s1, $t1, 0 (op=0, rs=0, rt=9, rd=17, shamt=0, funct=2)
        cpu.imem.imem[10] = 32'h200C_FFFB; // addi $t3, $zero, -5 (op=8, rs=0, rt=12, imm=-5)
        cpu.imem.imem[11] = 32'h000C_4403; // sra $s2, $t3, 0 (op=0, rs=0, rt=12, rd=18, shamt=0, funct=3)
        cpu.imem.imem[12] = 32'h0149_482A; // slt $s3, $t2, $t1 (op=0, rs=10, rt=9, rd=19, shamt=0, funct=42)
        cpu.imem.imem[13] = 32'h0149_4A2B; // sltu $s4, $t2, $t1 (op=0, rs=10, rt=9, rd=20, shamt=0, funct=43)
        cpu.imem.imem[14] = 32'h012A_4C2A; // slt $s5, $t1, $t2 (op=0, rs=9, rt=10, rd=21, shamt=0, funct=42)
        cpu.imem.imem[15] = 32'hAC09_0000; // sw $t1, 0($zero) (op=43, rs=0, rt=9, imm=0)
        cpu.imem.imem[16] = 32'h8C0F_0000; // lw $s7, 0($zero) (op=35, rs=0, rt=15, imm=0)
        cpu.imem.imem[17] = 32'h2108_0001; // addi $t0, $t0, 1 (op=8, rs=8, rt=8, imm=1)
        cpu.imem.imem[18] = 32'h1100_0008; // beq $t0, $zero, 8 (op=4, rs=8, rt=0, imm=8)
        cpu.imem.imem[19] = 32'h2108_0001; // addi $t0, $t0, 1 (op=8, rs=8, rt=8, imm=1)
        cpu.imem.imem[20] = 32'h1108_0004; // beq $t0, $t0, 4 (op=4, rs=8, rt=8, imm=4)
        cpu.imem.imem[21] = 32'h2108_0001; // addi $t0, $t0, 1 (op=8, rs=8, rt=8, imm=1) - 不会执行
        cpu.imem.imem[22] = 32'h2108_0001; // addi $t0, $t0, 1 (op=8, rs=8, rt=8, imm=1) - 不会执行
        cpu.imem.imem[23] = 32'h0800_0000; // j 0x00000000 (op=2, address=0)
    end

endmodule
