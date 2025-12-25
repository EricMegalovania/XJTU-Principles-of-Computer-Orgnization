// 2选1多路选择器模块
module mux2 #(parameter WIDTH = 32)( // 默认宽度为32位
    input wire sel,              // 选择信号
    input wire [WIDTH-1:0] in0,  // 输入0
    input wire [WIDTH-1:0] in1,  // 输入1
    output wire [WIDTH-1:0] out  // 输出
);
    
    // 默认选择in0
    assign out = (sel == 1'b0) ? in0 :
                 (sel == 1'b1) ? in1 : in0;
    
endmodule