`timescale 1ns/1ps

module testbench();
//REGISTER FILE CONTROL
//logic dreg_wr,dreg_rd;
//logic bc_rw,de_rw,hl_rw,wz_rw,pc_rw,sp_rw;
//logic rreg_rd,lreg_rd,rreg_wr,lreg_wr;
//logic dreg_inc,dreg_dec,dreg_cnt,dreg_cnt2;

//ALU CONTROL
//logic select_op1,select_op2,select_neg,select_ncarry_1,select_shift_right;
//logic shift_right_in;
//logic dbus_to_act,a_to_act,alu_to_a,sel_alu_a,alu_a_to_dbus,write_dbus_to_alu_tmp;
//logic sel_0_fe,fe_0_to_act;

logic dbus_to_instr_reg;

logic S0tb;
logic S1tb;
logic IOMntb;
logic RDntb;
logic WRntb;
logic ALEtb;

logic clk,rst;
logic [7:0] haddress;
wire [7:0] laddress_data;

system DUT(/*.laddress_data(laddress_data),*/
	/*.haddress(haddress),*/
	.clk(clk),.rst(rst),
	//REGISTER FILE CONTROL
//	.bc_rw(bc_rw),.de_rw(de_rw),.hl_rw(hl_rw),.wz_rw(wz_rw),.pc_rw(pc_rw),.sp_rw(sp_rw),
//	.rreg_rd(rreg_rd),.lreg_rd(lreg_rd),.rreg_wr(rreg_wr),.lreg_wr(lreg_wr),
//	.dreg_wr(dreg_wr),.dreg_rd(dreg_rd),
//	.dreg_inc(dreg_inc),.dreg_dec(dreg_dec),
//	.dreg_cnt(dreg_cnt),.dreg_cnt2(dreg_cnt2),
	//INSTRUCTION REGISTER CONTROL
	.dbus_to_instr_reg(dbus_to_instr_reg),
	//ALU CONTROL
//	.select_op1(select_op1),.select_op2(select_op2),.select_neg(select_neg),.select_ncarry_1(select_ncarry_1),.select_shift_right(select_shift_right),
//	.shift_right_in(shift_right_in),
//	.dbus_to_act(dbus_to_act),.a_to_act(a_to_act),.alu_to_a(alu_to_a),.sel_alu_a(sel_alu_a),.alu_a_to_dbus(alu_a_to_dbus),.write_dbus_to_alu_tmp(write_dbus_to_alu_tmp),
//	.sel_0_fe(sel_0_fe),
//	.fe_0_to_act(fe_0_to_act),
//
	.ALE(ALEtb),.RDn(RDntb),.WRn(WRntb),.IOMn(IOMntb),.S0(S0tb),.S1(S1tb)
);

always begin
#5 clk = !clk;
end

initial begin
clk = 1;
rst = 1;

//rreg_rd = 0;
//lreg_rd = 0;
//rreg_wr = 0;
//lreg_wr = 0;
//bc_rw = 0;
//de_rw = 0;
//hl_rw = 0;
//wz_rw = 0;
//pc_rw = 0;
//sp_rw = 0;
//dreg_wr = 0;
//dreg_rd = 0;
dbus_to_instr_reg = 0;
//dreg_inc = 0;
//dreg_dec = 0;
//dreg_cnt = 0;
//dreg_cnt2 = 0;
//
//select_op1 = 0;
//select_op2 = 0;
//select_neg = 0;
//select_ncarry_1 = 0;
//select_shift_right = 0;
//shift_right_in = 0;
//dbus_to_act = 0;
//a_to_act = 0;
//alu_to_a = 0;
//sel_alu_a = 0;
//alu_a_to_dbus = 0;
//write_dbus_to_alu_tmp = 0;
//sel_0_fe = 0;
//fe_0_to_act = 0;

S1tb = 1'b0;
S0tb = 1'b0;
ALEtb = 1'b0;
WRntb = 1'bz;
RDntb = 1'bz;
IOMntb = 1'bz;

#9 rst = 0;
// MOV R1 R2 TIMING
@(posedge clk);
@(negedge clk);			//T1/0
S1tb = 1'b1;
S0tb = 1'b1;
ALEtb = 1'b1;
WRntb = 1'b1;
RDntb = 1'b1;
IOMntb = 1'b0;
@(posedge clk);			//T1/1
ALEtb = 1'b0;
@(negedge clk);			//T2/0
RDntb = 1'b0;
@(posedge clk);			//T2/1
//pc_rw = 1;
//dreg_wr = 1;
dbus_to_instr_reg = 1;
@(negedge clk);
				//T3/0

//dreg_wr = 0;
@(posedge clk);			//T3/1
dbus_to_instr_reg = 0;
RDntb = 1'b1;
@(negedge clk);			//T4/0

@(posedge clk);			//T4/1
//pc_rw = 1;
//dreg_wr = 0;
//dreg_rd = 1;
//dreg_inc = 1;
//dreg_cnt = 1;
@(negedge clk);			//T1/0
//dreg_inc = 0;
//dreg_cnt = 0;

@(posedge clk);			//T1/1
//de_rw = 1;
//pc_rw = 0;
//rreg_rd = 1;
//dreg_rd = 0;


@(negedge clk);			//T2/0
//sel_0_fe = 1;
//fe_0_to_act = 0;
//select_ncarry_1 = 1;
//write_dbus_to_alu_tmp = 1;
@(posedge clk);			//T2/1
//rreg_rd = 0;
//write_dbus_to_alu_tmp = 0;
//pc_rw = 1;
//dreg_wr = 1;
//de_rw = 0;
//dreg_rd = 0;
@(negedge clk);			//T3/0
//dbus_to_instr_reg = 1;
//dreg_wr = 0;
@(posedge clk);			//T3/1
//dbus_to_instr_reg = 0;
//bc_rw = 1;
//alu_to_a = 0;
//sel_alu_a = 1;
//alu_a_to_dbus = 1;
//rreg_wr = 1;
//pc_rw = 0;
//dreg_wr = 0;
@(negedge clk);

@(posedge clk);
@(negedge clk);

@(posedge clk);
@(negedge clk);

@(posedge clk);
$stop;
end
assign laddress_data = (~RDntb & ~IOMntb) ? 8'h43 :8'bzzzzzzzz;
endmodule

