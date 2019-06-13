`timescale 1ns / 1ps

module system
(
input logic clk,
input logic rst
);

wire [7:0] bus;
wire [15:0] address_bus;
logic S0,S1,WRn,RDn,IOMn,ready;

cpu8080 U1(.clock(clk),.reset_in(rst),.ADD(address_bus),.DATA(bus),.RDn(RDn),.READY(ready));
rom8775 U2(.CLK(clk),.RESET(rst),.ADD(address_bus),.AD(bus),.READY(ready),.RDn(RDn));

endmodule
