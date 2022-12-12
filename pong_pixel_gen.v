module pong_pixel_gen
(
	input clk,reset_n,
	input video_on,
	input [1:0] btn,
	input [9:0] pixel_x,pixel_y,
	output reg [2:0] pixel_rgb
);

localparam MAX_X=640;
localparam MAX_Y = 480;
//wall boundaries
localparam WALL_X_L = 32;
localparam WALL_X_R = 35;
//vertial bar
localparam BAR_X_L = 600;
localparam BAR_X_R = 603;
localparam BAR_Y_SIZE = 72;
wire [9:0] bar_y_t,bar_y_b;
reg [9:0] bar_y_reg,bar_y_next;
localparam BAR_V = 4;
//square ball
localparam BALL_SIZE=8;
wire [9:0] ball_x_l,ball_x_r;
wire [9:0] ball_y_t,ball_y_b;
reg [9:0] ball_x_reg,ball_y_reg;
wire [9:0] ball_x_next,ball_y_next;
reg [9:0] x_delta_reg,x_delta_next;
reg [9:0] y_delta_reg, y_delta_next;
wire refr_tick;
localparam BALL_V_P = 2;
localparam BALL_V_N = -2;
//round ball
wire [2:0] rom_addr,rom_col;
reg [7:0] rom_data;
wire rom_bit;

//objects signals
wire wall_on, bar_on,sq_ball_on,rd_ball_on;
wire [2:0] wall_rgb,bar_rgb,ball_rgb;

//body
//round ball image rom
always @(*)
begin
	case (rom_addr)
		3'h0: rom_data = 8'b00111100; // ****
		3'h1: rom_data = 8'b01111110; // ******
		3'h2: rom_data = 8'b11111111; // ********
		3'h3: rom_data = 8'b11111111; // ********
		3'h4: rom_data = 8'b11111111; // ********
		3'h5: rom_data = 8'b11111111; // ********
		3'h6: rom_data = 8'b01111110; // ******
		3'h7: rom_data = 8'b00111100; // **** 
	endcase
end
//registers
always @(posedge clk or negedge reset_n) begin
	if(~reset_n) begin
		bar_y_reg <= 0;
		ball_x_reg <= 0;
		ball_y_reg <= 0;
		x_delta_reg <= 0;
		y_delta_reg <= 0;
	end else begin
	 	bar_y_reg <= bar_y_next;
		ball_x_reg <= ball_x_next;
		ball_y_reg <= ball_y_next;
		x_delta_reg <= x_delta_next;
		y_delta_reg <= y_delta_next;
	end
end
//refr tick
assign refr_tick = (pixel_y == 481) && (pixel_x == 0);

//wall pixel gen
assign wall_on = (pixel_x >= WALL_X_L) && (pixel_x <=WALL_X_R);
assign wall_rgb = 3'b001;
//bar pixel gen
assign bar_y_t = bar_y_reg;
assign bar_y_b = bar_y_t + BAR_Y_SIZE - 1;

assign bar_on = (pixel_x >= BAR_X_L) && (pixel_x <= BAR_X_R) &&
(pixel_y >= bar_y_t) && (pixel_y <= bar_y_b);

assign bar_rgb = 3'b100;

always @(*)
begin
	bar_y_next = bar_y_reg;
	if(refr_tick)
		if(btn[1] && (bar_y_b < (MAX_Y-1-BAR_V)))
			bar_y_next = bar_y_reg + BAR_V;
		else if(btn[0] & (bar_y_t > BAR_V))
			bar_y_next = bar_y_reg - BAR_V;
end
//ball pixel gen
assign sq_ball_on = (pixel_x >= ball_x_l) && (pixel_x <= ball_x_r) &&
(pixel_y >= ball_y_t) && (pixel_y <= ball_y_b);

assign ball_x_l = ball_x_reg;
assign ball_y_t = ball_y_reg;
assign ball_x_r = ball_x_l + BALL_SIZE -1;
assign ball_y_b = ball_y_t + BALL_SIZE -1;
//map current pixel location to rom addr/col
assign rom_addr = pixel_y[2:0] - ball_y_t[2:0];
assign rom_col = pixel_x[2:0] - ball_x_l[2:0];
assign rom_bit = rom_data[rom_col];

assign rd_ball_on = sq_ball_on && rom_bit;
assign ball_rgb =3'b100;
assign ball_x_next = (refr_tick)? ball_x_reg + x_delta_reg: ball_x_reg;
assign ball_y_next = (refr_tick)? ball_y_reg + y_delta_reg: ball_y_reg;
always @*
begin
	x_delta_next = x_delta_reg;
	y_delta_next = y_delta_reg;
	if(ball_y_t < 1)
		y_delta_next = BALL_V_P;
	else if(ball_y_b> MAX_Y-1)
		y_delta_next = BALL_V_N;
	else if(ball_x_l <= WALL_X_R)
		x_delta_next = BALL_V_P;
	else if(ball_x_r >=BAR_X_L && ball_x_r <= BAR_X_R && 
		ball_y_b >= bar_y_t && ball_y_t <= bar_y_b)
		x_delta_next = BALL_V_N;
	else if(ball_x_r >= MAX_X)
		x_delta_next = BALL_V_N;
end

always @(*)
begin
	if(~video_on)
			pixel_rgb = 3'b000;
	else 
		if(wall_on)
			pixel_rgb = wall_rgb;
		else if(bar_on)
			pixel_rgb = bar_rgb;
		else if(rd_ball_on)
			pixel_rgb = ball_rgb;
		else
			pixel_rgb = 3'b110;
end
endmodule