`timescale 1ns/1ps

module testbench();

logic clk,rst,s0,s1,ale,iomn,rdn,wrn;
logic [1:0] st;
wire [7:0] address_data,address_bus;

cpu8080 DUT (.clock(clk),.reset_in(rst),.S0(s0),.S1(s1),.IO_Mn(iomn),.RDn(rdn),.WRn(wrn),.ALE(ale),.ADD(address_bus),.state(st));

always begin

#5 clk = !clk;

end

initial begin
clk = 1;
rst = 1;

#9 rst = 0;

@(posedge clk);
@(posedge clk);
@(posedge clk);
@(posedge clk);
@(posedge clk);
@(posedge clk);
@(posedge clk);
$stop;
end

endmodule