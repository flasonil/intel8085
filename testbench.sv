`timescale 1ns/1ps

module testbench();

logic clk,rst,s0,s1,ale,iomn,rdn,wrn;
logic [1:0] st;
logic [7:0] data_bus,address_bus;

system DUT (.clk(clk),.rst(rst)/*,.S0(s0),.S1(s1),.IO_Mn(iomn),.RDn(rdn),.WRn(wrn),.ADD(address_bus),.state(st),.DATA(data_bus)*/);

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
@(posedge clk);
@(posedge clk);
@(posedge clk);
@(posedge clk);
@(posedge clk);
@(posedge clk);
@(posedge clk);
@(posedge clk);
@(posedge clk);
@(posedge clk);
@(posedge clk);
@(posedge clk);
@(posedge clk);
@(posedge clk);
@(posedge clk);
@(posedge clk);
$stop;
end

always @(posedge clk) begin
    $display ("[Time %0t ps] data value = %x", $time, DUT.U1.data_in);
end

endmodule
