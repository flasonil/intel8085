module rom8775
(
inout logic [7:0] AD,
input logic [7:0] ADD,
input logic RDn,
input logic IO_Mn,
input logic CSn,

input logic CLK,
input logic RESET,

output logic READY
);
logic MemRead;
logic [7:0] datao,address;

always@(negedge CLK)begin
	if(RESET) READY <= 1'b1;
	else
	case(ADD)

	`include "test2.rom" // get contents of memory
	default datao = 8'h76; // hlt

endcase
end

assign MemRead = ((~RDn & ~IO_Mn)&~CSn);
assign AD = (MemRead) ? datao : 8'bzzzzzzzz;

endmodule
