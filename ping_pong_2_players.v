module ping_pong_2_players
(
	input clk,reset_n,
	input video_on,
	input [3:0] key,
	input [11:0] pixel_x,pixel_y,
	output reg [2:0] rgb
);
localparam BAR_1_XL=100,
BAR_1_XR=105,
BAR_2_XL = 550,
BAR_2_XR = 555,
BAR_LEN = 80,
BAR_V = 10,
BALL_DIAM=7,
BALL_V=1;

wire bar_1_on,bar_2_on,ball_box;
reg ball_on;
reg [2:0] rom_addr;
reg [7:0] rom_data;
reg [9:0] bar_1_top_reg=220,bar_1_top_next;
reg [9:0] bar_2_top_reg = 220,bar_2_top_next;
reg [9:0] ball_x_reg=280,ball_x_next;
reg [9:0] ball_y_reg=200,ball_y_next;
reg ball_x_delta_reg=0, ball_x_delta_next;
reg ball_y_delta_reg=0, ball_y_delta_next;

//display conditions
assign bar_1_on = pixel_x >= BAR_1_XL && 
pixel_x <= BAR_1_XR && pixel_y >= bar_1_top_reg &&
pixel_y <= bar_1_top_reg + BAR_LEN;

assign bar_2_on = pixel_x >= BAR_2_XL && 
pixel_x <= BAR_2_XR && pixel_y >= bar_2_top_reg &&
pixel_y <= bar_2_top_reg + BAR_LEN;

assign ball_box = pixel_x >= ball_x_reg && pixel_x<= ball_x_reg + BALL_DIAM &&
pixel_y >= ball_y_reg && pixel_y <= ball_y_reg + BALL_DIAM;
//ball rom pattern
always @*
begin
	rom_addr=0;
	ball_on=0;
	if(ball_box)
	begin
		rom_addr = pixel_y - ball_y_reg;
		if(rom_data[pixel_x-ball_y_reg]) ball_on=1;
	end
end

always @* begin
	case(rom_addr)
		3'd0: rom_data=8'b0001_1000;
		3'd1: rom_data=8'b0011_1100;
		3'd2: rom_data=8'b0111_1110;
		3'd3: rom_data=8'b1111_1111;
		3'd4: rom_data=8'b1111_1111;
		3'd5: rom_data=8'b0111_1110;
		3'd6: rom_data=8'b0011_1100;
		3'd7: rom_data=8'b0001_1000;
	 endcase
end

always @(posedge clk or negedge reset_n)
begin
	if(!reset_n)
	begin
		bar_1_top_reg <= 220;
		bar_2_top_reg <= 220;
		ball_x_reg <= 280;
		ball_y_reg <= 280;
		ball_x_delta_reg <= 0;
		ball_y_delta_reg <= 0;
	end
	else
	begin
		bar_1_top_reg <= bar_1_top_next;
		bar_2_top_reg <= bar_2_top_next;
		ball_x_reg <= ball_x_next;
		ball_y_reg <= ball_y_next;
		ball_x_delta_reg <= ball_x_delta_next;
		ball_y_delta_reg <= ball_y_delta_next;	
	end
end
always @*
begin
	bar_1_top_next = bar_1_top_reg;
	bar_2_top_next = bar_2_top_reg;
	ball_x_next = ball_x_reg;
	ball_y_next = ball_y_reg;
	ball_x_delta_next = ball_x_delta_reg;
	ball_y_delta_next = ball_y_delta_reg;
	if(pixel_y == 500 && pixel_x==0)
	begin
		if(key[0] && bar_1_top_reg > BAR_LEN) bar_1_top_next = bar_1_top_reg - BAR_V;
		else if(key[1] && bar_1_top_reg <(480-BAR_LEN)) bar_1_top_next = bar_1_top_reg + BAR_V;
		
		if(key[2] && bar_2_top_reg> BAR_LEN) bar_2_top_next = bar_2_top_reg - BAR_V;
		else if(key[3] && bar_2_top_reg <(480- BAR_LEN)) bar_2_top_next = bar_2_top_reg + BAR_V;
	
		//bouncing ball
		if(ball_x_reg <= BAR_1_XR && ball_x_reg >= BAR_1_XL && 
		ball_y_reg+BALL_DIAM >= bar_1_top_reg && ball_y_reg <= bar_1_top_reg+BAR_LEN)
			ball_x_delta_next = ~ball_x_delta_reg;
		else if(ball_x_reg <= BAR_2_XR && ball_x_reg >= BAR_2_XL && 
		ball_y_reg+BALL_DIAM >= bar_2_top_reg && ball_y_reg <= bar_2_top_reg+BAR_LEN)
			ball_x_delta_next = ~ball_x_delta_reg;
		else if(ball_x_reg <=5) ball_x_delta_next = ~ball_x_delta_reg;
		else if(ball_x_reg + BALL_DIAM >= 640) ball_x_delta_next = ~ball_x_delta_reg;
		
			
		if(ball_y_reg <=5) ball_y_delta_next = ~ball_y_delta_reg;
		else if(ball_y_reg + BALL_DIAM >= 480) ball_y_delta_next = ~ball_y_delta_reg;
		
		ball_x_next = (ball_x_delta_next)? ball_x_reg + BALL_V : ball_x_reg - BALL_V;
		ball_y_next = (ball_y_delta_next)? ball_y_reg + BALL_V: ball_y_reg - BALL_V ;
	end
end
//overall display logic
always @(*)
begin
	rgb=0;
	if(video_on)
	begin
		if(bar_1_on) rgb = 3'b001;
		else if(bar_2_on) rgb = 3'b010;
		else if(ball_on) rgb=3'b100;
		else 
			rgb=3'b110;
	end
end
endmodule
