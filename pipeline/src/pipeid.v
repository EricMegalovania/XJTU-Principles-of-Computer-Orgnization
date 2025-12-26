`include "defines.v"

module pipeid( mwreg,mrn,ern,ewreg,em2reg,mm2reg,dpc4,inst,
	wrn,wdi,ealu,malu,mmo,wwreg,clock,resetn,
	bpc,jpc,pcsource,wpcir,dwreg,dm2reg,dwmem,daluc,
	daluimm,da,db,dimm,drn,dshift,djal ); 
	
	input [31:0] dpc4, inst, wdi, ealu, malu, mmo;
	input [4:0] ern, mrn, wrn;
	input mwreg, ewreg, em2reg, mm2reg, wwreg;
	input clock, resetn;
	output wire [31:0] bpc, jpc, da, db, dimm;
	output wire [4:0] drn;
	output wire [3:0] daluc;
	output wire [1:0] pcsource;
	output wpcir, dwreg, dm2reg, dwmem, daluimm, dshift, djal;
	
	wire [31:0] qa,qb;
	wire [5:0] op = inst[31:26];
	wire [4:0] rs = inst[25:21];
	wire [4:0] rt = inst[20:16];
	wire [4:0] rd = inst[15:11];
	wire [5:0] func = inst[5:0];
	reg [1:0] fwda,fwdb;
	wire dsext,dregrt;
	wire z = ~|(da^db);
	wire          e = dsext & inst[15];          // positive or negative sign at sext signal
   wire  [15:0] imm = {16{e}};                // high 16 sign bit
   assign dimm = {imm,inst[15:0]}; // sign extend to high 16
	wire [31:0]   offset = {imm[13:0],inst[15:0],1'b0,1'b0};   //offset(include sign extend)
	
	pipecu cu(op, func, ewreg, ern, em2reg, z, rs, rt, dwmem, dwreg, dregrt, dm2reg, daluc, dshift,
              daluimm, pcsource, djal, dsext,wpcir);
	
   assign bpc = dpc4 + offset;     // modified
   assign jpc = {dpc4[31:28],inst[25:0],1'b0,1'b0}; // j address 
	
	always @ (ewreg or mwreg or ern or mrn or em2reg or mm2reg or rs or rt)
	begin
		fwda = 2'b00;
		if (ewreg & (ern != 0) & (ern == rs) & ~em2reg)
		begin
			fwda = 2'b01;
		end
		else
		begin
			if (mwreg & (mrn != 0) & (mrn == rs) & ~mm2reg) 
			begin
				fwda = 2'b10;
			end
			else 
			begin
				if (mwreg & (mrn != 0) & (mrn == rs) & mm2reg)
				begin
					fwda = 2'b11;
				end
			end
		end
		
		fwdb = 2'b00;
		if (ewreg & (ern != 0) & (ern == rt) & ~em2reg)
		begin
			fwdb = 2'b01;
		end
		else
		begin
			if (mwreg & (mrn != 0) & (mrn == rt) & ~mm2reg) 
			begin
				fwdb = 2'b10;
			end
			else 
			begin
				if (mwreg & (mrn != 0) & (mrn == rt) & mm2reg)
				begin
					fwdb = 2'b11;
				end
			end
		end
	end
	mux2 #(`REG_ADDR_LEN) dreg(
		.sel(dregrt),
		.in0(rd),
		.in1(rt),
		.out(drn)
	);
	regfile rf(rs, rt, wdi, wrn, wwreg, clock, resetn, qa, qb);
	
	mux4 #(`DATA_LEN) alu_a(
		.sel(fwda),
		.in0(qa),
		.in1(ealu),
		.in2(malu),
		.in3(mmo),
		.out(da)
	);
	mux4 #(`DATA_LEN) alu_b(
		.sel(fwdb),
		.in0(qb),
		.in1(ealu),
		.in2(malu),
		.in3(mmo),
		.out(db)
	);

endmodule
