`include "defines.v"

module control_state(
	input wire rst,
	input wire [5:0] opcode,
	input wire [`STATE_LEN-1:0] state,
	output wire [`STATE_LEN-1:0] new_state,
	output wire state_pc,             // 下个状态是否为 IF
    output wire state_regfile_read,   // 下个状态是否为 ID
    output wire state_regfile_write,  // 下个状态是否为 WB
    output wire state_memory          // 下个状态是否为 MEM
);

	reg [`STATE_LEN-1:0] new_state_reg;

	always @(*) begin
		if (rst) begin
			new_state_reg = `STATE_IF;
		end
		else begin
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
	end

	assign new_state = new_state_reg;

	reg state_pc_reg;
    reg state_regfile_read_reg;
    reg state_regfile_write_reg;
    reg state_memory_reg;

	always @(posedge rst or new_state) begin
        // 默认值
        state_pc_reg <= 1'b0;
        state_regfile_read_reg <= 1'b0;
        state_regfile_write_reg <= 1'b0;
        state_memory_reg <= 1'b0;

        if (rst) begin
            state_pc_reg <= 1'b1;
        end
        else begin
            case (new_state)
                `STATE_IF : begin
                    state_pc_reg <= 1'b1;
                end
                `STATE_ID : begin
                    state_regfile_read_reg <= 1'b1;
                end
                `STATE_EX : begin
                end
                `STATE_MEM : begin
                    state_memory_reg <= 1'b1;
                end
                `STATE_WB : begin
                    state_regfile_write_reg <= 1'b1;
                end
            endcase
        end
    end

	assign state_pc            = state_pc_reg;
    assign state_regfile_read  = state_regfile_read_reg;
    assign state_regfile_write = state_regfile_write_reg;
    assign state_memory        = state_memory_reg;

endmodule