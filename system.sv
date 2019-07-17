module system
(
	input logic x1,x2,resetn_in
);
logic S0int,S1int,RDnint,WRnint,ALEint,IOMnint;
wire [7:0] bus,address_bus;
logic [15:0] address;
logic clk,rst;
always@(ALEint or bus)begin
	if(ALEint) address <= {address_bus,bus};
end

top top(.x1(x1),.x2(x2),.resetn_in(resetn_in),.haddress(address_bus),.laddress_data(bus),.RDn(RDnint),/*.READY(ready),*/.IOMn(IOMnint),.S0(S0int),.S1(S1int),.WRn(WRnint),.ALE(ALEint),.clk_out(clk),.reset_out(rst));
rom8775 rom8775(.CLK(clk),.RESET(rst),.ADD(address[7:0]),.AD(bus),.READY(ready),.RDn(RDnint),.IO_Mn(IOMnint),.CSn(~(~address_bus[7]&~address_bus[6]&~address_bus[5]&~address_bus[4]&~address_bus[3]&~address_bus[2]&~address_bus[1]&address_bus[0])));
ram8156 ram8156(.clk(clk),.rst(rst),.address(address[7:0]),.data(bus),.IOMn(IOMnint),.RDn(RDnint),.WRn(WRnint),.CSn(~(~address_bus[7]&~address_bus[6]&~address_bus[5]&~address_bus[4]&~address_bus[3]&~address_bus[2]&~address_bus[1]&~address_bus[0])));

endmodule