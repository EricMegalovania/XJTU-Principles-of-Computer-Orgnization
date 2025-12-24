// 3选1多路选择器模块
module mux3 #(parameter WIDTH)(
	input wire sel,
	input wire [WIDTH-1:0] in0,
	input wire [WIDTH-1:0] in1,
	input wire [WIDTH-1:0] in2,
	output reg [WIDTH-1:0] out
);
	always @(*) begin
		case (sel)
			2'b00: out = in0;
			2'b01: out = in1;
			2'b10: out = in2;
			default: out = in0;
		endcase
	end
endmodule