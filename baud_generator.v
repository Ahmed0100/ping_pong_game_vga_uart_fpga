module baud_generator
(
	input clk,reset_n,
	input [11:0] baud_dvsr,
	output reg s_tick
);

reg [11:0] counter=0;
always @(posedge clk or negedge reset_n)
begin
	if(~reset_n)
		counter <= 0;
	else 
	begin
		s_tick = 0;
		if(counter == baud_dvsr-1)
		begin
			s_tick = 1;
			counter <= 0;
		end
		else
			counter <= counter + 1;
	end
end
endmodule