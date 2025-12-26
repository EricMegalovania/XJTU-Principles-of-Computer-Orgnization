`include "defines.v"

module pc(
    input wire clk,
    input wire rst,
    input wire state_pc,
    input wire [`ADDR_LEN-1:0] in,
    output reg [`ADDR_LEN-1:0] out
);
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out <= 32'b0;
        end
        else if (state_pc) begin
            out <= in;
        end
    end
    
endmodule
