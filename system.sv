module system
(
	input logic S0,
	input logic S1,
	input logic IOMn,
	input logic RDn,
	input logic WRn,
	input logic ALE,

	input logic dbus_to_instr_reg,

	input logic clk,rst
);

wire [7:0] bus,address_bus;
logic [15:0] address;

always@(ALE or bus)begin
	if(ALE) address <= {address_bus,bus};
end

top U1(.clk(clk),.rst(rst),.haddress(address_bus),.laddress_data(bus),.RDn(RDn),/*.READY(ready),*/.IOMn(IOMn),.S0(S0),.S1(S1),.WRn(WRn),.ALE(ALE),.dbus_to_instr_reg(dbus_to_instr_reg));
rom8775 U2(.CLK(clk),.RESET(rst),.ADD(address[7:0]),.AD(bus),.READY(ready),.RDn(RDn),.IO_Mn(IOMn),.CSn(~(~address_bus[7]&~address_bus[6]&~address_bus[5]&~address_bus[4]&~address_bus[3]&~address_bus[2]&~address_bus[1]&address_bus[0])));
ram8156 U3(.clk(clk),.rst(rst),.address(address[7:0]),.data(bus),.IOMn(IOMn),.RDn(RDn),.WRn(WRn),.CSn(~(~address_bus[7]&~address_bus[6]&~address_bus[5]&~address_bus[4]&~address_bus[3]&~address_bus[2]&~address_bus[1]&~address_bus[0])));

endmodule