`timescale 1ns/1ps
module registerfile
(
	input logic phi1,phi2,rst,

	input logic bc_rw,de_rw,hl_rw,wz_rw,pc_rw,sp_rw,
	input logic rreg_rd,lreg_rd,rreg_wr,lreg_wr,
	input logic dreg_wr,dreg_rd,dreg_dec,dreg_inc,dreg_cnt,dreg_cnt2,

	inout logic [7:0] DATA,
	output logic [15:0] ADDRESS,
	output logic carry_out
);
logic [15:0] outreg;
logic [7:0]regbusr,regbusl,datao,data_latchr,data_latchl;
logic [15:0] bc,de,hl,wz,pc,sp,address_latch,incdec_out;

initial begin
incdec_out = 16'h0101;
//address_latch = pc;
//#30 pc = incdec_out;
end

always@(negedge phi2)begin
if(rst)begin
bc <= 16'h0000;
de <= 16'h00AA;
hl <= 16'h0000;
wz <= 16'h0000;
pc <= 16'h0100;
sp <= 16'h0000;
address_latch <= 16'h0100;
outreg <= 16'h0000;
carry_out <= 1'b0;
end
end

always@(posedge rreg_wr,posedge dreg_wr)begin
if(bc_rw) bc[7:0] <= regbusr;
else if(de_rw) de[7:0] <= regbusr;
else if(hl_rw) hl[7:0] <= regbusr;
else if(wz_rw) wz[7:0] <= regbusr;
else if(pc_rw) pc[7:0] <= regbusr;
else if(sp_rw) sp[7:0] <= regbusr;
end

always@(posedge lreg_wr,posedge dreg_wr)begin
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
if(bc_rw) address_latch <= bc;
else if(de_rw) address_latch <= de;
else if(hl_rw) address_latch <= hl;
else if(wz_rw) address_latch <= wz;
else if(pc_rw) address_latch <= pc;
else if(sp_rw) address_latch <= sp;
end

always@(address_latch)begin
if(dreg_inc&&!dreg_dec)begin
	if(dreg_cnt&&!dreg_cnt2) {carry_out,incdec_out} <= address_latch + 16'h0001;
	else if(!dreg_cnt&&dreg_cnt2) {carry_out,incdec_out} <= address_latch + 16'h0002;
end else if(!dreg_inc&&dreg_dec)begin
	if(dreg_cnt&&!dreg_cnt2) {carry_out,incdec_out} <= address_latch - 16'h0001;
	else if(!dreg_cnt&&dreg_cnt2) {carry_out,incdec_out} <= address_latch - 16'h0002;
end
end

always@(/*negedge clk,*/posedge phi1)begin
	if(!rreg_rd&&lreg_rd) datao <= outreg[15:8];
	else if(rreg_rd&&!lreg_rd) datao <= outreg[7:0];
	else datao <= 8'bzzzzzzzz;

	ADDRESS <= address_latch;
end

assign data_latchl = dreg_wr ? incdec_out[15:8] : DATA;
assign regbusl = ((!rreg_wr&&lreg_wr)||dreg_wr) ? data_latchl : 8'bzzzzzzzz;
assign data_latchr = dreg_wr ? incdec_out[7:0] : DATA;
assign regbusr = ((rreg_wr&&!lreg_wr)||dreg_wr) ? data_latchr : 8'bzzzzzzzz;

assign DATA = (rreg_rd || lreg_rd)?datao : 8'bzzzzzzzz;

//assign ADDRESS = address_latch;
endmodule