module rom8775
(
input logic ALE,
inout logic [7:0] AD,
input logic [2:0] A,
input logic RDn,
//input logic CE1n,
//input logic CE2n,
//input logic IOMn,
input logic CLK,
input logic RESET,
//input logic IORn,

output logic READY
);

logic [7:0] datao,address;

always@(address) case(address)

	`include "test.rom" // get contents of memory
	default datao = 8'h76; // hlt

endcase

assign address = {A,AD};
assign AD = RDn ? datao : 8'bzzzzzzzz;

endmodule