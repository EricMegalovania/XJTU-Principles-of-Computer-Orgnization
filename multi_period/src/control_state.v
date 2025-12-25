`include "defines.v"

module control_state(
	input wire clk,
	input wire rst,
	input wire [5:0] opcode,
	input wire [`STATE_LEN-1:0] state,
	output reg [`STATE_LEN-1:0] new_state
);

	always @(*) begin
		if (rst) begin
			new_state = `STATE_IF;
		end
		else begin
			case (state)
				`STATE_IF : new_state = `STATE_ID;
				`STATE_ID : begin
					case (opcode)
						`OP_J : new_state = `STATE_IF;
						default : new_state = `STATE_EX;
					endcase
				end
				`STATE_EX : begin
					case (opcode)
						`OP_R_TYPE, `OP_ADDI, `OP_ORI : new_state = `STATE_WB;
						`OP_LW, `OP_SW : new_state = `STATE_MEM;
						`OP_BEQ : new_state = `STATE_IF;
						default : new_state = `STATE_IF;
					endcase
				end
				`STATE_MEM : begin
					case (opcode)
						`OP_LW : new_state = `STATE_WB;
						`OP_SW : new_state = `STATE_IF;
						default : new_state = `STATE_IF;
					endcase
				end
				`STATE_WB : new_state = `STATE_IF;
				default : new_state = `STATE_IF;
			endcase
		end
	end

endmodule