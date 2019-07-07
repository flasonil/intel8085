module top
(
	input logic rst,clk,
	input logic [7:0] data,
	input logic bc_rw,de_rw,hl_rw,wz_rw,pc_rw,sp_rw,
	input logic rreg_rd,lreg_rd,rreg_wr,lreg_wr,
	input logic dreg_wr,dreg_rd,
	output logic [15:0] address
);

registerfile U1(.ADDRESS(address),.clk(clk),.rst(rst),.DATA(data),.bc_rw(bc_rw),.de_rw(de_rw),.hl_rw(hl_rw),.wz_rw(wz_rw),.pc_rw(pc_rw),.sp_rw(sp_rw),.rreg_rd(rreg_rd),.lreg_rd(lreg_rd),.rreg_wr(rreg_wr),.lreg_wr(lreg_wr),.dreg_wr(dreg_wr),.dreg_rd(dreg_rd));

endmodule