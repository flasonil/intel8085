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
integer i;
logic [7:0] datao;
logic [7:0] memory[0:256];

always@(negedge clk) begin
	if(rst) begin
		for(i=0;i<256;i++)
			memory[i] <= 8'b00000000;
	end else begin
	if(MemWrite)
		memory[address] <= data;
	else datao <= memory[address];
	end
end

assign MemRead = ((~RDn & ~IOMn)&~CSn);
assign MemWrite = ((~WRn & ~IOMn)&~CSn);

assign data = (MemRead) ? datao : 8'bzzzzzzzz;

endmodule
