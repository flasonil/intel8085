`timescale 1ns / 1ps

module system
(
input logic clk,
input logic rst
);

wire [7:0] bus, address_bus;
logic S0,S1,WRn,RDn,IOMn,ale;

cpu8080 U1(.clock(clk),.reset_in(rst),.ADD(address_bus),.AD(bus),.S0(S0),.S1(S1),.IO_Mn(IOMn),.WRn(WRn),.RDn(RDn),.ALE(ale));
rom8775 U2(.CLK(clk),.RESET(rst),.AD(address_bus),.A(bus),.ALE(ale),.RDn(RDn));

endmodule