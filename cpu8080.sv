`timescale 1ns / 1ps

`define cpus_idle		6'h00 // Idle
`define cpus_fetchi1		6'h01
`define cpus_fetchi2		6'h02
`define cpus_fetchi3		6'h03
`define cpus_fetchi4		6'h04
`define cpus_fetchi5		6'h05
`define cpus_fetchi6		6'h06
`define cpus_halt		6'h07
`define cpus_input1		6'h08
`define cpus_input2		6'h09
`define cpus_input3		6'h0A
`define cpus_output1		6'h0B
`define cpus_output2		6'h0C
`define cpus_output3		6'h0D
`define cpus_busidle1		6'h0E
`define cpus_busidle2		6'h0F
`define cpus_busidle3		6'h10
`define cpus_busidle4		6'h11
`define cpus_busidle5		6'h12
`define cpus_busidle6		6'h13
`define cpus_read1		6'h14
`define cpus_read2		6'h15
`define cpus_read3		6'h16
`define cpus_read4		6'h17
`define cpus_read5		6'h18
`define cpus_read6		6'h19
`define cpus_read7		6'h1A
`define cpus_read8		6'h1B
`define cpus_read9		6'h1C
`define cpus_read10		6'h1D
`define cpus_read11		6'h1E
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
//MOVE,LOAD,STORE
logic movrr ;
logic movrm ;
logic movmr ;
logic mvim ;
logic mvir ;
logic lxir ;
logic lxisp;
logic lda ;
logic sta ;
logic lhld ;
logic shld ;
logic ldax ;
logic stax ;
logic xchg ;
logic inport ;
logic outport ;
//STACK
logic pushr ;
logic pushpsw ;
logic popr ;
logic poppsw;
logic xthl ;
logic sphl ;
//ARITHMETIC
logic addr ;
logic addm ;
logic adi ;
logic adcr ;
logic adcm ;
logic aci ;
logic subr ;
logic subm ;
logic sui ;
logic sbbr ;
logic sbbm ;
logic sbi ;
logic inrr ;
logic inrm ;
logic dcrr ;
logic dcrm ;
logic inxrp;
logic dcxrp;
logic dadrp;
//LOGICAL
logic anar;
logic anam;
logic ani;
logic xrar;
logic xram;
logic xri;
logic orar;
logic oram;
logic ori;
logic cmpr;
logic cmpm;
logic cmpi;
//ROTATE
logic rlc;
logic rrc;
logic ral;
logic rar;
//JUMP
//CALL
//RETURN
//INPUT,OUTPUT
//DAA
//SPECIALS

logic [5:0] next_state;
logic [15:0] pc,address,sp;
logic [7:0] data_in,data_out,flag_reg,instruction_register,address_buffer,temporary_register;
logic [7:0] regfil[0:7];
logic [7:0] internalreg[0:1];

//		DATA_in/DATA_out --------------->	ADDRESS/DATA BUFFER
//		FLAG REGISTER
// |	S	|	Z	|	XX	|	AC	|	XX	|	P	|	XX	|	Cy	|
//

//FINO A INXrp e DCXrp rivedere distinzione tra regz,regw e tempreg (stack,datamov e arithmetic)
//registro dei flag non mai settato
//controllare istruzione DAD
//DAA non implementata

always@(negedge clock)begin
	if(reset_in) begin
	state <= `cpus_idle;
	pc <= 16'b0000000100000000;
	regfil <= {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hAD};
	internalreg <= {8'h00,8'h00};
	RDn <= 1'bz;
	WRn <= 1'bz;
	IO_Mn <= 1'bz;
	address_buffer <= 8'bzzzzzzzz;
	flag_reg <= 8'b10000000;
	xthl <= 1'b0;
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
	address_buffer <= pc[15:8];
	data_out <= pc[7:0];
	IO_Mn <= 1'b0;
	RDn <= 1'b1;
	WRn <= 1'b1;
	S1 <= 1'b1;
	S0 <= 1'b1;
	if(movrr) internalreg[`reg_z]<=regfil[instruction_register[2:0]];
	else if(xchg)begin
		regfil[`reg_h] <= regfil[`reg_d];
		regfil[`reg_d] <= regfil[`reg_h];
	end else if(inxrp || dcxrp)begin
		if(instruction_register[5:4] == 2'b11) temporary_register <= sp[15:8];
		else temporary_register <= regfil[{instruction_register[5:4],1'b0}];		
	end else if(addr || adcr || subr || sbbr || anar || xrar || orar || cmpr) temporary_register <= regfil[instruction_register[2:0]];
	else if(inrr || dcrr) temporary_register <= regfil[instruction_register[5:3]];
	next_state <= `cpus_fetchi2;
	end

	`cpus_fetchi2: begin
	RDn <= 1'b0;
	if(movrr)begin
		regfil[instruction_register[5:3]]<=internalreg[`reg_z];
		movrr <= 1'b0;
	end else if(xchg)begin
		regfil[`reg_l] <= regfil[`reg_e];
		regfil[`reg_e] <= regfil[`reg_l];
		xchg <= 1'b0;
	end else if(addr || addm || adi)begin
		regfil[`reg_a] <= regfil[`reg_a] + temporary_register;
		addr <= 1'b0;
		addm <= 1'b0;
		adi <= 1'b0;
	end else if(adcr || adcm || aci)begin
		regfil[`reg_a] <= regfil[`reg_a] + temporary_register + flag_reg[0];
		adcr <= 1'b0;
		adcm <= 1'b0;
		aci <= 1'b0;
	end else if(subr || subm || sui)begin
		regfil[`reg_a] <= regfil[`reg_a] - temporary_register;
		subr <= 1'b0;
		subm <= 1'b0;
		sui <= 1'b0;
	end else if(sbbr || sbbm || sbi)begin
		regfil[`reg_a] <= regfil[`reg_a] - temporary_register - flag_reg[0];
		sbbr <= 1'b0;
		sbbm <= 1'b0;
		sbi <= 1'b0;
	end else if(inrr)begin
		regfil[instruction_register[5:3]] <= temporary_register + 8'h01;
		inrr <= 1'b0;
	end else if(dcrr)begin
		regfil[instruction_register[5:3]] <= temporary_register - 8'h01;
		dcrr <= 1'b0;
	end else if(inxrp)begin
		if(instruction_register[5:4] == 2'b11) sp[15:8] <= temporary_register + flag_reg[0];
		else regfil[{instruction_register[5:4],1'b0}] <= temporary_register + flag_reg[0];
		flag_reg <= internalreg[`reg_z];
		inxrp <= 1'b0;
	end else if(anar || anam || ani)begin
		regfil[`reg_a] <= regfil[`reg_a] & temporary_register ;
		anar <= 1'b0;
		anam <= 1'b0;
		ani <= 1'b0;
	end else if(xrar || xram || xri)begin
		regfil[`reg_a] <= regfil[`reg_a] ^ temporary_register ;
		xrar <= 1'b0;
		xram <= 1'b0;
		xri <= 1'b0;
	end else if(orar || oram || ori)begin
		regfil[`reg_a] <= regfil[`reg_a] | temporary_register ;
		orar <= 1'b0;
		oram <= 1'b0;
		ori <= 1'b0;
	end else if(cmpr || cmpm || cmpi)begin
		/*  ACC - TEMP takes place and flags are affected  */
		orar <= 1'b0;
		oram <= 1'b0;
		ori <= 1'b0;
	end else if(rlc || ral)begin
		if(ral) {flag_reg[0],regfil[`reg_a]} <= {regfil[`reg_a][7],regfil[`reg_a][6:0],flag_reg[0]};
		else regfil[`reg_a] <= {regfil[`reg_a][6:0],regfil[`reg_a][7]};
		rlc <= 1'b0;
		ral <= 1'b0;
	end else if(rrc || rar)begin
		if(rar) {flag_reg[0],regfil[`reg_a]} <= {regfil[`reg_a][0],flag_reg[0],regfil[`reg_a][7:1]};
		else regfil[`reg_a] <= {regfil[`reg_a][0],regfil[`reg_a][7:1]};
		rrc <= 1'b0;
		rar <= 1'b0;
	end
	pc <= pc + 16'h0001;
	next_state <= `cpus_fetchi3;
	end

	`cpus_fetchi3: begin
	if(!READY) next_state <= `cpus_wait;
	else begin
	next_state <= `cpus_fetchi4;
	instruction_register <= DATA;
	RDn <= 1'b1;
	end
	end

	`cpus_fetchi4: begin
		case(instruction_register[7:6])

		2'b00:begin
			//MVI or LXI Instruction
			if(instruction_register[2:0] == 3'b110)begin
				if(instruction_register[5:3] == `reg_m) mvim<=1'b1;
				else mvir <= 1'b1;
				next_state <= `cpus_read1;
			end else if(instruction_register[3:0] == 4'b001)begin
				if(instruction_register[5:4] == 2'b11) lxisp<=1'b1;
				else lxir <= 1'b1;
				next_state <= `cpus_read1;
			end else if(instruction_register[5:0] == 6'b111010)begin
				lda <= 1'b1;
				next_state <= `cpus_read1;				
			end else if(instruction_register[5:0] == 6'b110010)begin
				sta <= 1'b1;
				next_state <= `cpus_read1;				
			end else if(instruction_register[5:0] == 6'b101010)begin
				lhld <= 1'b1;
				next_state <= `cpus_read1;				
			end else if(instruction_register[5:0] == 6'b100010)begin
				shld <= 1'b1;
				next_state <= `cpus_read1;				
			end else if(instruction_register[3:0] == 4'b1010)begin
				ldax <= 1'b1;
				next_state <= `cpus_read1;				
			end else if(instruction_register[3:0] == 4'b0010)begin
				stax <= 1'b1;
				next_state <= `cpus_write1;				
			end else if(instruction_register[3:0] == 4'b0011)begin
				inxrp <= 1'b1;
				next_state <= `cpus_fetchi5;				
			end else if(instruction_register[3:0] == 4'b1011)begin
				dcxrp <= 1'b1;
				next_state <= `cpus_fetchi5;				
			end else if(instruction_register[3:0] == 4'b1001)begin
				dadrp <= 1'b1;
				next_state <= `cpus_busidle1;				
			end else if(instruction_register[2:0] == 3'b100)begin
				if(instruction_register[5:3] == `reg_m)begin
					inrm <= 1'b1;
					next_state <= `cpus_read1;
				end else begin
					inrr <= 1'b1;
					next_state <= `cpus_fetchi1;
				end			
			end else if(instruction_register[2:0] == 3'b101)begin
				if(instruction_register[5:3] == `reg_m)begin
					dcrm <= 1'b1;
					next_state <= `cpus_read1;
				end else begin
					dcrr <= 1'b1;
					next_state <= `cpus_fetchi1;
				end			
			end else if(instruction_register[5:0] == 6'b000111)begin
				rlc <= 1'b1;
				next_state <= `cpus_fetchi1;				
			end else if(instruction_register[5:0] == 6'b001111)begin
				rrc <= 1'b1;
				next_state <= `cpus_fetchi1;				
			end else if(instruction_register[5:0] == 6'b010111)begin
				ral <= 1'b1;
				next_state <= `cpus_fetchi1;				
			end else if(instruction_register[5:0] == 6'b011111)begin
				rar <= 1'b1;
				next_state <= `cpus_fetchi1;				
			end
		end

		2'b01:begin					//MV instruction
			if(instruction_register[2:0] == `reg_m)begin
				next_state <= `cpus_read1;
				movrm <= 1'b1;
			end else if(instruction_register[5:3] == `reg_m)begin
				next_state <= `cpus_write1;
				movmr <= 1'b1;
			end else begin
				movrr <= 1'b1;
				next_state <= `cpus_fetchi1;
			end
		end

		2'b10:begin
			if(instruction_register[5:4] == 'b00)begin
				if(instruction_register[2:0] == `reg_m)begin
					if(instruction_register[3])adcm <= 1'b1;
					else addm <= 1'b1;
					next_state <= `cpus_read1;
				end else begin
					if(instruction_register[3])adcr <= 1'b1;
					else addr <= 1'b1;
					next_state <= `cpus_fetchi1;
				end
			end else if(instruction_register[5:4] == 2'b01)begin
				if(instruction_register[2:0] == `reg_m)begin
					if(instruction_register[3]) sbbm <= 1'b1;
					else subm <= 1'b1;
					next_state <= `cpus_read1;
				end else begin
					if(instruction_register[3]) sbbr <= 1'b1;
					else subr <= 1'b1;
					next_state <= `cpus_fetchi1;
				end
			end else if(instruction_register[5:3] == 3'b100)begin
				if(instruction_register[2:0] == `reg_m)begin
					anam <= 1'b1;
					next_state <= `cpus_read1;
				end else begin
					anar <= 1'b1;
					next_state <= `cpus_fetchi1;
				end
			end else if(instruction_register[5:3] == 3'b101)begin
				if(instruction_register[2:0] == `reg_m)begin
					xram <= 1'b1;
					next_state <= `cpus_read1;
				end else begin
					xrar <= 1'b1;
					next_state <= `cpus_fetchi1;
				end
			end else if(instruction_register[5:3] == 3'b110)begin
				if(instruction_register[2:0] == `reg_m)begin
					oram <= 1'b1;
					next_state <= `cpus_read1;
				end else begin
					orar <= 1'b1;
					next_state <= `cpus_fetchi1;
				end
			end else if(instruction_register[5:3] == 3'b111)begin
				if(instruction_register[2:0] == `reg_m)begin
					cmpm <= 1'b1;
					next_state <= `cpus_read1;
				end else begin
					cmpr <= 1'b1;
					next_state <= `cpus_fetchi1;
				end
			end
		end

		2'b11:begin					//XCHG
			if(instruction_register[5:0] == 6'b101011) begin
				xchg <= 1'b0;
				next_state <= `cpus_fetchi1;
			end else if(instruction_register[5:0] == 6'b011011)begin
				inport <= 1'b1;
				next_state <= `cpus_read1;
			end else if(instruction_register[5:0] == 6'b010011)begin
				outport <= 1'b1;
				next_state <= `cpus_read1;
			end else if(instruction_register[5:0] == 6'b100011)begin
				xthl <= 1'b1;
				next_state <= `cpus_read1;
			end else if(instruction_register[5:0] == 6'b111001)begin
				sphl <= 1'b1;
				next_state <= `cpus_fetchi5;
			end else if(instruction_register[3:0] == 4'b0101)begin
				if(instruction_register[5:4] == 2'b11) pushpsw <= 1'b1;
				else pushr <= 1'b1;
				next_state <= `cpus_fetchi5;
			end else if(instruction_register[3:0] == 4'b0001)begin
				if(instruction_register[5:4] == 2'b11) poppsw <= 1'b1;
				else popr <= 1'b1;
				next_state <= `cpus_read1;
			end else if(instruction_register[5:0] == 6'b000110)begin
				adi <= 1'b1;
				next_state <= `cpus_read1;
			end else if(instruction_register[5:0] == 6'b001110)begin
				aci <= 1'b1;
				next_state <= `cpus_read1;
			end else if(instruction_register[5:0] == 6'b010110)begin
				sui <= 1'b1;
				next_state <= `cpus_read1;
			end else if(instruction_register[5:0] == 6'b011110)begin
				sbi <= 1'b1;
				next_state <= `cpus_read1;
			end else if(instruction_register[5:0] == 6'b100110)begin
				ani <= 1'b1;
				next_state <= `cpus_read1;
			end else if(instruction_register[5:0] == 6'b101110)begin
				xri <= 1'b1;
				next_state <= `cpus_read1;
			end else if(instruction_register[5:0] == 6'b110110)begin
				ori <= 1'b1;
				next_state <= `cpus_read1;
			end else if (instruction_register[5:0] == 6'b111110)begin
				cmpi <= 1'b1;
				next_state <= `cpus_read1;
			end
		end
		endcase
	end

	`cpus_fetchi5:begin
	if(sphl) sp[7:0]<= regfil[`reg_l];
	else if(inxrp || dcxrp)begin
		if(instruction_register[5:4] == 2'b11) temporary_register <= sp[7:0];
		else temporary_register <= regfil[{instruction_register[5:4],1'b0} + 3'b001];
		internalreg[`reg_z] <= flag_reg;
	end
	next_state <= `cpus_fetchi6;
	end

	`cpus_fetchi6:begin
	if(sphl)begin
		sp[15:8]<= regfil[`reg_h];
		sphl <= 1'b0;
	end else if(inxrp)begin
		if(instruction_register[5:4] == 2'b11) sp[7:0] <= temporary_register + 8'h01;
		else regfil[{instruction_register[5:4],1'b0} + 3'b001] <= temporary_register + 8'h01;
		next_state <= `cpus_fetchi1;
	end else if(dcxrp)begin
		if(instruction_register[5:4] == 2'b11) sp[7:0] <= temporary_register - 8'h01;
		else regfil[{instruction_register[5:4],1'b0} + 3'b001] <= temporary_register - 8'h01;
		next_state <= `cpus_fetchi1;
	end
	else sp <= sp - 16'h0001;
	next_state <= `cpus_write1;
	end

	`cpus_read1: begin
	IO_Mn <= 1'b0;
	S0 <= 1'b0;
	S1 <= 1'b1;
	if(movrm || addm || adcm || subm || sbbm || inrm || dcrm || anam || xram || oram || cmpm)begin
		address_buffer <= regfil[`reg_h];
		data_out <= regfil[`reg_l];
	end else if(ldax)begin
		address_buffer <= regfil[{instruction_register[5:4],1'b0}];
		data_out <= regfil[{instruction_register[5:4],1'b0}+3'b001];
	end else if(mvim || mvir || lxir || lxisp || lda || sta || lhld || shld || inport || outport || adi || aci || sui || sbi || ani || xri || ori)begin
		address_buffer <= pc[15:8];
		data_out <= pc[7:0];
	end else if(popr || poppsw || xthl)begin
		address_buffer <= sp[15:8];
		data_out <= sp[7:0];		
	end
	next_state <= `cpus_read2;
	end

	`cpus_read2: begin
	RDn <= 1'b0;
	WRn <= 1'b1;
	if(mvir || lxir || lxisp || lda || sta || lhld || shld || inport || outport || adi || aci || sui || sbi || ani || xri || ori) pc <= pc + 16'h0001;
	else if(popr || poppsw || xthl) sp <= sp + 16'h0001;
	next_state <= `cpus_read3;
	end

	`cpus_read3: begin
	if(!READY) next_state <= `cpus_wait;
	else begin
	RDn <= 1'b1;
	if(movrm)begin
		regfil[instruction_register[5:3]] <= DATA;
		next_state <= `cpus_fetchi1;
		movrm <= 1'b0;
	end else if(mvir)begin
		regfil[instruction_register[5:3]] <= DATA;
		next_state <= `cpus_fetchi1;
		mvir <= 1'b0;
	end else if(mvim)begin
		internalreg[`reg_z] <= DATA;
		next_state <= `cpus_write1;
	end else if(lxir || lxisp)begin
		if(lxisp) sp[7:0] <= DATA;
		else regfil[(instruction_register[5:3])+3'b001] <= DATA;
		next_state <= `cpus_read4;
	end else if(lda || sta || lhld || shld || xthl)begin
		internalreg[`reg_z] <= DATA;
		next_state <= `cpus_read4;
	end else if(ldax)begin
		internalreg[`reg_a] <= DATA;
		next_state <= `cpus_fetchi1;
		ldax <= 1'b0;
	end else if(popr || poppsw)begin
		if(poppsw) flag_reg <= DATA;
		else regfil[{instruction_register[5:4],1'b0}+3'b001] <= DATA;
		next_state <= `cpus_read4;
	end else if(inport || outport)begin
		internalreg[`reg_z] <= DATA;
		internalreg[`reg_w] <= DATA;
		if(inport)  next_state <= `cpus_input1;
		else next_state <= `cpus_output1;
	end else if(addm || adi || adcm || aci || subm || sbbm || sui || sbi || inrm || dcrm || anam || ani || xram || xri || oram || ori || cmpm || cmpi)begin
		temporary_register <= DATA;	//da rivedere
		if(inrm || dcrm) next_state <= `cpus_write1;
		else next_state <= `cpus_fetchi1;
	end
	end
	end

	`cpus_read4: begin
	S0 <= 1'b0;
	S1 <= 1'b1;
	if(lxir || lxisp || lda || sta || lhld || shld)begin
		address_buffer <= pc[15:8];
		data_out <= pc[7:0];
	end else if(popr || poppsw || xthl)begin
		address_buffer <= sp[15:8];
		data_out <= sp[7:0];		
	end
	next_state <= `cpus_read5;
	end

	`cpus_read5: begin
	RDn <= 1'b0;
	WRn <= 1'b1;
	if(lxir || lxisp || lda || sta || lhld || shld) pc <= pc + 16'h0001;
	else if(popr || poppsw) sp <= sp + 16'h0001;
	next_state <= `cpus_read6;
	end

	`cpus_read6: begin
	if(!READY) next_state <= `cpus_wait;
	else begin
	RDn <= 1'b1;
	if(lxir || lxisp)begin
		if(lxisp) sp[15:8] <= DATA;
		else regfil[instruction_register[5:3]] <= DATA;
		next_state <= `cpus_fetchi1;
		lxir <= 1'b0;
		lxisp <= 1'b0;
	end else if(lda || lhld || xthl)begin
		internalreg[`reg_w] <= DATA;
		if(xthl) next_state <= `cpus_write1;  //FINIRE XTHL !!!!!!!!
		else next_state <= `cpus_read7;
	end else if(sta || shld)begin
		internalreg[`reg_w] <= DATA;
		next_state <= `cpus_write1;
	end else if(popr || poppsw)begin
		if(poppsw) regfil[`reg_a] <= DATA;
		else regfil[{instruction_register[5:4],1'b0}] <= DATA;
		popr <= 1'b0;
		poppsw <= 1'b0;
		next_state <= `cpus_fetchi1;
	end
	end
	end

	`cpus_read7: begin
	S0 <= 1'b0;
	S1 <= 1'b1;
	address_buffer <= internalreg[`reg_w];
	data_out <= internalreg[`reg_z];
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
	if(lhld)begin//LHLD
		regfil[`reg_l] <= DATA;
		next_state <= `cpus_read10;
	end else if(lda)begin//LDA
		regfil[`reg_a] <= DATA;
		lda <= 1'b0;
		next_state <= `cpus_fetchi1;
		end
	end
	end

	`cpus_read10: begin
	S0 <= 1'b0;
	S1 <= 1'b1;
	address_buffer <= internalreg[`reg_w];
	data_out <= internalreg[`reg_z] + 8'b00000001;
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
		lhld <= 1'b0;
		next_state <= `cpus_fetchi1;
	end
	end

	`cpus_write1:begin
	IO_Mn <= 1'b0;
	S0 <= 1'b1;
	S1 <= 1'b0;
	if(movmr || mvim || inrm || dcrm)begin
		address_buffer <= regfil[`reg_h];
		data_out <= regfil[`reg_l];
	end else if(sta || shld)begin
		address_buffer <= internalreg[`reg_w];
		data_out <= internalreg[`reg_z];		
	end else if(stax)begin
		address_buffer <= regfil[{instruction_register[5:4],1'b0}];
		data_out <= regfil[{instruction_register[5:4],1'b0}+3'b001];
	end else if(pushr || pushpsw || xthl)begin
		address_buffer <= sp[15:8];
		data_out <= sp[7:0];
	end
	next_state <= `cpus_write2;
	end

	`cpus_write2:begin
	WRn <= 1'b0;
	RDn <= 1'b1;
	if(movmr)begin
		data_out <= regfil[instruction_register[2:0]];
		movmr <= 1'b0;
	end else if(mvim)begin
		data_out <= internalreg[`reg_z];
		mvim <= 1'b0;
	end else if(inrm || dcrm)begin
		if(inrm) data_out <= internalreg[`reg_z] + 8'h01;
		else if(dcrm) data_out <= internalreg[`reg_z] - 8'h01;
		inrm <= 1'b0;
		dcrm <= 1'b0;
	end else if(sta || stax)begin
		data_out <= regfil[`reg_a];
		sta <= 1'b0;
		stax <= 1'b0;
	end else if(shld)begin
		data_out <= regfil[`reg_l];
	end else if(pushr) data_out <= regfil[{instruction_register[5:4],1'b0}];
	else if(pushpsw) data_out <= regfil[`reg_a];
	else if(xthl) data_out <= regfil[`reg_h];
	next_state <= `cpus_write3;
	end

	`cpus_write3:begin
	WRn <= 1'b1;
	if(shld) next_state <= `cpus_write4;	//PUSH
	else if(pushr || pushpsw || xthl)begin
		if(xthl) regfil[`reg_h] <= internalreg[`reg_w];
		sp <= sp - 16'h0001;
		next_state <= `cpus_write4;
	end
	else next_state <= `cpus_fetchi1;
	end

	`cpus_write4:begin
	IO_Mn <= 1'b0;
	S0 <= 1'b1;
	S1 <= 1'b0;
	if(shld)begin
		/*if(internalreg[`reg_z] == 8'hFF)begin
			data_out <= 8'h00;
			address_buffer <= internalreg[`reg_w]++;
		end else begin
			data_out <= internalreg[`reg_z]++;
			address_buffer <= internalreg[`reg_w];
		end*/{address_buffer,data_out} <= {internalreg[`reg_w],internalreg[`reg_z]} + 16'h0001;
	end else if(pushr || pushpsw || xthl)begin
		address_buffer <= sp[15:8];
		data_out <= sp[7:0];
	end
	next_state <= `cpus_write5;
	end

	`cpus_write5:begin
	WRn <= 1'b0;
	RDn <= 1'b1;
	if(shld)begin
		data_out <= regfil[`reg_h];
		shld <= 1'b0;
	end else if(pushr)begin
		data_out <= regfil[{instruction_register[5:4],1'b0} + 3'b001];
		pushr <= 1'b0;
	end else if(pushpsw)begin
		data_out <= flag_reg;
		pushpsw <= 1'b0;
	end else if(xthl)begin
		data_out <= regfil[`reg_l];
	end
	next_state <= `cpus_write6;
	end

	`cpus_write6:begin
	WRn <= 1'b1;
	if(xthl)begin
		regfil[`reg_l] <= internalreg[`reg_z];
		xthl <= 1'b0;
	end
	next_state <= `cpus_fetchi1;
	end

	`cpus_input1:begin
	IO_Mn <= 1'b1;
	S0 <= 1'b0;
	S1 <= 1'b1;
	RDn <= 1'b1;
	WRn <= 1'b1;
	address_buffer <= internalreg[`reg_w];
	data_out <= internalreg[`reg_z];
	next_state <= `cpus_input2;
	end

	`cpus_input2:begin
	RDn <= 1'b0;
	end

	`cpus_busidle1:begin
	IO_Mn <= 1'b0;
	S0 <= 1'b0;
	S1 <= 1'b1;
	internalreg[`reg_w] <= regfil[`reg_a];
	internalreg[`reg_z] <= flag_reg;
	next_state <= `cpus_busidle2;
	end

	`cpus_busidle2:begin
	if(instruction_register[5:4] == 2'b11) regfil[`reg_a] <= sp[7:0];
	else regfil[`reg_a] <= regfil[{instruction_register[5:4],1'b0}+3'b001];
	temporary_register <= regfil[`reg_l];
	next_state <= `cpus_busidle3;
	end

	`cpus_busidle3:begin
	regfil[`reg_l] <= regfil[`reg_a] + temporary_register;
	next_state <= `cpus_busidle4;
	end

	`cpus_busidle4:begin
	IO_Mn <= 1'b0;
	S0 <= 1'b0;
	S1 <= 1'b1;
	if(instruction_register[5:4] == 2'b11) regfil[`reg_a] <= sp[15:8];
	else regfil[`reg_a] <= regfil[{instruction_register[5:4],1'b0}];
	temporary_register <= regfil[`reg_h];
	next_state <= `cpus_busidle5;
	end

	`cpus_busidle5:begin
	regfil[`reg_h] <= regfil[`reg_a] + temporary_register + flag_reg[0];
	next_state <= `cpus_busidle6;
	end

	`cpus_busidle6:begin
	regfil[`reg_a] <= internalreg[`reg_w];
	flag_reg <= internalreg[`reg_z];
	next_state <= `cpus_fetchi1;
	end

	endcase
end

assign ADD 	= address_buffer;
assign DATA 	= ((~WRn&~IO_Mn&RDn)|ALE) ? data_out : 8'bzzzzzzzz;;
endmodule
