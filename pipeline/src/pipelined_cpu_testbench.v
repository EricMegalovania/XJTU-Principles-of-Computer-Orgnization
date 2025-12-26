`include "defines.v"

module pipelined_cpu_testbench;

    // 信号定义
    reg                     clk;
    reg                     rst;
    wire [`ADDR_LEN-1:0]    pc;
    wire [`DATA_LEN-1:0]    inst;
    
    // 调试信号
    reg [31:0] cycle_count;

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

    // 复位和测试序列
    initial begin
        // 初始化
        rst = 1'b1;
        cycle_count = 0;
        
        // 复位信号维持2个时钟周期
        #(CLK_PERIOD * 2);
        rst = 1'b0;
        
        // 运行测试，5级流水线需要足够的时间来展示流水线操作
        #(CLK_PERIOD * 50);
        
        $display("\n=== 流水线CPU测试完成 ===");
        $display("总共运行了 %d 个时钟周期", cycle_count);
        $display("最终PC值: %h", pc);
        $display("最终指令: %h", inst);
        
        $finish;
    end
    
    // 周期计数和监控
    always @(posedge clk) begin
        if (!rst) begin
            cycle_count <= cycle_count + 1;
            
            // 每10个周期显示一次状态
            if (cycle_count % 10 == 0) begin
                $display("周期 %d: PC = %h, 指令 = %h", cycle_count, pc, inst);
            end
            
            // 监控特定指令的执行
            if (inst[31:26] == `OP_ADDI) begin
                $display("  -> 执行ADDI指令");
            end
            else if (inst[31:26] == `OP_R_TYPE && inst[5:0] == `FUNCT_ADD) begin
                $display("  -> 执行ADD指令");
            end
            else if (inst[31:26] == `OP_LW) begin
                $display("  -> 执行LW指令 (可能产生Load-Use冒险)");
            end
            else if (inst[31:26] == `OP_BEQ) begin
                $display("  -> 执行BEQ指令 (分支指令)");
            end
        end
    end
    
    // VCD波形文件生成
    initial begin
        $dumpfile("pipelined_cpu.vcd");
        $dumpvars(0, pipelined_cpu_testbench);
    end

endmodule