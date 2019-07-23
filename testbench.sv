`timescale 1ns/1ps
module testbench();

logic x1,x2;
logic phi1,phi2;
logic clk_out;
logic resetn_in,reset,reset_out;

system DUT(.x1(x1),.x2(x2),/*.phi1(phi1),.phi2(phi2),.clk_out(clk_out),*/.resetn_in(resetn_in)/*,.reset(reset),.reset_out(reset_out)*/);

always begin
x1 = 0;
#5;
x1 = 1;
#5;
end

initial begin
resetn_in = 0;
//#380 resetn_in = 0;
#560 resetn_in = 1;
#3000 $stop;
end

assign x2 = ~x1;

endmodule
