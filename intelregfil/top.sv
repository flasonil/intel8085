module top
(
	input logic rst,clk,
	//input logic [7:0] data,
	//REGISTER FILE CONTROL
	input logic bc_rw,de_rw,hl_rw,wz_rw,pc_rw,sp_rw,
	input logic rreg_rd,lreg_rd,rreg_wr,lreg_wr,
	input logic dreg_wr,dreg_rd,dreg_inc,dreg_dec,dreg_cnt,dreg_cnt2,

	//ALU CONTROL
	input logic select_op1,select_op2,select_neg,select_ncarry_1,select_shift_right,
	input logic shift_right_in,
	input logic dbus_to_act,a_to_act,alu_to_a,sel_alu_a,alu_a_to_dbus,write_dbus_to_alu_tmp,
	input logic sel_0_fe,fe_0_to_act,

	//INSTR REG CONTROL
	input logic dbus_to_instr_reg,
	output logic [15:0] address
);
wire [7:0] data; //DBUS
logic [7:0] instruction_register;

always@(posedge dbus_to_instr_reg)begin
	instruction_register <= data;
end

assign data = /*(!dreg_wr&&(lreg_wr||rreg_wr))&&*/(dbus_to_instr_reg) ? 8'h43 : 8'bzzzzzzzz;

registerfile U1(
	.ADDRESS(address),
	.clk(clk),
	.rst(rst),
	.DATA(data),
	.bc_rw(bc_rw),
	.de_rw(de_rw),
	.hl_rw(hl_rw),
	.wz_rw(wz_rw),
	.pc_rw(pc_rw),
	.sp_rw(sp_rw),
	.rreg_rd(rreg_rd),
	.lreg_rd(lreg_rd),
	.rreg_wr(rreg_wr),
	.lreg_wr(lreg_wr),
	.dreg_wr(dreg_wr),
	.dreg_rd(dreg_rd),
	.dreg_inc(dreg_inc),
	.dreg_dec(dreg_dec),
	.dreg_cnt(dreg_cnt),
	.dreg_cnt2(dreg_cnt2)
);

aluplusreg U2(
	.clk(clk),
	.select_op1(select_op1),
	.select_op2(select_op2),
	.select_neg(select_neg),
	.select_ncarry_1(select_ncarry_1),
	.select_shift_right(select_shift_right),
	.shift_right_in(shift_right_in),
	.write_dbus_to_alu_tmp(write_dbus_to_alu_tmp),
	.dbus_tmp(data),
	.dbus_act(data),
	.flagdbus(data),
	.aluacc_dbus(data),
	.dbus_to_act(dbus_to_act),
	.alu_a_to_dbus(alu_a_to_dbus),
	.sel_alu_a(sel_alu_a),
	.a_to_act(a_to_act),
	.alu_to_a(alu_to_a),
	.sel_0_fe(sel_0_fe),
	.fe_0_to_act(fe_0_to_act)
);


endmodule
