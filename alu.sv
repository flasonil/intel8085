module onebitalu
(
	input logic in1,in2,in2n,
	input logic /*zero_in,*/parity_in,carry_in,
	input logic select_op1,select_op2,select_neg,select_ncarry_1,select_shift_right,
	input logic shift_right_in,

	output logic /*zero_out,*/parity_out,carry_out,

	output logic out
);
wire negation,operation;

assign negation = ~((~select_neg&in2n)|(select_neg&in2));
assign operation = ~(~(select_op1&in1&negation)&(select_op2|negation|in1));
assign out = ~((operation&carry_in)|(~(operation|carry_in|(select_shift_right&shift_right_in))));

assign parity_out = ~((out&parity_in)|(~(out|parity_in)));
assign carry_out = ~(select_op2|(~(select_ncarry_1|(~(negation&in1&select_op1))))|(~(select_ncarry_1|carry_in|operation)));

endmodule

module alu8bit
(
	input logic [7:0] in1,in2,
	input logic carry_in,
	input logic select_op1,select_op2,select_neg,select_ncarry_1,select_shift_right,
	input logic shift_right_in,

	output logic [7:0] out,
	output logic zero_out,parity_out,carry_out,aux_carry
);
wire zero1,parity1,carry1,zero2,parity2,carry2,zero3,parity3,carry3,zero4,parity4,carry4,zero5,parity5,carry5,zero6,parity6,carry6,zero7,parity7,carry7;

onebitalu alu0(.in1(in1[0]),.in2(in2[0]),.in2n(~in2[0]),.out(out[0]),.select_op1(select_op1),.select_op2(select_op2),.select_neg(select_neg),.select_ncarry_1(select_ncarry_1),.select_shift_right(select_shift_right),.shift_right_in(shift_right_in),.carry_in(carry_in),.carry_out(carry1),.parity_in(1'b0),.parity_out(parity1));
onebitalu alu1(.in1(in1[1]),.in2(in2[1]),.in2n(~in2[1]),.out(out[1]),.select_op1(select_op1),.select_op2(select_op2),.select_neg(select_neg),.select_ncarry_1(select_ncarry_1),.select_shift_right(select_shift_right),.shift_right_in(shift_right_in),.carry_in(carry1),.carry_out(carry2),.parity_in(parity1),.parity_out(parity2));
onebitalu alu2(.in1(in1[2]),.in2(in2[2]),.in2n(~in2[2]),.out(out[2]),.select_op1(select_op1),.select_op2(select_op2),.select_neg(select_neg),.select_ncarry_1(select_ncarry_1),.select_shift_right(select_shift_right),.shift_right_in(shift_right_in),.carry_in(carry2),.carry_out(carry3),.parity_in(parity2),.parity_out(parity3));
onebitalu alu3(.in1(in1[3]),.in2(in2[3]),.in2n(~in2[3]),.out(out[3]),.select_op1(select_op1),.select_op2(select_op2),.select_neg(select_neg),.select_ncarry_1(select_ncarry_1),.select_shift_right(select_shift_right),.shift_right_in(shift_right_in),.carry_in(carry3),.carry_out(carry4),.parity_in(parity3),.parity_out(parity4));
onebitalu alu4(.in1(in1[4]),.in2(in2[4]),.in2n(~in2[4]),.out(out[4]),.select_op1(select_op1),.select_op2(select_op2),.select_neg(select_neg),.select_ncarry_1(select_ncarry_1),.select_shift_right(select_shift_right),.shift_right_in(shift_right_in),.carry_in(carry4),.carry_out(carry5),.parity_in(parity4),.parity_out(parity5));
onebitalu alu5(.in1(in1[5]),.in2(in2[5]),.in2n(~in2[5]),.out(out[5]),.select_op1(select_op1),.select_op2(select_op2),.select_neg(select_neg),.select_ncarry_1(select_ncarry_1),.select_shift_right(select_shift_right),.shift_right_in(shift_right_in),.carry_in(carry5),.carry_out(carry6),.parity_in(parity5),.parity_out(parity6));
onebitalu alu6(.in1(in1[6]),.in2(in2[6]),.in2n(~in2[6]),.out(out[6]),.select_op1(select_op1),.select_op2(select_op2),.select_neg(select_neg),.select_ncarry_1(select_ncarry_1),.select_shift_right(select_shift_right),.shift_right_in(shift_right_in),.carry_in(carry6),.carry_out(carry7),.parity_in(parity6),.parity_out(parity7));
onebitalu alu7(.in1(in1[7]),.in2(in2[7]),.in2n(~in2[7]),.out(out[7]),.select_op1(select_op1),.select_op2(select_op2),.select_neg(select_neg),.select_ncarry_1(select_ncarry_1),.select_shift_right(select_shift_right),.shift_right_in(shift_right_in),.carry_in(carry7),.carry_out(carry_out),.parity_in(parity7),.parity_out(parity_out));

assign zero_out = ~(out[0]|out[1]|out[2]|out[3]|out[4]|out[5]|out[6]|out[7]);

endmodule

module aluplusreg
(
	input logic phi1,phi2,rst,
	input logic select_op1,select_op2,select_neg,select_ncarry_1,select_shift_right,
	input logic shift_right_in,
	input logic [7:0] dbus_tmp,dbus_act,
	inout logic [7:0] flagdbus,
	input logic dbus_to_act,a_to_act,alu_to_a,sel_alu_a,alu_a_to_dbus,write_dbus_to_alu_tmp,
	input logic sel_0_fe,fe_0_to_act,
	
	output logic [7:0] aluacc_dbus
);
logic [7:0] accumulator,act,tmp,alures,alures_acc,flag_register;

alu8bit alu(
	.in1(act),.in2(tmp),.out(alures),.carry_in(1'b1),
	.select_op1(select_op1),
	.select_op2(select_op2),
	.select_neg(select_neg),
	.select_ncarry_1(select_ncarry_1),
	.select_shift_right(select_shift_right),
	.shift_right_in(shift_right_in)
);

always@(negedge phi2)begin
if(rst)begin
accumulator <= 8'hcc;
//act <= 8'h00;
tmp <= 8'h00;
end
end

always@(sel_0_fe)begin
if(!sel_0_fe)begin
	if(dbus_to_act) act <= dbus_act;
	else if(a_to_act) act <= accumulator;
end else if(sel_0_fe)begin
		if(fe_0_to_act) act <= 8'hfe;
		else if(!fe_0_to_act) act <= 8'h00;
	end
end
always@(alures or alu_to_a)begin
	if(alu_to_a) accumulator <= alures;
end
always@(write_dbus_to_alu_tmp)begin
	if(write_dbus_to_alu_tmp) tmp <= dbus_tmp;
end

assign alures_acc = sel_alu_a ? /*1*/alures : /*0*/accumulator;
assign aluacc_dbus = alu_a_to_dbus ? alures_acc : 8'bzzzzzzzz;
endmodule


