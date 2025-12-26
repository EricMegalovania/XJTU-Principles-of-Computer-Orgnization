`include "defines.v"

module testbench_pipelined;

    // 信号定义
    reg                     clk;
    reg                     rst;
    wire [`ADDR_LEN-1:0]    pc;
    wire [`INSTR_LEN-1:0]   inst;

    // 时钟周期：20ns
    parameter CLK_PERIOD = 20;

    // CPU实例化
    pipelined_cpu cpu (
        .clk(clk),
        .rst(rst),
        .pc(pc),
        .inst(inst)
    );

    // 时钟生成
    initial begin
        clk = 1'b1;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // 监控信号变化
    initial begin
        $monitor("Time: %4d, PC: %8h, Instruction: %8h", 
                 $time, pc, inst);
    end

    // 测试序列
    initial begin
        $display("开始流水线CPU测试...");
        
        rst = 1'b1;
        #(CLK_PERIOD);
        rst = 1'b0;
        
        $display("复位完成，开始执行指令...");
        
        // 运行足够多的时钟周期来观察流水线操作
        #(CLK_PERIOD * 100);
        
        $display("测试完成");
        $finish;
    end

    // 收集统计信息
    initial begin
        $dumpfile("pipelined_cpu.vcd");
        $dumpvars(0, testbench_pipelined);
    end

endmodule