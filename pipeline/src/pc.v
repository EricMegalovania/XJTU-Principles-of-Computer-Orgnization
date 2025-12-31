`include "defines.v"

module pc(
    input wire clk,
    input wire rst,
    input wire pc_write,
    input wire [`ADDR_LEN-1:0] pc,
    input wire [`ADDR_LEN-1:0] pc_plus_4,
    input wire ex_mem_valid,
    input wire ex_mem_jump_flag,
    input wire [`ADDR_LEN-1:0] ex_mem_jump_target,
    input wire ex_mem_branch_flag,
    input wire ex_mem_zero,
    input wire [`ADDR_LEN-1:0] ex_mem_branch_target,
    input wire [`ADDR_LEN-1:0] ex_mem_pc_plus_4,
    output wire [`ADDR_LEN-1:0] pc_next
);
    
    reg [`ADDR_LEN-1:0] pc_next_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_next_reg <= 32'b0;
        end
        else if (pc_write) begin
            if (ex_mem_valid && ex_mem_jump_flag) begin
                // 跳转指令
                pc_next_reg <= ex_mem_jump_target;
            end
            else if (ex_mem_valid && ex_mem_branch_flag) begin
                // 分支指令
                if (ex_mem_zero) begin
                    pc_next_reg <= ex_mem_branch_target;
                end
                else begin
                    pc_next_reg <= ex_mem_pc_plus_4;
                end
            end
            else begin
                pc_next_reg <= pc_plus_4;
            end
        end
    end

    assign pc_next = pc_next_reg;
    
endmodule
