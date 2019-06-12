
`timescale 1ns / 1ps

`define cpus_idle		6'h00 // Idle
`define cpus_fetchi1		6'h01
`define cpus_fetchi2		6'h02
`define cpus_fetchi3		6'h03
`define cpus_fetchi4		6'h04

module cpu8080
(
inout logic [7:0] AD,

input logic clock,
input logic reset_in,
//input logic READY,

output logic S0,
output logic S1,
output logic IO_Mn,
output logic RDn,
output logic WRn,
output logic ALE,
output logic [7:0] ADD,
output logic [1:0] state
);

logic [1:0] next_state;
logic [15:0] pc,pc_int;
logic ale_en;
logic [7:0] addr_out, data_in;

always@(negedge clock)begin
	if(reset_in)
	state <= `cpus_idle;
	else state <= next_state;
end

always@(state)begin

/*	if(reset_in) begin
	state <= `cpus_fetchi1;
	pc <= 1'b0;
	ale_en <= 1'b0;
	IO_Mn <= 1'bz;
	RDn <= 1'bz;
	WRn <= 1'bz;
	end*/


	/*else*/ case (state)

	`cpus_idle: next_state <= `cpus_fetchi1;

	`cpus_fetchi1: begin
	IO_Mn <= 1'b0;
	ale_en <= 1'b1;
	S0 <= 1'b1;
	S1 <= 1'b1;
	RDn <= 1'b1;
	WRn <= 1'b1;
	next_state <= `cpus_fetchi2;
	end

	`cpus_fetchi2: begin
	ale_en <= 1'b0;
	end

	endcase
end
	
assign AD = RDn ? 8'bzzzzzzzz : pc[7:0];
assign data_in = RDn ? AD :8'b00000000;
assign ALE = (~clock) & ale_en;

endmodule