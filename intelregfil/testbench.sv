`timescale 1ns/1ps

module testbench();

logic dreg_wr,dreg_rd;
logic bc_rw,de_rw,hl_rw,wz_rw,pc_rw,sp_rw;
logic rreg_rd,lreg_rd,rreg_wr,lreg_wr;
logic [7:0] data;
logic clk,rst;
logic [15:0] address;

top DUT(.address(address),.data(data),.clk(clk),.rst(rst),.bc_rw(bc_rw),.de_rw(de_rw),.hl_rw(hl_rw),.wz_rw(wz_rw),.pc_rw(pc_rw),.sp_rw(sp_rw),.rreg_rd(rreg_rd),.lreg_rd(lreg_rd),.rreg_wr(rreg_wr),.lreg_wr(lreg_wr),.dreg_wr(dreg_wr),.dreg_rd(dreg_rd));

always begin
#5 clk = !clk;
end

initial begin
clk = 1;
rst = 1;
rreg_rd = 0;
lreg_rd = 0;
rreg_wr = 0;
lreg_wr = 0;
bc_rw = 0;
de_rw = 0;
hl_rw = 0;
wz_rw = 0;
pc_rw = 0;
sp_rw = 0;
dreg_wr = 0;
dreg_rd = 0;
data = 8'h11;
#9 bc_rw = 1;
#9 rst = 0;

@(posedge clk);
lreg_wr = 1;
@(posedge clk);
data = 8'hAA;
lreg_wr = 0;
rreg_wr = 1;
@(posedge clk);
rreg_wr = 0;
rreg_rd = 1;
lreg_rd = 1;
@(posedge clk);
rreg_wr = 0;
rreg_rd = 0;
lreg_rd = 0;
@(posedge clk);
dreg_rd = 1;
@(posedge clk);
@(posedge clk);
$stop;

end
endmodule
