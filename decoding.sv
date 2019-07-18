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


module decoding
(
	input logic phi1,phi2,reset,
	input logic [7:0] instruction,
	output logic[36:0] control,

//	output logic S0,
//	output logic S1,
//	output logic IOMn,
//	output logic RDn,
//	output logic WRn,
//	output logic ALE,

	output logic dbus_to_instr_reg
);

logic hld_cyc,nxt_ins,m1_end,m1;

logic[4:0] current_mc/* = {ins_m1,ins_r1,ins_r2,ins_w1,ins_w2}*/;
logic[4:0] next_mc,next_mc_atphi1/* = {ins_m1,ins_r1,ins_r2,ins_w1,ins_w2}*/;

logic[6:0] current_t/* = {t1,t2,t3,t4,t5,t6,t_reset}*/;
logic[6:0] next_t/* = {t1,t2,t3,t4,t5,t6,t_reset}*/;

logic[7:0] microcode_pc;

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
			`T3: next_t <= `T4;
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
	//m1 <= (~hld_cyc&nxt_ins)|(hld_cyc&next_mc_atphi1[4]);
end

always@(posedge phi1)begin
	current_t <= next_t;
	current_mc <= next_mc;
	next_mc_atphi1 <= next_mc;
	hld_cyc = (~reset&~m1_end&~(next_t[4]&~next_mc[4]));
	nxt_ins = (((next_mc[3]&~timing[`ins_e2]&~timing[`ins_e3])|(next_mc[2]&~timing[`ins_e2]&timing[`ins_e3])|(next_mc[1]&timing[`ins_e2]&~timing[`ins_e3]))&next_t[4])|reset|(m1_end&timing[`ins_e1]&timing[`ins_e2]&timing[`ins_e3]);
end
//assign nxt_ins = (((next_mc[3]&~timing[`ins_e2]&~timing[`ins_e3])|(next_mc[2]&~timing[`ins_e2]&timing[`ins_e3])|(next_mc[1]&timing[`ins_e2]&~timing[`ins_e3]))&next_t[4])|reset|(m1_end&timing[`ins_e1]&timing[`ins_e2]&timing[`ins_e3]);
assign m1_end = next_t[1]|(next_t[3]&~timing[`ins_lng]);

always@(posedge phi1,posedge phi2)begin
	if(reset) microcode_pc <= 1'b0;
	else if(next_t != 7'b0000001) begin
		if(((!phi1&phi2)||(!phi2&!phi1))&current_t[4]) microcode_pc = 10;
		else microcode_pc++ ;
	end
	case(microcode_pc)
	`include "rommicrocode.rom"
	endcase
end

assign dbus_to_instr_reg = control[0];
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
