//	TO DO: reg_op_s/d e control[0] potrebbero essere inutili, migliorare leggibilità codice
//	Caricare in uscita dalla CPU il byte da scrivere in memoria
`define ins_skp_rx 5
`define ins_skp_r1 4
`define ins_lng 3
`define ins_e1 2
`define ins_e2 1
`define ins_e3 0

`define t1 	6
`define t2 	5
`define t3 	4
`define t4 	3

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

`define HLT		47
`define XCHG		46
`define MOV_RD_RS	45
`define MOV_RD_M	44
`define MOV_M_RS	43
`define LXI_RD		42
`define LDAX		41
`define STAX		40
`define MVI_RD		14

module decoding
(
	input logic phi1,phi2,reset,
	input logic [7:0] next_instruction,
	output logic[14:0] control,

//	output logic S0,
//	output logic S1,
//	output logic IOMn,
	output logic RDn,
	output logic WRn,
	output logic ALE,

	output logic bc_rw,de_rw,hl_rw,pc_rw,
	output logic dreg_wr,dreg_rd,
	output logic lreg_rd,rreg_rd,lreg_wr,rreg_wr,
	output logic dreg_cnt,dreg_inc,
	output logic dbus_to_instr_reg,
	output logic write_dbus_to_alu_tmp,sel_alu_a,alu_a_to_dbus,alu_to_a,
	output logic sel_0_fe,select_ncarry_1,fe_0_to_act,
	output logic datapin_dbus_tmp,
	output logic xchg
);

logic hld_cyc,nxt_ins,m1_end,load_ins;

logic[4:0] current_mc/* = {ins_m1,ins_r1,ins_r2,ins_w1,ins_w2}*/;
logic[4:0] next_mc/* = {ins_m1,ins_r1,ins_r2,ins_w1,ins_w2}*/;

logic[6:0] current_t/* = {t1,t2,t3,t4,t5,t6,t_reset}*/;
logic[6:0] next_t/* = {t1,t2,t3,t4,t5,t6,t_reset}*/;

logic[7:0] microcode_pc,instruction;

logic[47:0] next_group,group;
logic[5:0] timing;

initial begin
current_mc = `M1;
next_mc = `M1;
current_t = 7'b0000001;
next_t = 7'b1000000;
microcode_pc = 8'b00000000;
group = 47'b00000000000000000000000000000000000000000000000;
next_group = 47'b00000000000000000000000000000000000000000000000;
end

decode decode(.instr(next_instruction),.gr(next_group));
timingrom timingrom(.group(next_group),.timing(timing));


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
					else next_mc <= `R1;
				end
				load_ins <= 1'b0;
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
	if(nxt_ins) load_ins <= nxt_ins;
end

always@(posedge phi1)begin
	if(next_t[3])begin
		instruction <= next_instruction;
		group <= next_group;
	end
	current_t <= next_t;
	current_mc <= next_mc;
	hld_cyc = (~reset&~m1_end&~(next_t[4]&~next_mc[4]));
	nxt_ins = (((next_mc[3]&~timing[`ins_e2]&~timing[`ins_e3])|(next_mc[2]&~timing[`ins_e2]&timing[`ins_e3])|(next_mc[1]&timing[`ins_e2]&~timing[`ins_e3]))&next_t[4])|reset|(m1_end&timing[`ins_e1]&timing[`ins_e2]&timing[`ins_e3]);
end
assign m1_end = next_t[1]|(next_t[3]&~timing[`ins_lng]);

always@(posedge phi1)begin
	if(reset) microcode_pc <= 1'b0;
	else if(next_t != `Treset) begin
		if(m1_end) begin
			if(next_group[`MOV_RD_RS])microcode_pc = 15;
			else if(next_group[`LXI_RD]|next_group[`MVI_RD]) microcode_pc = 4;	//LXI
		end
		else microcode_pc++ ;
	end
end

always_comb begin
	case(microcode_pc)
	`include "rommicrocode.rom"
	endcase
end

assign bc_s = ((~instruction[2]&~instruction[1]&~instruction[0])|(~instruction[2]&~instruction[1]&instruction[0]))&(group[`MOV_RD_RS]|group[`MOV_M_RS]);
assign bc_d = ((~instruction[5]&~instruction[4]&~instruction[3])|(~instruction[5]&~instruction[4]&instruction[3]))&(group[`MOV_RD_RS]|group[`LXI_RD]|group[`MVI_RD]|group[`MOV_RD_M]);
assign de_s = ((~instruction[2]&instruction[1]&~instruction[0])|(~instruction[2]&instruction[1]&instruction[0]))&(group[`MOV_RD_RS]|group[`MOV_M_RS]);
assign de_d = ((~instruction[5]&instruction[4]&~instruction[3])|(~instruction[5]&instruction[4]&instruction[3]))&(group[`MOV_RD_RS]|group[`LXI_RD]|group[`MVI_RD]|group[`MOV_RD_M]);
assign hl_s = ((instruction[2]&~instruction[1]&~instruction[0])|(instruction[2]&~instruction[1]&instruction[0]))&(group[`MOV_RD_RS]|group[`MOV_M_RS]);
assign hl_d = ((instruction[5]&~instruction[4]&~instruction[3])|(instruction[5]&~instruction[4]&instruction[3]))&(group[`MOV_RD_RS]|group[`LXI_RD]|group[`MVI_RD]|group[`MOV_RD_M]);

assign bc_rw =	(((current_mc[4]&current_t[`t1]&next_t[`t2]/*MOV RD RS*/)|(current_mc[1]&current_t[`t1]&next_t[`t2]/*MOV M RS*/))&(bc_s))|(((current_mc[4]&current_t[`t3]&next_t[`t4]/*MOV RD RS*/) | (current_mc[2]&current_t[`t1]&next_t[`t2]/*LXI*/))&(bc_d));
assign de_rw =	(((current_mc[4]&current_t[`t1]&next_t[`t2]/*MOV RD RS*/)|(current_mc[1]&current_t[`t1]&next_t[`t2]/*MOV M RS*/))&(de_s))|(((current_mc[4]&current_t[`t3]&next_t[`t4]/*MOV RD RS*/) | (current_mc[2]&current_t[`t1]&next_t[`t2]/*LXI*/))&(de_d));
assign hl_rw =	((((current_mc[4]&current_t[`t1]&next_t[`t2]/*MOV RD RS*/)|(current_mc[1]&current_t[`t1]&next_t[`t2]/*MOV M RS*/))&(hl_s))|(((current_mc[4]&current_t[`t3]&next_t[`t4]/*MOV RD RS*/) | (current_mc[2]&current_t[`t1]&next_t[`t2]/*LXI*/))&(hl_d)))|(/* HL to ADDRESS_LATCH */(group[`MOV_RD_M]|group[`MOV_M_RS])&current_mc[4]&current_t[`t4]&next_t[`t1]);
assign pc_rw = ((group[`MOV_RD_RS]|group[`LXI_RD]|group[`MVI_RD]|group[`XCHG])&current_t[`t4]&next_t[`t1]&current_mc[4]) | ((group[`LXI_RD]|group[`MOV_RD_M]|group[`MVI_RD])&(current_mc[3]|current_mc[2])&current_t[`t3]&next_t[`t1]) | (group[`MOV_M_RS]&current_mc[1]&current_t[`t3]&next_t[`t1]) | (current_mc[4]&current_t[`t2]&next_t[`t3])/* INC to PC sempre in M1T21 */ | (~group[`MOV_RD_M]&~group[`MOV_M_RS]&~current_mc[4]&current_t[`t2]&next_t[`t3]);

assign dreg_wr = next_t[`t3]&current_t[`t2];//inc_to_pc
assign dreg_rd =  (group[`MOV_RD_RS]|group[`LXI_RD]|group[`MVI_RD]|group[`MOV_RD_M]|group[`MOV_M_RS]|group[`MOV_M_RS]|group[`XCHG])&((current_t[`t4]&next_t[`t1]&current_mc[4])|(current_t[`t3]&next_t[`t1]&(current_mc[3]|current_mc[2]|current_mc[1])));//LEGGO PC O HL IN M1T41 O LEGGO PC IN R1T31 O R2T31 O W1T31

assign dreg_cnt = ((group[`MOV_RD_RS]|group[`LXI_RD]|group[`MVI_RD]|group[`XCHG])&next_t[`t1]&current_t[`t4]&current_mc[4]) | ((group[`LXI_RD]|group[`MOV_RD_M]|group[`MVI_RD])&current_t[`t3]&next_t[`t1]&(current_mc[3]|current_mc[2])) | (group[`MOV_M_RS]&current_mc[1]&current_t[`t3]&next_t[`t1]);//pc_to_inc
assign dreg_inc = ((group[`MOV_RD_RS]|group[`LXI_RD]|group[`MVI_RD]|group[`XCHG])&next_t[`t1]&current_t[`t4]&current_mc[4]) | ((group[`LXI_RD]|group[`MOV_RD_M]|group[`MVI_RD])&current_t[`t3]&next_t[`t1]&(current_mc[3]|current_mc[2])) | (group[`MOV_M_RS]&current_mc[1]&current_t[`t3]&next_t[`t1]);//pc_to_inc

assign lreg_rd = (group[`MOV_RD_RS]|group[`MOV_M_RS])&/*high registers cond*/(~instruction[0])&/*timing cond*/((current_t[`t1]&next_t[`t2])|(current_t[`t2]&next_t[`t2]));
assign rreg_rd = (group[`MOV_RD_RS]|group[`MOV_M_RS])&/*low registers cond*/  (instruction[0])&/*timing cond*/((current_t[`t1]&next_t[`t2])|(current_t[`t2]&next_t[`t2]));

assign lreg_wr = (/*(group[`MOV_RD_RS]|group[`LXI_RD]|group[`MOV_RD_M])&*//*high registers cond*/(~instruction[3])&/*timing cond*/((group[`MOV_RD_RS]|group[`LXI_RD]|group[`MOV_RD_M]|group[`MVI_RD])&current_mc[4]&current_t[`t3]&next_t[`t4]/*MOV RD RS*/)/*|(current_mc[4]&current_t[`t3]&next_t[`t4]LXI high register write)*/);
assign rreg_wr = (/*(group[`MOV_RD_RS]|group[`LXI_RD]|group[`MOV_RD_M])&*//*low registers cond*/  (instruction[3])&/*timing cond*/((group[`MOV_RD_RS]|group[`LXI_RD]|group[`MOV_RD_M]|group[`MVI_RD])&current_mc[4]&current_t[`t3]&next_t[`t4]/*MOV RD RS*/)|(group[`LXI_RD]&current_mc[2]&current_t[`t1]&next_t[`t2]/*LXI low register write*/));

assign dbus_to_instr_reg = load_ins&current_t[`t3]&next_t[`t3];
assign datapin_dbus_tmp = (group[`LXI_RD]|group[`MOV_RD_M]|group[`MVI_RD])&current_t[`t3]&next_t[`t3];
assign write_dbus_to_alu_tmp = (((group[`MOV_RD_RS])&(current_t[`t2]&next_t[`t2]))|((group[`LXI_RD]|group[`MOV_RD_M]|group[`MVI_RD])&current_t[`t3]&next_t[`t3]&(current_mc[3]|current_mc[2]))|(group[`MOV_M_RS]&current_mc[1]&current_t[`t2]&next_t[`t2]))&(~(instruction[2]&instruction[1]&instruction[0]));
assign sel_0_fe = ((group[`MOV_RD_RS])&(current_t[`t2]&next_t[`t2]&current_mc[4]))|((group[`LXI_RD]|group[`MOV_RD_M]|group[`MVI_RD])&current_t[`t3]&next_t[`t3]&(current_mc[2]|current_mc[3]))|(group[`MOV_M_RS]&current_mc[1]&current_t[`t2]&next_t[`t2]);
assign fe_0_to_act = 1'b0;
assign select_ncarry_1 = (group[`MOV_RD_RS]|group[`LXI_RD]|group[`MVI_RD]|group[`MOV_RD_M])&((current_t[`t2]&next_t[`t2]&current_mc[4])|(current_t[`t3]&next_t[`t3]&(current_mc[3]|current_mc[2]))|(current_mc[1]&current_t[`t2]&next_t[`t2]));
assign sel_alu_a = (~((instruction[2]&instruction[1]&instruction[0])&(~((instruction[5]&instruction[4]&instruction[3])|(instruction[5]&instruction[4]&~instruction[3])))))&((current_t[`t3]&next_t[`t4]&current_mc[4])|(current_t[`t1]&next_t[`t2]&current_mc[2])|(/*MOV M RS*/current_t[`t2]&next_t[`t3]&current_mc[1]));//0 se la sorgente è accumulatore e destinazione uno dei registri
assign alu_a_to_dbus = ((current_t[`t3]&next_t[`t4]&current_mc[4])&(bc_rw|de_rw|hl_rw))|((current_t[`t1]&next_t[`t2]&current_mc[2])&(bc_rw|de_rw|hl_rw))|(/*MOV M RS*/current_t[`t2]&next_t[`t3]&current_mc[1]);
assign alu_to_a = (instruction[5]&instruction[4]&instruction[3])&(current_t[`t3]&next_t[`t4]);

assign xchg = group[`XCHG];

assign ALE = current_t[`t1]&next_t[`t1];
assign RDn = ~((current_mc[4]|current_mc[3]|current_mc[2])&current_t[`t3]);
assign WRn = ~(current_mc[1]&(current_t[`t2]|(current_t[`t3]&next_t[`t3])));

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
assign gr[`MVI_RD] = (~instr[7] & ~instr[6] & ins_m2) & ~ins_m1;
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

assign gr[`STAX] = ~instr[7] & ~instr[6] & ~instr[5] & ~instr[3] & ~instr[2] & instr[1] & ~instr[0];
assign gr[`LDAX] = ~instr[7] & ~instr[6] & ~instr[5] & instr[3] & ~instr[2] & instr[1] & ~instr[0];
assign gr[`LXI_RD] =  ~instr[7] & ~instr[6] & ~instr[3] & ~instr[2] & ~instr[1] & instr[0];
assign gr[`MOV_M_RS] = (~instr[7] & instr[6] & instr[5] & instr[4] & ~instr[3]) & ~ins_m2;
assign gr[`MOV_RD_M] = (~instr[7] & instr[6]) & ~ins_m1 & ins_m2;
assign gr[`MOV_RD_RS] = ~instr[7] & instr[6] & ~ins_m1 & ~ins_m2;
assign gr[`XCHG] = instr[7] & instr[6] & instr[5] & ~instr[4] & instr[3] & ~instr[2] & instr[1] & instr[0];
assign gr[`HLT] = ~instr[7] & instr[6] & instr[5] & instr[4] & instr[3] & ~instr[2] & ~instr[1] & instr[0];

endmodule

module timingrom
(
	input logic [47:0] group,
	output logic [5:0] timing
);

always_comb begin
case(group)
	48'b010000000000000000000000000000000000000000000000: timing = 6'b000111; //XCHG
	48'b001000000000000000000000000000000000000000000000: timing = 6'b000111; //MOV RD RS
	48'b000100000000000000000000000000000000000000000000: timing = 6'b000100; //MOV RD M
	48'b000010000000000000000000000000000000000000000000: timing = 6'b100110; //MOV M RS
	48'b000001000000000000000000000000000000000000000000: timing = 6'b000101; //LXI
	48'b000000000000000000000000000000000100000000000000: timing = 6'b000100; //MVI RS
endcase
end

endmodule
