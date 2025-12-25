// 3选1多路选择器模块
module mux3 #(parameter WIDTH)(
    input wire [1:0] sel,
    input wire [WIDTH-1:0] in0,
    input wire [WIDTH-1:0] in1,
	input wire [WIDTH-1:0] in2,
    output wire [WIDTH-1:0] out
);
    
	// 默认为in0
    assign out = (sel == 2'b00) ? in0 :
                 (sel == 2'b01) ? in1 :
                 (sel == 2'b10) ? in2 : in0;
    
endmodule