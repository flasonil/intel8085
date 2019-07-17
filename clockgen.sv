module clockgen
(
	input logic x1,x2,resetn_in,

	output logic clk_out,phi1,phi2,reset,reset_out
);
logic [2:0] counter;
logic reset_rec;
initial begin
counter = 0;
end

always@(negedge x1)begin
	if(counter == 1) phi1 <= 1;
	else if(counter == 3) phi1 <= 0;
	else if(counter == 5) phi2 <= 1;
	else if(counter == 7) phi2 <= 0;
	counter++;
end

always@(phi2)begin
	reset_rec <= ~resetn_in;
	reset_out <= reset;
end

always@(phi1)begin
	reset <= reset_rec;
end

assign clk_out = ~phi1;

endmodule
