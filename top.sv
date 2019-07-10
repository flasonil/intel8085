module top
(
	input logic rst,clk,
	//input logic [7:0] data,
	//REGISTER FILE CONTROL
//	input logic bc_rw,de_rw,hl_rw,wz_rw,pc_rw,sp_rw,
//	input logic rreg_rd,lreg_rd,rreg_wr,lreg_wr,
//	input logic dreg_wr,dreg_rd,dreg_inc,dreg_dec,dreg_cnt,dreg_cnt2,

	//ALU CONTROL
//	input logic select_op1,select_op2,select_neg,select_ncarry_1,select_shift_right,
//	input logic shift_right_in,
//	input logic dbus_to_act,a_to_act,alu_to_a,sel_alu_a,alu_a_to_dbus,write_dbus_to_alu_tmp,
//	input logic sel_0_fe,fe_0_to_act,
//
	//CONTROL MEMORY/IO FROM TESTBENCH
	input logic S0,
	input logic S1,
	input logic IOMn,
	input logic RDn,
	input logic WRn,
	input logic ALE,
//
//	//CONTROL MEMORY/IO
//	output logic S0,
//	output logic S1,
//	output logic IOMn,
//	output logic RDn,
//	output logic WRn,
//	output logic ALE,
//
	//INSTR REG CONTROL
	input logic dbus_to_instr_reg,


	output logic [7:0] haddress,
	inout logic [7:0] laddress_data
);
wire [7:0] dbus; //DBUS
logic [7:0] instruction_register,data_out;
logic [15:0] address;

logic [30:0] control;
logic [7:0] microcode_pc;

initial begin
control = 31'b0000000000000000000000000000000;
end

always@(negedge dbus_to_instr_reg)begin
	if(instruction_register == 8'h43) microcode_pc <= 8'h00;
end

always@(posedge clk,negedge clk)begin
	if(!dbus_to_instr_reg) microcode_pc++;
	case(microcode_pc)
	`include "rommicrocode.rom"
	endcase
end

always@(negedge clk)begin
	if(dbus_to_instr_reg) instruction_register <= dbus;
end

assign dbus = (dbus_to_instr_reg) ? laddress_data : 8'bzzzzzzzz;

registerfile U1(
	.ADDRESS(address),
	.clk(clk),
	.rst(rst),
	.DATA(dbus),
	.bc_rw(/*bc_rw*/control[1]),
	.de_rw(/*de_rw*/control[2]),
	.hl_rw(/*hl_rw*/control[3]),
	.wz_rw(/*wz_rw*/control[4]),
	.pc_rw(/*pc_rw*/control[5]),
	.sp_rw(/*sp_rw*/control[6]),
	.rreg_rd(/*rreg_rd*/control[7]),
	.lreg_rd(/*lreg_rd*/control[8]),
	.rreg_wr(/*rreg_wr*/control[9]),
	.lreg_wr(/*lreg_wr*/control[10]),
	.dreg_wr(/*dreg_wr*/control[11]),
	.dreg_rd(/*dreg_rd*/control[12]),
	.dreg_inc(/*dreg_inc*/control[13]),
	.dreg_dec(/*dreg_dec*/control[14]),
	.dreg_cnt(/*dreg_cnt*/control[15]),
	.dreg_cnt2(/*dreg_cnt2*/control[16])
);

aluplusreg U2(
	.clk(clk),
	.select_op1(/*select_op1*/control[17]),
	.select_op2(/*select_op2*/control[18]),
	.select_neg(/*select_neg*/control[19]),
	.select_ncarry_1(/*select_ncarry_1*/control[20]),
	.select_shift_right(/*select_shift_right*/control[21]),
	.shift_right_in(/*shift_right_in*/control[22]),
	.dbus_to_act(/*dbus_to_act*/control[23]),
	.a_to_act(/*a_to_act*/control[24]),
	.alu_to_a(/*alu_to_a*/control[25]),
	.sel_alu_a(/*sel_alu_a*/control[26]),
	.alu_a_to_dbus(/*alu_a_to_dbus*/control[27]),
	.write_dbus_to_alu_tmp(/*write_dbus_to_alu_tmp*/control[28]),
	.sel_0_fe(/*sel_0_fe*/control[29]),
	.fe_0_to_act(/*fe_0_to_act*/control[30]),

	.dbus_tmp(dbus),
	.dbus_act(dbus),
	.flagdbus(dbus),
	.aluacc_dbus(dbus)

);

//assign S0 = S0tb;
//assign S1 = S1tb;
//assign IOMn = IOMntb;
//assign ALE = ALEtb;
//assign RDn = RDntb;
//assign WRn = WRntb;
always@(posedge ALE)begin
 data_out <= 8'h00;
end

assign laddress_data = ((!WRn&!IOMn&RDn)|ALE) ? data_out : 8'bzzzzzzzz;
assign haddress = address[15:8];

endmodule




