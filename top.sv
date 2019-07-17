module top
(
	input logic x1,x2,resetn_in,

	output logic [7:0] haddress,
	inout logic [7:0] laddress_data,

	output logic S0,
	output logic S1,
	output logic IOMn,
	output logic RDn,
	output logic WRn,
	output logic ALE,

	output logic clk_out,reset_out
);
//logic S0int,S1int,RDnint,WRnint,ALEint,IOMnint,dbus_to_instr_reg;
logic dbus_to_instr_reg;

logic phi1,phi2,reset;
logic[36:0] control;

wire [7:0] dbus; //DBUS
logic [7:0] instruction_register,data_out;
logic [15:0] address;

always@(dbus or dbus_to_instr_reg)begin
	if(dbus_to_instr_reg) instruction_register <= dbus;
end

clockgen clockgen(.x1(x1),.x2(x2),.resetn_in(resetn_in),.phi1(phi1),.phi2(phi2),.reset(reset),.clk_out(clk_out),.reset_out(reset_out));

decoding decoding(
	.phi1(phi1),
	.phi2(phi2),
	.reset(reset),
	.control(control),
//	.S1(S1),
//	.S0(S0),
//	.WRn(WRn),
//	.RDn(RDn),
//	.ALE(ALE),
//	.IOMn(IOMn),
	.dbus_to_instr_reg(dbus_to_instr_reg),
	.instruction(instruction_register)
);

registerfile registerfile(
	.rst(reset),
	.ADDRESS(address),
	.phi1(phi1),
	.phi2(phi2),
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
	.phi1(phi1),
	.phi2(phi2),
	.rst(reset),
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

always@(posedge control[36])begin
 data_out <= address[7:0];
end

assign dbus = (dbus_to_instr_reg) ? laddress_data : 8'bzzzzzzzz;
assign laddress_data = ((!control[35]&!control[33]&control[34])|control[36]) ? data_out : 8'bzzzzzzzz;
assign haddress = address[15:8];

assign S0 = control[31];
assign S1 = control[32];
assign IOMn = control[33];
assign RDn = control[34];
assign WRn = control[35];
assign ALE = control[36];
endmodule
