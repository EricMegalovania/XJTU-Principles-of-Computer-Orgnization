`include "defines.v"

module testbench;

    // 信号定义
    reg                     clk;
    reg                     rst;

    // 时钟周期：20ns
    parameter CLK_PERIOD = 20;

    // CPU实例化
    multi_period_cpu cpu (
        .clk(clk),
        .rst(rst)
    );

    // 时钟生成
    initial begin
        clk = 1'b1;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        // 初始化信号
        rst = 1'b1;
        #(CLK_PERIOD);
        rst = 1'b0;

        // 运行足够多的时钟周期，确保所有测试指令都能执行完成
        // 每条指令平均需要3个周期，17条指令需要约51个周期
        // 额外增加一些周期以确保稳定性
        #(CLK_PERIOD * 70);

        $finish;
    end
endmodule