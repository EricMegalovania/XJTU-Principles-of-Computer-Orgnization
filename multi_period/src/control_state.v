`include "defines.v"

module control_state(
	input wire [5:0] opcode,
	input wire [`STATE_LEN-1:0] state,
	output wire [`STATE_LEN-1:0] new_state
);

	reg [`STATE_LEN-1:0] new_state_reg;

	always @(*) begin
		case (state)
			`STATE_IF : new_state_reg = `STATE_ID;
			`STATE_ID : begin
				case (opcode)
					`OP_J : new_state_reg = `STATE_IF;
					default : new_state_reg = `STATE_EX;
				endcase
			end
			`STATE_EX : begin
				case (opcode)
					`OP_R_TYPE, `OP_ADDI, `OP_ORI : new_state_reg = `STATE_WB;
					`OP_LW, `OP_SW : new_state_reg = `STATE_MEM;
					`OP_BEQ : new_state_reg = `STATE_IF;
					default : new_state_reg = `STATE_IF;
				endcase
			end
			`STATE_MEM : begin
				case (opcode)
					`OP_LW : new_state_reg = `STATE_WB;
					`OP_SW : new_state_reg = `STATE_IF;
					default : new_state_reg = `STATE_IF;
				endcase
			end
			`STATE_WB : new_state_reg = `STATE_IF;
			default : new_state_reg = `STATE_IF;
		endcase
	end

	assign new_state = new_state_reg;

endmodule