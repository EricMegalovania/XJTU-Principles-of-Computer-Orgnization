`include "defines.v"

module io_input_reg (
	input wire [`ADDR_LEN-1:0] addr,
	input wire io_clk,
	input wire [`DATA_LEN-1:0] in_port0,
	input wire [`DATA_LEN-1:0] in_port1,
	input wire [`DATA_LEN-1:0] in_port2,
	output wire [`DATA_LEN-1:0] io_read_data
);

	reg [`DATA_LEN-1:0] in_reg0; // input port0
	reg [`DATA_LEN-1:0] in_reg1; // input port1
	reg [`DATA_LEN-1:0] in_reg2; // input port2

	io_input_mux io_input_mux_inst(
		.sel_addr(addr[7:2]),
		.in0(in_reg0),
		.in1(in_reg1),
		.in2(in_reg2),
		.out(io_read_data)
	);

	always @(posedge io_clk) begin
		in_reg0 <= in_port0; // 输入端口在io_clk上升沿时进行数据锁存
		in_reg1 <= in_port1; // 输入端口在io_clk上升沿时进行数据锁存
		in_reg2 <= in_port2; // 输入端口在io_clk上升沿时进行数据锁存
	end

endmodule
