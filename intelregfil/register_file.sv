//module registerpair
//(
//	inout logic [15:0] DATA,
//	input logic /*oe,we,*/reg_rw,
//
//	input logic clk,rst
//);
//logic [15:0] value,datao;
//
//always@(negedge clk)begin
//	if(rst) value <= 16'h0000;
//	else begin
//		if(!reg_rw) value <= DATA;	//0 = write
//		else datao <= value;		//1 = read
//	end
//end
//assign DATA = reg_rw ? datao : 16'bzzzzzzzzzzzzzzzz;
//endmodule

module registerfile
(
	inout logic [7:0] DATA,

	input logic clk,rst,
	input logic bc_rw,de_rw,hl_rw,wz_rw,pc_rw,sp_rw,
	input logic rreg_rd,lreg_rd,rreg_wr,lreg_wr,
	input logic dreg_wr,dreg_rd,

	output logic [15:0] ADDRESS
);
logic [15:0] outreg;
logic [7:0]regbusr,regbusl,datao,data_latchr,data_latchl;
logic [15:0] bc,de,hl,wz,pc,sp,address_latch;

always@(negedge clk)begin
if(rst)begin
bc <= 16'h0000;
de <= 16'h0000;
hl <= 16'h0000;
wz <= 16'h0000;
pc <= 16'h0000;
sp <= 16'h0000;
end
end

always@(posedge rreg_wr)begin
if(bc_rw) bc[7:0] <= regbusr;
else if(de_rw) de[7:0] <= regbusr;
else if(hl_rw) hl[7:0] <= regbusr;
else if(wz_rw) wz[7:0] <= regbusr;
else if(pc_rw) pc[7:0] <= regbusr;
else if(sp_rw) sp[7:0] <= regbusr;
end

always@(posedge lreg_wr)begin
if(bc_rw) bc[15:8] <= regbusl;
else if(de_rw) de[15:8] <= regbusl;
else if(hl_rw) hl[15:8] <= regbusl;
else if(wz_rw) wz[15:8] <= regbusl;
else if(pc_rw) pc[15:8] <= regbusl;
else if(sp_rw) sp[15:8] <= regbusl;
end

always@(posedge rreg_rd)begin
if(bc_rw) outreg[7:0] <= bc[7:0];
else if(de_rw) outreg[7:0] <= de[7:0];
else if(hl_rw) outreg[7:0] <= hl[7:0];
else if(wz_rw) outreg[7:0] <= wz[7:0];
else if(pc_rw) outreg[7:0] <= pc[7:0];
else if(sp_rw) outreg[7:0] <= sp[7:0];
end

always@(posedge lreg_rd)begin
if(bc_rw) outreg[15:8] <= bc[15:8];
else if(de_rw) outreg[15:8] <= de[15:8];
else if(hl_rw) outreg[15:8] <= hl[15:8];
else if(wz_rw) outreg[15:8] <= wz[15:8];
else if(pc_rw) outreg[15:8] <= pc[15:8];
else if(sp_rw) outreg[15:8] <= sp[15:8];
end

always@(posedge dreg_rd)begin
if(bc_rw) address_latch <= bc[15:8];
else if(de_rw) address_latch <= de[15:8];
else if(hl_rw) address_latch <= hl[15:8];
else if(wz_rw) address_latch <= wz[15:8];
else if(pc_rw) address_latch <= pc[15:8];
else if(sp_rw) address_latch <= sp[15:8];
end

always@(negedge clk)begin
	if(!rreg_rd&&lreg_rd) datao <= outreg[15:7];
	else if(rreg_rd&&!lreg_rd) datao <= outreg[7:0];
	else datao <= 8'bzzzzzzzz;
end

assign data_latchl = dreg_wr ? address_latch[15:8] : DATA;
assign regbusl = ((!rreg_wr&&lreg_wr)||dreg_wr) ? data_latchl : 8'bzzzzzzzz;
assign data_latchr = dreg_wr ? address_latch[7:0] : DATA;
assign regbusr = ((rreg_wr&&!lreg_wr)||dreg_wr) ? data_latchr : 8'bzzzzzzzz;
assign DATA = (rreg_rd || lreg_rd)?datao : 8'bzzzzzzzz;

assign ADDRESS = address_latch;
endmodule