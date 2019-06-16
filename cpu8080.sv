
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
`define cpus_write1		6'h0e
`define cpus_write2		6'h0f
`define cpus_write3		6'h10
`define cpus_wait		6'h0b

`define reg_b	3'b000
`define reg_c	3'b001
`define reg_d	3'b010
`define reg_e	3'b011
`define reg_h	3'b100
`define reg_l	3'b101
`define reg_m	3'b110
`define reg_a	3'b111

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
output logic [15:0] ADD,
output logic [5:0] state
);

logic [5:0] next_state;
logic [15:0] pc,address;

logic [7:0] data_in,data_out,temp_reg_z,accumulator;

logic [7:0] regfil[0:7];
logic lowByteSaved;

always@(negedge clock)begin
	if(reset_in) begin
	state <= `cpus_idle;
	pc <= /*16'b0000010100000010*/16'b0000000100000000;
	regfil <= {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
	lowByteSaved <= 1'b0;
	end else begin
	state <= next_state;
	//address <= pc;
	end
end

always@(state)begin
	case (state)

	`cpus_idle: next_state <= `cpus_fetchi1;

	`cpus_fetchi1: begin
	ADD <= /*address*/pc;
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
			if(data_in[5:0]==3'b000010 || data_in[5:0]==3'b010010) next_state <= `cpus_write1; //STAX
			else if(data_in[5:0] == 6'b101010 || data_in[5:0] == 6'b011010)//LDAX
			next_state <= `cpus_read1;
			else if(data_in[5:0] == 6'b110010)begin		//STA
			next_state <= `cpus_read1;
			pc <= pc + 1;
			end else if(data_in[5:0] == 6'b111010)		//LDA
			next_state <= `cpus_read1;			
			else begin
			pc <= pc + 1;
			next_state <= `cpus_read1;
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
		end
		endcase
	end

	`cpus_read1: begin
	S0 <= 1'b0;
	S1 <= 1'b1;
	if(data_in == 8'b00101010) ADD <= {regfil[`reg_b],regfil[`reg_c]};		//LDAX B
	else if(data_in == 8'b00011010) ADD <= {regfil[`reg_d],regfil[`reg_e]};		//LDAX D
	else ADD <= pc;
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
		temp_reg_z <= DATA;
	end
	else if(data_in == 8'b00101010 || data_in == 8'b00011010)
		accumulator <= DATA;

	else if(data_in[7:6]==2'b00&&data_in[2:0]==3'b001)begin	//LXI
		if(!lowByteSaved)begin					//LXI saving low byte
		regfil[(data_in[5:3])+1] <= DATA;
		lowByteSaved <= 1'b1;
		pc <= pc + 1;
		next_state <= `cpus_read1;
		end else begin						//LXI saving high byte
		regfil[data_in[5:3]] <= DATA;
		lowByteSaved <= 1'b0;
		pc <= pc + 1;
		next_state <= `cpus_fetchi1;
		end
	end else if(data_in[7:6]==2'b01 && data_in[2:0]==2'b110) begin //MOV memory to register
		regfil[data_in[5:3]] <= DATA;
	end else begin
		regfil[data_in[5:3]] <= DATA;	//MVI to regfile: save immediate to register file
		pc <= pc + 1;
		next_state <= `cpus_fetchi1;
		end
	end
	end

	`cpus_write1:begin
	IO_Mn <= 1'b0;
	S0 <= 1'b1;
	S1 <= 1'b0;
	if(data_in[7:3] == 6'b00110)begin //MOV immediate to memory
		ADD <= {regfil[`reg_h],regfil[`reg_l]};
		data_out <= temp_reg_z;
	end else if(data_in[7:3] == 6'b01110)begin //MOV register to memory
		ADD <= {regfil[`reg_h],regfil[`reg_l]};
		data_out <= regfil[data_in[2:0]];
	end else if(data_in[7:6]==2'b00 && data_in[2:0]==2'b010) begin	//STAX: move accumulator to Mem[B or D,C or F]
		ADD <= {regfil[data_in[5:3]],regfil[data_in[5:3] + 1]};
		data_out <= accumulator;
	end
	next_state <= `cpus_write2;
	end

	`cpus_write2:begin
	WRn <= 1'b0;
	RDn <= 1'b1;
	next_state <= `cpus_write3;
	end

	`cpus_write3:begin
	WRn <= 1'b1;
	pc <= pc + 1;
	next_state <= `cpus_fetchi1;
	end
	endcase
end
assign DATA = (~WRn&~IO_Mn&RDn) ? data_out : 8'bzzzzzzzz;;
endmodule

