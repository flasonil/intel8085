module ram8156
(
input logic clk,
input logic rst,

input logic [7:0] address,
inout logic [7:0] data,

input logic CSn,
input logic WRn,
input logic RDn,
input logic IOMn
);
logic MemRead,MemWrite;

logic [7:0] datao;
logic [7:0] memory[0:256];

always@(negedge clk) begin
	/*if(rst)
	else begin*/
	if(MemWrite)
		memory[address] <= data;
	else datao <= memory[address];
end

assign MemRead = ~(~RDn & ~IOMn);
assign MemWrite = ~(~WRn & ~IOMn);

assign data = MemRead ? 8'bzzzzzzzz : datao;

endmodule