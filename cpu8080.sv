
`timescale 1ns / 1ps

`define cpus_idle		6'h00 // Idle
`define cpus_fetchi1		6'h01
`define cpus_fetchi2		6'h02
`define cpus_fetchi3		6'h03
`define cpus_fetchi4		6'h04
`define cpus_halt		6'h05
`define cpus_read1		6'h12
`define cpus_read2		6'h13
`define cpus_read3		6'h14
`define cpus_read4		6'h15
`define cpus_read5		6'h16
`define cpus_read6		6'h17
`define cpus_read7		6'h18
`define cpus_read8		6'h19
`define cpus_read9		6'h1A
`define cpus_read10		6'h1B
`define cpus_read11		6'h1C
`define cpus_read12		6'h1F
`define cpus_write1		6'h20
`define cpus_write2		6'h21
`define cpus_write3		6'h22
`define cpus_write4		6'h23
`define cpus_write5		6'h24
`define cpus_write6		6'h25
`define cpus_wait		6'h0b

`define reg_b	3'b000
`define reg_c	3'b001
`define reg_d	3'b010
`define reg_e	3'b011
`define reg_h	3'b100
`define reg_l	3'b101
`define reg_m	3'b110
`define reg_a	3'b111

`define reg_z	1'b0
`define reg_w	1'b1

module cpu8080
(
inout logic [7:0] DATA,

input logic clock,
input logic reset_in,
input logic READY,

output logic S0,
output logic S1,
output logic IO_Mn,
output logic RDn,
output logic WRn,
output logic ALE,
output logic [7:0] ADD,
output logic [5:0] state
);

logic [5:0] next_state;
logic [15:0] pc,address,sp;
logic [7:0] data_in,data_out,data_bus,flag_reg;
logic [7:0] regfil[0:7];
logic [7:0] tempreg[0:1];

//		FLAG REGISTER
// |	S	|	Z	|	XX	|	AC	|	XX	|	P	|	XX	|	Cy	|
//

always@(negedge clock)begin
	if(reset_in) begin
	state <= `cpus_idle;
	pc <= /*16'b0000010100000010*/16'b0000000100000000;
	regfil <= {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hAD};
	tempreg <= {8'h00,8'h00};
	RDn <= 1'bz;
	WRn <= 1'bz;
	IO_Mn <= 1'bz;
	ADD <= 8'bzzzzzzzz;
	flag_reg <= 8'b10000000;
	end else begin
	state <= next_state;
	if(next_state == `cpus_fetchi1 || next_state == `cpus_read1 || next_state == `cpus_read4 || next_state == `cpus_read7 || next_state == `cpus_read10 || next_state == `cpus_write1 || next_state == `cpus_write4) ALE = ~clock;
	else ALE <= 1'b0;
	end
end

always@(posedge clock)begin
	if(next_state == `cpus_fetchi1 || next_state == `cpus_read1 || next_state == `cpus_read4 || next_state == `cpus_read7 || next_state == `cpus_read10 || next_state == `cpus_write1 || next_state == `cpus_write4) ALE = ~clock;
	else ALE <= 1'b0;
end

always@(state)begin
	case (state)

	`cpus_idle: next_state <= `cpus_fetchi1;

	`cpus_fetchi1: begin
	ADD <= pc[15:8];
	data_bus <= pc[7:0];
	IO_Mn <= 1'b0;
	RDn <= 1'b1;
	WRn <= 1'b1;
	S1 <= 1'b1;
	S0 <= 1'b1;
	next_state <= `cpus_fetchi2;
	end

	`cpus_fetchi2: begin
	/*pc <= pc + 16'b0000000000000001;*/
	RDn <= 1'b0;
	next_state <= `cpus_fetchi3;
	end

	`cpus_fetchi3: begin
	if(!READY) next_state <= `cpus_wait;
	else begin
	next_state <= `cpus_fetchi4;
	data_in <= DATA;
	RDn <= 1'b1;
	end
	end

	`cpus_fetchi4: begin
		case(data_in[7:6])

		2'b00:begin
			//MVI or LXI Instruction
			if(data_in[5:0]==6'b000010 || data_in[5:0]==6'b010010) next_state <= `cpus_write1; //STAX
			else if(data_in[5:0] == 6'b101010 || data_in[5:0] == 6'b011010)//LDAX
				next_state <= `cpus_read1;
			else if(data_in[5:0] == 6'h32 || data_in[5:0] == 6'h3A/*SDA,LDA*/ || data_in[5:0] == 6'h01 || data_in[5:0] == 6'h11 || data_in[5:0] == 6'h21 || data_in[5:0] == 6'h31/*LXI*/ || data_in[2:0] == 6'b110 || data_in[5:0] == 6'h22/*SHLD*/ || data_in[5:0] == 6'h2A)begin		//STA
				next_state <= `cpus_read1;
				pc <= pc + 1;		
			end else if(data_in[5:0] == 6'h33)begin	//INX SP
				sp <= sp + 1;
				pc <= pc + 1;
				next_state = `cpus_fetchi1;
			end else if(data_in[5:0] == 6'h3B)begin	//DCX SP
				sp <= sp - 1;
				pc <= pc + 1;
				next_state = `cpus_fetchi1;			
			end
		end

		2'b01:begin					//MV instruction
			if(data_in[5:0] == 6'b110110) next_state <= `cpus_halt;
			else begin
				if(data_in[2:0] == `reg_m)begin
					next_state <= `cpus_read1;	//MOV memory to register
					pc <= {regfil[`reg_h],regfil[`reg_l]};
					end
				else if(data_in[5:3] == `reg_m)
					next_state <= `cpus_write1;	//MV register to memory
				else begin
				regfil[data_in[5:3]] <= regfil[data_in[2:0]]; //MOV register to register
				next_state = `cpus_fetchi1;
				end
			end
			if(data_in[2:0] == 3'b110/*MVI m or MVI r*/|| data_in[2:0] == 3'b001/*LXI B,D,H or SP*//*|| data_in[5:0] == 6'h0A|| data_in[5:0] == 6'h1A*/|| data_in[5:0] == 6'h32 || data_in[5:0] == 6'h3A || data_in[5:0] == 6'h22 || data_in[5:0] == 6'h2A)begin
			pc <= pc + 1;
			next_state <= `cpus_read1;
			end else if(data_in[5:0] == 6'h0A|| data_in[5:0] == 6'h1A)
			next_state <= `cpus_read1;
		end
		2'b11:begin					//XCHG
			if(data_in[5:0] == 6'b101011) begin
				regfil[`reg_h] <= regfil[`reg_d];
				regfil[`reg_d] <= regfil[`reg_h];
				regfil[`reg_l] <= regfil[`reg_e];
				regfil[`reg_e] <= regfil[`reg_l];
				pc <= pc + 1;
				next_state <= `cpus_fetchi1;
			end else if(data_in[5:0] == 6'h05 || data_in[5:0] == 6'h15 || data_in[5:0] == 6'h25 || data_in[5:0] == 6'h35)begin	//PUSH
				next_state <= `cpus_write1;
			end else if(data_in[5:0] == 6'h01 || data_in[5:0] == 6'h11 || data_in[5:0] == 6'h21 || data_in[5:0] == 6'h31)begin	//POP
				next_state <= `cpus_read1;
			end else if(data_in[5:0] == 6'h23)begin		//XTHL
				next_state <= `cpus_read1;
			end else if(data_in[5:0] == 6'h03 || data_in[5:0] == 6'h1A || data_in[5:0] == 6'h12 || data_in[5:0] == 6'h0A || data_in[5:0] == 6'h02 || data_in[5:0] == 6'h32 || data_in[5:0] == 6'h3A || data_in[5:0] == 6'h2A || data_in[5:0] == 6'h22)begin
				next_state <= `cpus_read1;
				pc <= pc + 1;
			end else if(data_in[5:0] == 6'h29)begin
				pc[7:0] <= regfil[`reg_l];
				pc[15:8] <= regfil[`reg_h];
				next_state <= `cpus_fetchi1;
			end else if(data_in[5:0] == 6'h39)begin
				sp[7:0] <= regfil[`reg_l];
				sp[15:8] <= regfil[`reg_h];
				pc <= pc + 1;
				next_state <= `cpus_fetchi1;
			end
		end
		endcase
	end

	`cpus_read1: begin
	S0 <= 1'b0;
	S1 <= 1'b1;
	if(data_in == 8'b00101010) ADD <= {regfil[`reg_b],regfil[`reg_c]};		//LDAX B
	else if(data_in == 8'hC1 || data_in == 8'hD1 || data_in == 8'hE1 || data_in == 8'hF1 || data_in == 8'hE3)begin
		ADD <= sp[15:8];
		data_bus <= sp[7:0];
	end else begin ADD <= pc[15:8];
		data_bus <= pc[7:0];
	end
	next_state <= `cpus_read2;
	end

	`cpus_read2: begin
	RDn <= 1'b0;
	WRn <= 1'b1;
	next_state <= `cpus_read3;
	end

	`cpus_read3: begin
	if(!READY) next_state <= `cpus_wait;
	else begin
	RDn <= 1'b1;
	if(data_in == 8'b00110110)begin		//MVI to memory: save immediate to temp reg z
		next_state <= `cpus_write1;
		tempreg[`reg_z] <= DATA;
	end
	else if(data_in == 8'b00001010 || data_in == 8'b00011010)begin	//LDAX B or D
		regfil[`reg_a] <= DATA;
		next_state <= `cpus_fetchi1;
	end
	else if(data_in == 8'h01 || data_in == 8'h11 || data_in == 8'h21 || data_in == 8'h31)begin	//LXI				//LXI saving low byte
		if(data_in == 8'h31) sp[7:0] <= DATA;
		else regfil[(data_in[5:3])+1] <= DATA;
		pc <= pc + 1;
		next_state <= `cpus_read4;
	end else if(data_in[7:6]==2'b01 && data_in[2:0]==2'b110) begin //MOV memory to register
		regfil[data_in[5:3]] <= DATA;
		pc <= pc + 1;
		next_state <= `cpus_fetchi1;
	end else if(data_in == 8'h32)begin		//STA
		tempreg[`reg_z] <= DATA;
		pc <= pc + 1;
		next_state <= `cpus_read4;
	end else if(data_in == 8'h3A)begin		//LDA
		tempreg[`reg_z] <= DATA;
		pc <= pc + 1;
		next_state <= `cpus_read4;
	end else if(data_in == 8'h2A)begin		//LHDL
		tempreg[`reg_z] <= DATA;
		pc <= pc + 1;
		next_state <= `cpus_read4;
	end else if(data_in == 8'h22)begin
		tempreg[`reg_z] <= DATA;
		pc <= pc + 1;
		next_state <= `cpus_read4;
	end else if(data_in == 8'hC3 || data_in == 8'hCA || data_in == 8'hDA || data_in == 8'hFA || data_in == 6'hEA || data_in == 8'hC2 || data_in == 8'hD2 || data_in == 8'hF2 || data_in == 8'hE2)begin
		tempreg[`reg_z] <= DATA;
		pc <= pc + 1;
		next_state <= `cpus_read4;
	end else if(data_in[7:0] == 8'hC1 || data_in[7:0] == 8'hD1 || data_in[7:0] == 8'hE1 || data_in[7:0] == 8'hF1)begin
		if(data_in == 8'hF1) flag_reg <= DATA;
		else regfil[data_in[5:3]+1] <= DATA;
		sp <= sp + 1;
		next_state <= `cpus_read4;
	end else if(data_in[7:0] == 8'hE3)begin
		tempreg[`reg_z] <= DATA;
		next_state <= `cpus_read4;
	end else begin
		regfil[data_in[5:3]] <= DATA;	//MVI to regfile: save immediate to register file
		pc <= pc + 1;
		next_state <= `cpus_fetchi1;
		end
	end
	end

	`cpus_read4: begin
	S0 <= 1'b0;
	S1 <= 1'b1;
	if(data_in[7:0] == 8'hC1 || data_in[7:0] == 8'hD1 || data_in[7:0] == 8'hE1 || data_in[7:0] == 8'hF1)begin
		ADD <= sp[15:8];
		data_bus <= sp[7:0];
	end else if(data_in[7:0] == 8'hE3)begin
		if(sp[7:0] == 8'hFF)begin
			data_bus <= 8'h00;
			ADD <= sp[15:8] + 8'h01;
		end else begin
			data_bus <= sp[7:0] + 8'h01;
			ADD <= sp[15:8];
		end
	end else begin
		ADD <= pc[15:8];
		data_bus <= pc[7:0];
	end
	next_state <= `cpus_read5;
	end

	`cpus_read5: begin
	RDn <= 1'b0;
	WRn <= 1'b1;
	next_state <= `cpus_read6;
	end

	`cpus_read6: begin
	if(!READY) next_state <= `cpus_wait;
	else begin
	RDn <= 1'b1;
	if(data_in == 8'h01 || data_in == 8'h11 || data_in == 8'h21 || data_in == 8'h31)begin//LXI
		if(data_in == 8'h31) sp[15:8] <= DATA;
		else regfil[(data_in[5:3])] <= DATA;
		pc <= pc + 1;
		next_state <= `cpus_fetchi1;
	end else if(data_in == 8'h32)begin //SDA
		tempreg[`reg_w] <= DATA;
		next_state <= `cpus_write1;
	end else if(data_in == 8'h3A)begin//LDA
		tempreg[`reg_w] <= DATA;
		next_state <= `cpus_read7;
	end else if(data_in == 8'h2A)begin//LHLD
		tempreg[`reg_w] <= DATA;
		next_state <= `cpus_read7;
	end else if(data_in == 8'h22)begin//SHLD
		tempreg[`reg_w] <= DATA;
		next_state <= `cpus_write1;
	end else if(data_in == 8'hC3 || data_in == 8'hCA || data_in == 8'hDA || data_in == 8'hFA || data_in == 6'hEA || data_in == 8'hC2 || data_in == 8'hD2 || data_in == 8'hF2 || data_in == 8'hE2)begin
		if(data_in == 8'hC3)begin
			pc <= {DATA,tempreg[`reg_z]};
			next_state <= `cpus_fetchi1;
		end else begin
			case(data_in)
			8'hCA:begin
				if(flag_reg[6]) pc <= {DATA,tempreg[`reg_z]};
				else pc <= pc + 1;
			end
			8'hDA:begin
				if(flag_reg[0]) pc <= {DATA,tempreg[`reg_z]};
				else pc <= pc + 1;
			end
			8'hFA:begin
				if(flag_reg[7]) pc <= {DATA,tempreg[`reg_z]};
				else pc <= pc + 1;
			end
			8'hEA:begin
				if(flag_reg[2]) pc <= {DATA,tempreg[`reg_z]};
				else pc <= pc + 1;
			end
			8'hC2:begin
				if(!flag_reg[6]) pc <= {DATA,tempreg[`reg_z]};
				else pc <= pc + 1;
			end
			8'hD2:begin
				if(!flag_reg[0]) pc <= {DATA,tempreg[`reg_z]};
				else pc <= pc + 1;
			end
			8'hF2:begin
				if(!flag_reg[7]) pc <= {DATA,tempreg[`reg_z]};
				else pc <= pc + 1;
			end
			8'hE2:begin
				if(!flag_reg[2]) pc <= {DATA,tempreg[`reg_z]};
				else pc <= pc + 1;
			end
			endcase
		end
		next_state <=`cpus_fetchi1;
	end else if(data_in == 8'hE3)begin
		tempreg[`reg_w] <= DATA;
		next_state <= `cpus_write1;
	end else if(data_in == 8'hC1 || data_in[7:0] == 8'hD1 || data_in[7:0] == 8'hE1 || data_in[7:0] == 8'hF1)begin
		if(data_in == 8'hF1) regfil[`reg_a] <= DATA;
		else regfil[data_in[5:3]] <= DATA;
		sp <= sp + 1;
		pc <= pc + 1;
		next_state <=`cpus_fetchi1; 
	end
	end
	end

	`cpus_read7: begin
	S0 <= 1'b0;
	S1 <= 1'b1;
	ADD <= tempreg[`reg_w];
	data_bus <= tempreg[`reg_z];
	next_state <= `cpus_read8;
	end

	`cpus_read8: begin
	RDn <= 1'b0;
	WRn <= 1'b1;
	next_state <= `cpus_read9;
	end

	`cpus_read9: begin
	if(!READY) next_state <= `cpus_wait;
	else begin
	RDn <= 1'b1;
	if(data_in == 8'h2A)begin//LHLD
		regfil[`reg_l] <= DATA;
		next_state <= `cpus_read10;
	end else if(data_in == 8'h3A)begin
		regfil[`reg_a] <= DATA;
		pc <= pc + 1;
		next_state <= `cpus_fetchi1;
		end
	end
	end

	`cpus_read10: begin
	S0 <= 1'b0;
	S1 <= 1'b1;
	ADD <= tempreg[`reg_w];
	data_bus <= tempreg[`reg_z] + 8'b00000001;
	next_state <= `cpus_read11;
	end

	`cpus_read11: begin
	RDn <= 1'b0;
	WRn <= 1'b1;
	next_state <= `cpus_read12;
	end

	`cpus_read12: begin
	if(!READY) next_state <= `cpus_wait;
	else begin
	RDn <= 1'b1;
	regfil[`reg_h] <= DATA;
	next_state <= `cpus_fetchi1;
	end
	end

	`cpus_write1:begin
	IO_Mn <= 1'b0;
	S0 <= 1'b1;
	S1 <= 1'b0;
	if(data_in == 8'h36)begin //MOV immediate to memory
		ADD <= regfil[`reg_h];
		data_bus <= regfil[`reg_l];
	end else if(data_in[7:3] == 6'b01110)begin //MOV register to memory
		ADD <= regfil[`reg_h];
		data_bus <= regfil[`reg_l];
	end else if(data_in==8'h02 && data_in==8'h12) begin	//STAX: move accumulator to Mem[B or D,C or F]
		ADD <= regfil[data_in[5:3]];
		data_bus <= regfil[data_in[5:3] + 3'b001];
	end else if(data_in == 8'h32)begin			//STA
		ADD <= tempreg[`reg_w];
		data_bus <= tempreg[`reg_z];
	end else if(data_in == 8'h22)begin			//
		ADD <= tempreg[`reg_w];
		data_bus <= tempreg[`reg_z];
	end else if(data_in == 8'hC5 || data_in == 8'hD5 || data_in == 8'hE5 || data_in == 8'hF5)begin	//PUSH
		if(sp[7:0]==8'h00)begin
			sp[7:0] <= 8'hFF;
			data_bus <= 8'hFF;
			sp[15:8] <= sp[15:8] - 8'h01;
			ADD <= sp[15:8] - 8'h01;
		end else begin
			sp <= sp - 8'h01;
			ADD <= sp[15:8];
			data_bus <= sp[7:0] - 8'h01;
		end
	end else if(data_in == 8'hE3)begin
		data_bus <= sp[7:0];
		ADD <= sp[15:8];
	end
	next_state <= `cpus_write2;
	end

	`cpus_write2:begin
	WRn <= 1'b0;
	RDn <= 1'b1;
	if(data_in == 8'h36)data_bus <= tempreg[`reg_z];
	else if(data_in[7:3] == 6'b01110)data_bus <= regfil[data_in[2:0]];
	else if(data_in==8'h02 && data_in==8'h12)data_bus <= regfil[`reg_a];
	else if(data_in == 8'h32) data_bus <= regfil[`reg_a];
	else if(data_in == 8'h22 || data_in == 8'hE3) data_bus <= regfil[`reg_l];
	else if(data_in == 8'hC5 || data_in == 8'hD5 || data_in == 8'hE5 || data_in == 8'hF5)begin	//PUSH
		if(data_in == 8'hF5) data_bus <= flag_reg;
		else data_bus <= regfil[data_in[5:3]];
	end
	next_state <= `cpus_write3;
	end

	`cpus_write3:begin
	WRn <= 1'b1;
	pc <= pc + 1;
	if(data_in == 8'h22 || data_in == 8'hC5 || data_in == 8'hD5 || data_in == 8'hE5 || data_in == 8'hE3) next_state <= `cpus_write4;	//PUSH
	else next_state <= `cpus_fetchi1;
	end

	`cpus_write4:begin
	IO_Mn <= 1'b0;
	S0 <= 1'b1;
	S1 <= 1'b0;
	if(data_in == 8'h22)begin
		if(tempreg[`reg_z] == 8'hFF)begin
			data_bus <= 8'h00;
			ADD <= tempreg[`reg_w]++;
		end else begin
			data_bus <= tempreg[`reg_z]++;
			ADD <= tempreg[`reg_w];
		end
	end else if(data_in == 8'hC5 || data_in == 8'hD5 || data_in == 8'hE5 || data_in == 8'hF5)begin //PUSH
		if(sp[7:0]==8'h00)begin
			sp[7:0] <= 8'hFF;
			data_bus <= 8'hFF;
			sp[15:8] <= sp[15:8] - 8'h01;
			ADD <= sp[15:8] - 8'h01;
		end else begin
			sp <= sp - 8'h01;
			ADD <= sp[15:8];
			data_bus <= sp[7:0] - 8'h01;
		end
//		ADD <= sp - 1;
//		sp <= sp - 1;
	end else if(data_in == 8'hE3)begin
		if(sp[7:0] == 8'hFF)begin
			data_bus <= 8'h00;
			ADD <= sp[15:8] + 8'h01;
		end else begin
			data_bus <= sp[7:0] + 8'h01;
			ADD <= sp[15:8];
		end
	end
	next_state <= `cpus_write5;
	end

	`cpus_write5:begin
	WRn <= 1'b0;
	RDn <= 1'b1;
	if(data_in == 8'h22) data_bus <= regfil[`reg_h];
	else if(data_in == 8'hE3)begin
		data_bus <= regfil[`reg_h];
		regfil[`reg_h] <= tempreg[`reg_z];
		regfil[`reg_l] <= tempreg[`reg_w];
	end else begin
		if(data_in == 8'hF5) data_bus <= regfil[`reg_a];
		else data_bus <= regfil[data_in[5:3] + 3'b001];
	end
	next_state <= `cpus_write6;
	end

	`cpus_write6:begin
	WRn <= 1'b1;
	next_state <= `cpus_fetchi1;
	end

	endcase
end
//assign data_bus = ALE ? pc[7:0] : data_out;
assign DATA = ((~WRn&~IO_Mn&RDn)|ALE) ? data_bus : 8'bzzzzzzzz;;
endmodule


