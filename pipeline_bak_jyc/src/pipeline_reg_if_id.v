`include "defines.v"

// IF/ID 流水线寄存器模块
module pipeline_reg_if_id(
    input wire clk,                    // 时钟信号
    input wire rst,                    // 复位信号
    input wire stall,                  // 暂停信号
    input wire [`ADDR_LEN-1:0] pc,     // PC值
    input wire [`INSTR_LEN-1:0] inst,  // 指令
    output reg [`ADDR_LEN-1:0] pc_id,  // ID阶段的PC值
    output reg [`INSTR_LEN-1:0] inst_id // ID阶段的指令
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_id <= 32'b0;
            inst_id <= 32'b0;
        end
        else if (stall) begin
            // 暂停时保持不变
            pc_id <= pc_id;
            inst_id <= inst_id;
        end
        else begin
            pc_id <= pc;
            inst_id <= inst;
        end
    end

endmodule