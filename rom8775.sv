module rom8775
(
inout logic [7:0] AD,
input logic [15:0] ADD,
input logic RDn,
input logic IO_Mn,

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

	`include "test.rom" // get contents of memory
	default datao = 8'h76; // hlt

endcase
end

/*always@(address) begin


case(address)

	`include "test.rom" // get contents of memory
	default datao = 8'h76; // hlt

endcase
//READY <= 1'b1;
end*/

assign MemRead = ~(~RDn & ~IO_Mn);
assign AD = MemRead ? 8'bzzzzzzzz : datao;

endmodule
