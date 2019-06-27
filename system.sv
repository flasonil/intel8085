`timescale 1ns / 1ps

/*Current address space organization:

0xFFFF
 |
 |	EMPTY
 |
0x0200

0x01FF
 |
 |	256 byte ROM
 |
0x0100

0x00FF
 |
 |	256 byte RAM
 |
0x0000

*/
module system
(
input logic clk,
input logic rst,

output logic S0,
output logic S1,
output logic IOMn,
output logic RDn,
output logic WRn
);

wire [7:0] bus;
wire [15:0] address_bus;

// always@(ALE or bus)begin
//	if(ALE) address <= {address_bus,bus};
//end


cpu8080 U1(.clock(clk),.reset_in(rst),.ADD(address_bus),.DATA(bus),.RDn(RDn),.READY(ready),.IO_Mn(IOMn),.S0(S0),.S1(S1),.WRn(WRn));
rom8775 U2(.CLK(clk),.RESET(rst),.ADD(address_bus[7:0]),.AD(bus),.READY(ready),.RDn(RDn),.IO_Mn(IOMn),.CSn(~(~address_bus[15]&~address_bus[14]&~address_bus[13]&~address_bus[12]&~address_bus[11]&~address_bus[10]&~address_bus[9]&address_bus[8])));
ram8156 U3(.clk(clk),.rst(rst),.address(address_bus[7:0]),.data(bus),.IOMn(IOMn),.RDn(RDn),.WRn(WRn),.CSn(~(~address_bus[15]&~address_bus[14]&~address_bus[13]&~address_bus[12]&~address_bus[11]&~address_bus[10]&~address_bus[9]&~address_bus[8])));

endmodule
