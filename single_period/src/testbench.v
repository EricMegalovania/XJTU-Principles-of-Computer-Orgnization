`timescale 1ns / 1ps

module testbench;

    reg clk;
    reg rst;

    single_cycle_cpu cpu (
        .clk(clk),
        .rst(rst)
    );

    initial begin
        clk = 1;
        forever #10 clk = ~clk; // 20ns周期, 50MHz
    end

    initial begin
        rst = 1;
        #20;
        rst = 0;
        #400; // 运行400ns
        $finish;
    end

endmodule