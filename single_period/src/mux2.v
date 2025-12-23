// 2选1多路选择器模块
module mux2 #(parameter WIDTH)(
    input wire sel,              // 选择信号
    input wire [WIDTH-1:0] in0,  // 输入0
    input wire [WIDTH-1:0] in1,  // 输入1
    output wire [WIDTH-1:0] out  // 输出
);
    
    assign out = (sel == 1'b0) ? in0 : in1;
    
endmodule
