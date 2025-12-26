// 2选1多路选择器模块
module mux4 #(parameter WIDTH = 32)( // 默认宽度为32位
    input wire [1:0] sel,              // 选择信号
    input wire [WIDTH-1:0] in0,  // 输入0
    input wire [WIDTH-1:0] in1,  // 输入1
    input wire [WIDTH-1:0] in2,  // 输入2
    input wire [WIDTH-1:0] in3,  // 输入3
    output wire [WIDTH-1:0] out  // 输出
);
    
    // 默认选择in0
    assign out = (sel == 2'b00) ? in0 :
                 (sel == 2'b01) ? in1 :
                 (sel == 2'b10) ? in2 :
                 (sel == 2'b11) ? in3 : in0;
    
endmodule