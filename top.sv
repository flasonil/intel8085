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
logic dreg_wr,bc_rw,de_rw,hl_rw,pc_rw;
logic lreg_rd,rreg_rd,lreg_wr,rreg_wr;
logic write_dbus_to_alu_tmp,sel_alu_a,alu_a_to_dbus,alu_to_a;
logic sel_0_fe,select_ncarry_1,fe_0_to_act;
logic datapin_dbus_tmp;
logic xchg,xchg_status;

logic phi1,phi2,reset;
logic[14:0] control;

wire [7:0] dbus; //DBUS
logic [7:0] instruction_register,data_out;
logic [15:0] address;

always@(dbus or dbus_to_instr_reg)begin
	if(dbus_to_instr_reg) instruction_register <= dbus;
end

//XCHG STATUS: 0 --> HL = HL, DE = DE	1 --> HL = DE, DE = HL
initial xchg_status = 1'b0;
always@(posedge xchg) xchg_status <= ~xchg_status;

clockgen clockgen(.x1(x1),.x2(x2),.resetn_in(resetn_in),.phi1(phi1),.phi2(phi2),.reset(reset),.clk_out(clk_out),.reset_out(reset_out));

decoding decoding(
	.phi1(phi1),
	.phi2(phi2),
	.reset(reset),
	.control(control),
//	.S1(S1),
//	.S0(S0),
	.WRn(WRn),
	.RDn(RDn),
	.ALE(ALE),
//	.IOMn(IOMn),
	.xchg(xchg),
	.dreg_wr(dreg_wr),
	.dreg_rd(dreg_rd),
	.dreg_cnt(dreg_cnt),
	.dreg_inc(dreg_inc),
	.lreg_wr(lreg_wr),
	.rreg_wr(rreg_wr),
	.lreg_rd(lreg_rd),
	.rreg_rd(rreg_rd),
	.bc_rw(bc_rw),
	.de_rw(de_rw),
	.hl_rw(hl_rw),
	.pc_rw(pc_rw),
	.dbus_to_instr_reg(dbus_to_instr_reg),
	.write_dbus_to_alu_tmp(write_dbus_to_alu_tmp),
	.datapin_dbus_tmp(datapin_dbus_tmp),
	.next_instruction(instruction_register),
	.sel_0_fe(sel_0_fe),
	.select_ncarry_1(select_ncarry_1),
	.fe_0_to_act(fe_0_to_act),
	.sel_alu_a(sel_alu_a),
	.alu_a_to_dbus(alu_a_to_dbus),
	.alu_to_a(alu_to_a)
);

registerfile registerfile(
	.rst(reset),
	.ADDRESS(address),
	.phi1(phi1),
	.phi2(phi2),
	.DATA(dbus),
	.bc_rw(bc_rw),
	.de_rw(/*de_rw*/xchg_status?hl_rw:de_rw),
	.hl_rw(/*hl_rw*/xchg_status?de_rw:hl_rw),
	.wz_rw(/*wz_rw*//*control[3]*/1'b0),
	.pc_rw(pc_rw/*control[4]*/),
	.sp_rw(/*sp_rw*//*control[5]*/1'b0),
	.rreg_rd(rreg_rd/*control[6]*/),
	.lreg_rd(lreg_rd/*control[7]*/),
	.rreg_wr(rreg_wr/*control[8]*/),
	.lreg_wr(lreg_wr/*control[9]*/),
	.dreg_wr(dreg_wr/*control[10]*/),
	.dreg_rd(dreg_rd/*control[11]*/),
	.dreg_inc(dreg_inc/*control[12]*/),
	.dreg_dec(/*dreg_dec*//*control[13]*/1'b0),
	.dreg_cnt(dreg_cnt/*control[14]*/),
	.dreg_cnt2(/*dreg_cnt2*//*control[15]*/1'b0)
);

aluplusreg aluplusreg(
	.phi1(phi1),
	.phi2(phi2),
	.rst(reset),
	.select_op1(/*select_op1*//*control[16]*/1'b0),
	.select_op2(/*select_op2*//*control[17]*/1'b0),
	.select_neg(/*select_neg*//*control[18]*/1'b0),
	.select_ncarry_1(select_ncarry_1/*control[19]*/),
	.select_shift_right(/*select_shift_right*//*control[20]*/1'b0),
	.shift_right_in(/*shift_right_in*//*control[21]*/1'b0),
	.dbus_to_act(/*dbus_to_act*//*control[22]*/1'b0),
	.a_to_act(/*a_to_act*//*control[23]*/1'b0),
	.alu_to_a(alu_to_a/*control[24]*/),
	.sel_alu_a(sel_alu_a/*control[25]*/),
	.alu_a_to_dbus(alu_a_to_dbus/*control[26]*/),
	.write_dbus_to_alu_tmp(write_dbus_to_alu_tmp/*control[27]*/),
	.sel_0_fe(sel_0_fe/*control[28]*/),
	.fe_0_to_act(fe_0_to_act/*control[29]*/),

	.dbus_tmp(dbus),
	.dbus_act(dbus),
	.flagdbus(dbus),
	.aluacc_dbus(dbus)

);

always_comb begin
 if(ALE) data_out <= address[7:0];
 else if(!WRn) data_out <= dbus;
end

assign dbus = (dbus_to_instr_reg|datapin_dbus_tmp) ? laddress_data : 8'bzzzzzzzz;
assign laddress_data = ((RDn&!IOMn&!WRn)|ALE) ? data_out : 8'bzzzzzzzz;
assign haddress = address[15:8];

assign S0 = control[9];
assign S1 = control[10];
assign IOMn = control[11];

endmodule
