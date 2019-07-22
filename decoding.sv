`define ins_skp_rx 5
`define ins_skp_r1 4
`define ins_lng 3
`define ins_e1 2
`define ins_e2 1
`define ins_e3 0

`define T1 	7'b1000000
`define T2 	7'b0100000
`define T3 	7'b0010000
`define T4 	7'b0001000
`define T5 	7'b0000100
`define T6 	7'b0000010
`define Treset 	7'b0000001

`define M1	5'b10000
`define R1	5'b01000
`define R2	5'b00100
`define W1	5'b00010
`define W2	5'b00001

`define reg_b	3'b000
`define reg_c	3'b001
`define reg_d	3'b010
`define reg_e	3'b011
`define reg_h	3'b100
`define reg_l	3'b101

module decoding
(
	input logic phi1,phi2,reset,
	input logic [7:0] next_instruction,
	output logic[35:0] control,

//	output logic S0,
//	output logic S1,
//	output logic IOMn,
//	output logic RDn,
//	output logic WRn,
	output logic ALE,

	output logic bc_rw,de_rw,hl_rw,pc_rw,
	output logic dreg_wr,dreg_rd,
	output logic lreg_rd,rreg_rd,lreg_wr,rreg_wr,
	output logic dreg_cnt,dreg_inc,
	output logic dbus_to_instr_reg,
	output logic write_dbus_to_alu_tmp,sel_alu_a,alu_a_to_dbus,
	output logic sel_0_fe,select_ncarry_1
);

logic hld_cyc,nxt_ins,m1_end;
logic bc_s,de_s,hl_s;
logic bc_d,de_d,hl_d;

logic[4:0] current_mc/* = {ins_m1,ins_r1,ins_r2,ins_w1,ins_w2}*/;
logic[4:0] next_mc/* = {ins_m1,ins_r1,ins_r2,ins_w1,ins_w2}*/;

logic[6:0] current_t/* = {t1,t2,t3,t4,t5,t6,t_reset}*/;
logic[6:0] next_t/* = {t1,t2,t3,t4,t5,t6,t_reset}*/;

logic[7:0] microcode_pc,instruction;

logic[47:0] group;
logic[5:0] timing;

initial begin
current_mc = `M1;
next_mc = `M1;
current_t = 7'b0000001;
next_t = 7'b1000000;
microcode_pc = 8'b00000000;
end

decode decode(.instr(instruction),.gr(group));
timingrom timingrom(.group(group),.timing(timing));

always@(posedge phi2)begin
if(current_t[3])begin
	bc_s <= (~instruction[2]&~instruction[1]&~instruction[0])|(~instruction[2]&~instruction[1]&instruction[0]);
	de_s <= (~instruction[2]&instruction[1]&~instruction[0])|(~instruction[2]&instruction[1]&instruction[0]);
	hl_s <= (instruction[2]&~instruction[1]&~instruction[0])|(instruction[2]&~instruction[1]&instruction[0]);
	bc_d <= (~instruction[5]&~instruction[4]&~instruction[3])|(~instruction[5]&~instruction[4]&instruction[3]);
	de_d <= (~instruction[5]&instruction[4]&~instruction[3])|(~instruction[5]&instruction[4]&instruction[3]);
	hl_d <= (instruction[5]&~instruction[4]&~instruction[3])|(instruction[5]&~instruction[4]&instruction[3]);
end
end

always@(posedge phi2)begin
	if(reset)begin
	next_t <= `Treset;
	end
	else begin
		case(next_mc)
		`M1:begin
			case(next_t)
			`Treset: next_t <= `T1;

			`T1: next_t <= `T2;
			`T2: next_t <= `T3;
			`T3: begin
				next_t <= `T4;			
			end
			`T4:begin
				if(timing[`ins_lng])next_t <= `T5;
				else begin 
					next_t <= `T1;
					if(timing[`ins_skp_rx]) next_mc <= `W1;
					else if(timing[`ins_skp_r1]) next_mc <= `R2;
					else if(timing[`ins_e1]&timing[`ins_e2]&timing[`ins_e3]) next_mc <= `M1;
				end
			end
			`T5: next_t <= `T6;
			`T6: next_t <= `T1; //NEXT MC ?
			endcase
		end
		`R1:begin
			case(next_t)
			`T1: next_t <= `T2;
			`T2: next_t <= `T3;
			`T3:begin
				next_t <= `T1;
				if(timing[`ins_e1]&~timing[`ins_e2]&~timing[`ins_e3]) next_mc <= `M1;
				else next_mc <= `R2;
			end
			endcase
		end
		`R2:begin
			case(next_t)
			`T1: next_t <= `T2;
			`T2: next_t <= `T3;
			`T3:begin
				next_t <= `T1;
				if(timing[`ins_e1]&~timing[`ins_e2]&timing[`ins_e3]) next_mc <= `M1;
				else next_mc <= `W1;
			end
			endcase
		end
		`W1:begin
			case(next_t)
			`T1: next_t <= `T2;
			`T2: next_t <= `T3;
			`T3:begin
				next_t <= `T1;
				if(timing[`ins_e1]&timing[`ins_e2]&~timing[`ins_e3]) next_mc <= `M1;
				else next_mc <= `W2;
			end
			endcase
		end
		`W2:begin
			case(next_t)
			`T1: next_t <= `T2;
			`T2: next_t <= `T3;
			`T3:begin
				next_t <= `T1;
				if(~timing[`ins_e1]&timing[`ins_e2]&timing[`ins_e3]) next_mc <= `M1;
			end
			endcase
		end
		endcase
	end
end

always@(posedge phi1)begin
	if(next_t[3]) instruction <= next_instruction;
	current_t <= next_t;
	current_mc <= next_mc;
	hld_cyc = (~reset&~m1_end&~(next_t[4]&~next_mc[4]));
	nxt_ins = (((next_mc[3]&~timing[`ins_e2]&~timing[`ins_e3])|(next_mc[2]&~timing[`ins_e2]&timing[`ins_e3])|(next_mc[1]&timing[`ins_e2]&~timing[`ins_e3]))&next_t[4])|reset|(m1_end&timing[`ins_e1]&timing[`ins_e2]&timing[`ins_e3]);
end
assign m1_end = next_t[1]|(next_t[3]&~timing[`ins_lng]);

always@(posedge phi1)begin
	if(reset) microcode_pc <= 1'b0;
	else if(next_t != 7'b0000001) begin
		if(current_t[4]) microcode_pc = 10;
		else microcode_pc++ ;
	end
	case(microcode_pc)
	`include "rommicrocode.rom"
	endcase
end

assign bc_rw =	((/*reg_op_s*/control[1]&current_mc[4]&(current_t[6]&next_t[5])&bc_s)|(/*reg_op_d*/control[2]&current_mc[4]&(current_t[4]&next_t[3])&bc_d));
assign de_rw =	((/*reg_op_s*/control[1]&current_mc[4]&(current_t[6]&next_t[5])&de_s)|(/*reg_op_d*/control[2]&current_mc[4]&(current_t[4]&next_t[3])&de_d));
assign hl_rw =	((/*reg_op_s*/control[1]&current_mc[4]&(current_t[6]&next_t[5])&hl_s)|(/*reg_op_d*/control[2]&current_mc[4]&(current_t[4]&next_t[3])&hl_d));
assign pc_rw = control[4]&phi2;
assign dreg_wr = control[10]&phi2;
assign dreg_rd = control[11]&phi2&current_t[3];
assign dreg_cnt = control[14]&phi2&current_t[3];
assign dreg_inc = control[12]&phi2&current_t[3];
assign lreg_rd = /*reg_op_s*/control[1]&/*high registers cond*/((~instruction[2]&~instruction[1]&~instruction[0])|(~instruction[2]&instruction[1]&~instruction[0])|(instruction[2]&~instruction[1]&~instruction[0]))&/*timing cond*/((current_t[6]&next_t[5])|(current_t[5]&next_t[5]));
assign rreg_rd = /*reg_op_s*/control[1]&/*low registers cond*/((~instruction[2]&~instruction[1]&instruction[0])|(~instruction[2]&instruction[1]&instruction[0])|(instruction[2]&~instruction[1]&instruction[0]))&/*timing cond*/((current_t[6]&next_t[5])|(current_t[5]&next_t[5]));
assign lreg_wr = control[9]&current_t[4]&next_t[3];
assign rreg_wr = control[8]&phi2;
assign dbus_to_instr_reg = control[0]&phi1&next_t[4];
assign write_dbus_to_alu_tmp = control[27]&current_t[5]&next_t[5];
assign sel_0_fe = control[28]&current_t[5]&next_t[5];
assign select_ncarry_1 = control[19]&current_t[5]&next_t[5];
assign sel_alu_a = control[25]&current_t[4]&next_t[3];
assign alu_a_to_dbus = control[26]&current_t[4]&next_t[3];

assign ALE = control[35]&phi1&next_t[6];

endmodule

module decode
(
	input logic [7:0] instr,
	output logic [47:0] gr
);

assign ins_m1 = instr[5] & instr[4] & ~instr[3];
assign ins_m2 = instr[2] & instr[1] & ~instr[0];

assign gr[0] = instr[7] & instr[6] & instr[5] & instr[4] & ~instr[2] & instr[1] & instr[0];
assign gr[1] = (instr[7] & ~instr[6]) & ~ins_m2;
assign gr[2] = instr[7] & instr[6] & ins_m2;
assign gr[3] = ~instr[7] & ~instr[6] & instr[5] & ~instr[3] & ~instr[2] & ~instr[1] & ~instr[0];
assign gr[4] = instr[7] & ~instr[6] & ins_m2;
assign gr[5] = instr[7] & instr[6] & instr[2] & instr[1] & instr[0];
assign gr[6] = ~instr[7] & ~instr[6] & instr[5] & instr[2] & instr[1] & instr[0];
assign gr[7] = instr[7] & instr[6] & ~instr[5] & ~instr[4] & instr[3] & ~instr[2] & instr[1] & instr[0];

assign gr[8] = ~instr[7] & ~instr[6] & instr[5] & instr[4] & ~instr[3] & ~instr[2] & instr[1] & ~instr[0];
assign gr[9] = ~instr[7] & ~instr[6] & instr[5] & instr[4] & instr[3] & ~instr[2] & instr[1] & ~instr[0];
assign gr[10] = instr[7] & instr[6] & ~instr[5] & instr[4] & instr[3] & ~instr[2] & ~instr[1] & instr[0];
assign gr[11] = instr[7] & instr[6] & instr[5] & ~instr[4] & instr[3] & instr[2] & ~instr[1] & instr[0];
assign gr[12] = ~instr[7] & ~instr[6] & instr[5] & ~instr[4] & ~instr[3] & ~instr[2] & instr[1] & ~instr[0];
assign gr[13] = ~instr[7] & ~instr[6] & instr[5] & ~instr[4] & instr[3] & ~instr[2] & instr[1] & ~instr[0];
assign gr[14] = (~instr[7] & ~instr[6] & ins_m2) & ~ins_m1;
assign gr[15] = instr[7] & instr[6] & ~instr[5] & instr[4] & instr[3] & ~instr[2] & instr[1] & instr[0];

assign gr[16] = ~instr[7] & ~instr[6] & ins_m1 & ins_m2;
assign gr[17] = instr[7] & instr[6] & ~instr[5] & instr[4] & ~instr[3] & ~instr[2] & instr[1] & instr[0];
assign gr[18] = instr[7] & instr[6] & ~instr[5] & ~instr[4] & instr[3] & ~instr[2] & ~instr[1] & instr[0];
assign gr[19] = instr[7] & instr[6] & ~instr[2] & ~instr[1] & ~instr[0];
assign gr[20] = ~instr[7] & ~instr[6] & instr[3] & ~instr[2] & ~instr[1] & instr[0];
assign gr[21] = ~instr[7] & ~instr[6] & ~instr[5] & ~instr[4] & instr[3] & ~instr[2] & ~instr[1] & ~instr[0];
assign gr[22] = ~instr[7] & ~instr[6] & ~instr[5] & instr[4] & instr[3] & ~instr[2] & ~instr[1] & ~instr[0];
assign gr[23] = ~instr[7] & ~instr[6] & instr[5] & instr[3] & ~instr[2] & ~instr[1] & ~instr[0];

assign gr[24] = ~instr[7] & ~instr[6] & ~instr[5] & instr[4] & ~instr[3] & ~instr[2] & ~instr[1] & ~instr[0];
assign gr[25] = ~instr[7] & ~instr[6] & ~instr[5] & instr[2] & instr[1] & instr[0];
assign gr[26] = instr[7] & instr[6] & ~instr[3] & instr[2] & ~instr[1] & instr[0];
assign gr[27] = instr[7] & instr[6] & ~instr[3] & ~instr[2] & ~instr[1] & instr[0];
assign gr[28] = instr[7] & instr[6] & instr[5] & instr[4] & instr[3] & ~instr[2] & ~instr[1] & instr[0];
assign gr[29] = instr[7] & instr[6] & ~instr[2] & instr[1] & ~instr[0];
assign gr[30] = instr[7] & instr[6] & ~instr[5] & ~instr[4] & ~instr[3] & ~instr[2] & instr[1] & instr[0];
assign gr[31] = instr[7] & instr[6] & instr[4] & instr[3] & instr[2] & ~instr[1] & instr[0];

assign gr[32] = instr[7] & instr[6] & instr[5] & ~instr[4] & instr[3] & ~instr[2] & ~instr[1] & instr[0];
assign gr[33] = instr[7] & instr[6] & instr[2] & ~instr[1] & ~instr[0];
assign gr[34] = instr[7] & instr[6] & ~instr[5] & ~instr[4] & instr[3] & instr[2] & ~instr[1] & instr[0];
assign gr[35] = instr[7] & instr[6] & instr[5] & ~instr[4] & ~instr[3] & ~instr[2] & instr[1] & instr[0];
assign gr[36] = ~instr[7] & ~instr[6] & ~instr[3] & ~instr[2] & instr[1] & instr[0];
assign gr[37] = ~instr[7] & ~instr[6] & instr[3] & ~instr[2] & instr[1] & instr[0];
assign gr[38] = (~instr[7] & ~instr[6]) & (~ins_m1) & (instr[2] & ~instr[1]);
assign gr[39] = ~instr[7] & ~instr[6] & instr[5] & instr[4] & ~instr[3] & instr[2] & ~instr[1];

assign gr[40] = ~instr[7] & ~instr[6] & ~instr[5] & ~instr[3] & ~instr[2] & instr[1] & ~instr[0];
assign gr[41] = ~instr[7] & ~instr[6] & ~instr[5] & instr[3] & ~instr[2] & instr[1] & ~instr[0];
assign gr[42] =  ~instr[7] & ~instr[6] & ~instr[3] & ~instr[2] & ~instr[1] & instr[0];
assign gr[43] = (~instr[7] & instr[6] & instr[5] & instr[4] & ~instr[3]) & ~ins_m2;
assign gr[44] = (~instr[7] & instr[6]) & ~ins_m1 & ins_m2;
assign gr[45] = ~instr[7] & instr[6] & ~ins_m1 & ~ins_m2;
assign gr[46] = instr[7] & instr[6] & instr[5] & ~instr[4] & instr[3] & ~instr[2] & instr[1] & instr[0];
assign gr[47] = ~instr[7] & instr[6] & instr[5] & instr[4] & instr[3] & ~instr[2] & ~instr[1] & instr[0];

endmodule

module timingrom
(
	input logic [47:0] group,
	output logic [5:0] timing
);

always_comb begin
case(group)
	48'b001000000000000000000000000000000000000000000000: timing = 6'b000111;
endcase
end

endmodule
