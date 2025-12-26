`include "defines.v"

module pipeif( pcsource,pc,bpc,da,jpc,npc,pc4,ins,rom_clk );
	input [`ADDR_LEN-1:0] pc, bpc, da, jpc;
	input [1:0] pcsource;
	input rom_clk;
	output [`ADDR_LEN-1:0] npc, pc4, ins;
	
	wire [`ADDR_LEN-1:0] npc, pc4, ins;
	lpm_rom_irom irom(pc[7:2], rom_clk, ins);

	assign pc4 = pc + 32'h4;

	mux4 #(`ADDR_LEN) new_pc(pcsource,pc4,bpc,da,jpc,npc);
endmodule