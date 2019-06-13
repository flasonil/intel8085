
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
`define cpus_write		6'h0e
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

/*output logic S0,
output logic S1,
output logic IO_Mn,*/
output logic RDn,
//output logic WRn,
output logic [15:0] ADD,
output logic [5:0] state
);

logic [5:0] next_state;
logic [15:0] pc,address,data_address;
logic ale_en, fetch_data;
logic [7:0] data_in;

logic [7:0] regfil[0:7];

always@(negedge clock)begin
	if(reset_in) begin
	state <= `cpus_idle;
	pc <= 16'b0000010100000010;
	regfil <= {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
	fetch_data <= 1'b1;
	end else begin
	state <= next_state;
	if(fetch_data) address <= pc;
	else address <= data_address;
end
end

always@(state)begin
	case (state)

	`cpus_idle: next_state <= `cpus_fetchi1;

	`cpus_fetchi1: begin
	ADD <= address;
	
	RDn <= 1'b1;
	next_state <= `cpus_fetchi2;
	end

	`cpus_fetchi2: begin
	pc <= pc + 16'b0000000000000001;
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
			if(data_in[2:0] == 3'b110) begin
			next_state <= `cpus_read1;
			fetch_data <= 1'b0;
			end
		end

		2'b01:begin
			if(data_in[5:0] == 6'b110110) next_state <= `cpus_halt;
			else begin
				if(data_in[2:0] == `reg_m)begin
					data_address <= {regfil[`reg_h],regfil[`reg_l]};
					fetch_data <= 1'b0;
					next_state <= `cpus_read1;
					end
				else if(data_in[5:3] == `reg_m)
					next_state <= `cpus_write;
				else begin
				regfil[data_in[5:3]] <= regfil[data_in[2:0]];
				next_state = `cpus_fetchi1;
				end
			end
		end
		endcase
	end

	`cpus_read1: begin
	ADD <= address;
	next_state <= `cpus_read2;
	end

	`cpus_read2: begin
	RDn <= 1'b0;
	next_state <= `cpus_read3;
	end

	`cpus_read3: begin
	if(!READY) next_state <= `cpus_wait;
	else begin
	next_state <= `cpus_fetchi1;
	regfil[data_in[5:3]] <= DATA;
	fetch_data <= 1'b1;
	RDn <= 1'b1;
	end
	end
	endcase
end
//assign address = fetch_data ? pc : data_address;
endmodule

