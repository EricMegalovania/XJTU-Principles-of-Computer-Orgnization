`include "defines.v"

module testbench;

    // 信号定义
    reg                     clk;
    reg                     rst;
    wire [`ADDR_LEN-1:0]    pc;
    wire [`INSTR_LEN-1:0]   inst;

    // 时钟周期：20ns
    parameter CLK_PERIOD = 20;

    // CPU实例化
    single_period_cpu cpu (
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

    initial begin
        rst = 1'b1;
        #(CLK_PERIOD);
        rst = 1'b0;

        #(CLK_PERIOD * 20);

        $finish;
    end
endmodule