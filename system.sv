`timescale 1ns / 1ps

module system
(
input logic clk,
input logic rst,

output logic S0,
output logic S1,
output logic IOMn,
output logic RDn
);

wire [7:0] bus;
wire [15:0] address_bus;


cpu8080 U1(.clock(clk),.reset_in(rst),.ADD(address_bus),.DATA(bus),.RDn(RDn),.READY(ready),.IO_Mn(IOMn),.S0(S0),.S1(S1));
rom8775 U2(.CLK(clk),.RESET(rst),.ADD(address_bus),.AD(bus),.READY(ready),.RDn(RDn),.IO_Mn(IOMn));

endmodule
