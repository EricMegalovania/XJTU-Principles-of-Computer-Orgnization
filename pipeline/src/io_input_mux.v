`include "defines.v"

module io_input_mux(
	input wire [`REG_ADDR_LEN-1:0] sel_addr,
	input wire [`DATA_LEN-1:0] in0,
	input wire [`DATA_LEN-1:0] in1,
	input wire [`DATA_LEN-1:0] in2,
	output wire [`DATA_LEN-1:0] out
);

	reg [31:0] out_reg;

	always @(*) begin
		case (sel_addr)
			6'b110000: out_reg = in0;
			6'b110001: out_reg = in1;
			6'b110010: out_reg = in2;
		endcase
	end

	assign out = out_reg;

endmodule
