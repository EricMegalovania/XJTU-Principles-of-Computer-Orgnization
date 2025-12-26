`include "defines.v"

// 流水线寄存器传递模块
module pipeline_reg_swap(
    input wire clk,                    // 时钟信号
    input wire rst,                    // 复位信号
    input wire stall,                  // 暂停信号

    input wire [`DATA_LEN-1:0] reg1_data_in,
    input wire [`DATA_LEN-1:0] reg2_data_in,
    input wire [`DATA_LEN-1:0] alu_b_in,
    input wire [`DATA_LEN-1:0] alu_result_in,
    input wire [`DATA_LEN-1:0] mem_read_data_in,
    input wire [`DATA_LEN-1:0] write_back_data_in,
    input wire [`DATA_LEN-1:0] ext_imm_in,
    input wire [`ADDR_LEN-1:0] next_pc_in,
    input wire [`ADDR_LEN-1:0] branch_pc_in,
    input wire [`ADDR_LEN-1:0] jump_pc_in,
    input wire [`ADDR_LEN-1:0] next_pc_temp_in,
    input wire reg_dst_flag_in,
    input wire alu_src_flag_in,
    input wire mem_to_reg_flag_in,
    input wire reg_write_flag_in,
    input wire mem_read_flag_in,
    input wire mem_write_flag_in,
    input wire branch_flag_in,
    input wire jump_flag_in,
    input wire zero_in,
    input wire [`ALU_OPCODE] alu_op_in,
    input wire [`REG_ADDR_LEN-1:0] write_reg_addr_in,

	output reg [`DATA_LEN-1:0] reg1_data_out,
    output reg [`DATA_LEN-1:0] reg2_data_out,
    output reg [`DATA_LEN-1:0] alu_b_out,
    output reg [`DATA_LEN-1:0] alu_result_out,
    output reg [`DATA_LEN-1:0] mem_read_data_out,
    output reg [`DATA_LEN-1:0] write_back_data_out,
    output reg [`DATA_LEN-1:0] ext_imm_out,
    output reg [`ADDR_LEN-1:0] next_pc_out,
    output reg [`ADDR_LEN-1:0] branch_pc_out,
    output reg [`ADDR_LEN-1:0] jump_pc_out,
    output reg [`ADDR_LEN-1:0] next_pc_temp_out,
    output reg reg_dst_flag_out,
    output reg alu_src_flag_out,
    output reg mem_to_reg_flag_out,
    output reg reg_write_flag_out,
    output reg mem_read_flag_out,
    output reg mem_write_flag_out,
    output reg branch_flag_out,
    output reg jump_flag_out,
    output reg zero_out,
    output reg [`ALU_OPCODE] alu_op_out,
    output reg [`REG_ADDR_LEN-1:0] write_reg_addr_out,
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_id <= 32'b0;
            inst_id <= 32'b0;
        end
        else if (stall) begin
            // 暂停时保持不变
			reg1_data_out       <= reg1_data_out,
			reg2_data_out       <= reg2_data_out,
			alu_b_out           <= alu_b_out,
			alu_result_out      <= alu_result_out,
			mem_read_data_out   <= mem_read_data_out,
			write_back_data_out <= write_back_data_out,
			ext_imm_out         <= ext_imm_out,
			next_pc_out         <= next_pc_out,
			branch_pc_out       <= branch_pc_out,
			jump_pc_out         <= jump_pc_out,
			next_pc_temp_out    <= next_pc_temp_out,
			reg_dst_flag_out    <= reg_dst_flag_out,
			alu_src_flag_out    <= alu_src_flag_out,
			mem_to_reg_flag_out <= mem_to_reg_flag_out,
			reg_write_flag_out  <= reg_write_flag_out,
			mem_read_flag_out   <= mem_read_flag_out,
			mem_write_flag_out  <= mem_write_flag_out,
			branch_flag_out     <= branch_flag_out,
			jump_flag_out       <= jump_flag_out,
			zero_out            <= zero_out,
			alu_op_out          <= alu_op_out,
			write_reg_addr_out  <= write_reg_addr_out,
        end
        else begin
			reg1_data_out       <= reg1_data_in,
			reg2_data_out       <= reg2_data_in,
			alu_b_out           <= alu_b_in,
			alu_result_out      <= alu_result_in,
			mem_read_data_out   <= mem_read_data_in,
			write_back_data_out <= write_back_data_in,
			ext_imm_out         <= ext_imm_in,
			next_pc_out         <= next_pc_in,
			branch_pc_out       <= branch_pc_in,
			jump_pc_out         <= jump_pc_in,
			next_pc_temp_out    <= next_pc_temp_in,
			reg_dst_flag_out    <= reg_dst_flag_in,
			alu_src_flag_out    <= alu_src_flag_in,
			mem_to_reg_flag_out <= mem_to_reg_flag_in,
			reg_write_flag_out  <= reg_write_flag_in,
			mem_read_flag_out   <= mem_read_flag_in,
			mem_write_flag_out  <= mem_write_flag_in,
			branch_flag_out     <= branch_flag_in,
			jump_flag_out       <= jump_flag_in,
			zero_out            <= zero_in,
			alu_op_out          <= alu_op_in,
			write_reg_addr_out  <= write_reg_addr_in,
        end
    end

endmodule