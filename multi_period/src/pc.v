`include "defines.v"

module pc(
    input wire clk,
    input wire rst,
    input wire we,                  // 写使能信号
    input wire [`ADDR_LEN-1:0] in,
    output reg [`ADDR_LEN-1:0] out
);
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out <= 32'b0;
        end
        else if (we) begin  // 只有写使能信号有效时才更新PC
            out <= in;
        end
    end
    
endmodule
