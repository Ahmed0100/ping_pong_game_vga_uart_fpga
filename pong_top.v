module pong_top
(
	input clk,reset_n,
	input [1:0] btn,
	input rx,
	output vga_hsync,vga_vsync,
	output [2:0] vga_rgb
);

//signal declarations
wire [11:0] pixel_x,pixel_y;
wire video_on;
reg rd_uart;
wire [7:0] rd_data;
reg [2:0] rgb_reg;
wire [2:0] rgb_next;
wire [1:0] btn_db;
reg [1:0] player_2_reg,player_2_next;
wire rx_empty;

//body
always @(posedge clk or negedge reset_n)
begin
	if(~reset_n)
	begin
		player_2_reg <= 0;
	end
	else
	begin
		player_2_reg <= player_2_next;
	end
end

always @(*)
begin
	player_2_next = player_2_reg;
	rd_uart=0;
	if(pixel_y == 500 && pixel_x == 0)
	begin
		rd_uart = 1;
		player_2_next = 0;
	end
	else if(~rx_empty)
	begin
		if(rd_data == 8'h73) player_2_next = 2'b10;
		else if(rd_data == 8'h77) player_2_next = 2'b01;
	end
end

db_fsm db_fsm_inst_0
(.clk(clk), .reset_n(reset_n), .sw(!btn[0]), 
	 .db_level(btn_db[0]));

	 db_fsm db_fsm_inst_1
(.clk(clk), .reset_n(reset_n), .sw(!btn[1]), 
	 .db_level(btn_db[1]));
	 
vga_sync vga_sync_inst
(.clk(clk), .rst_n(reset_n), .hsync(vga_hsync), .vsync(vga_vsync), .pixel_x(pixel_x), .pixel_y(pixel_y),
	.video_on(video_on));

ping_pong_2_players pong_pixel_gen_inst
(	.clk(clk),.reset_n(reset_n),
	.video_on(video_on),
	.key({player_2_reg,btn_db}),
	.pixel_x(pixel_x),.pixel_y(pixel_y),
	.rgb(rgb_next)
);

uart m3
(
	.clk(clk),
	.reset_n(reset_n),
	.rd_uart(rd_uart),
	.wr_uart(0),
	.wr_data(),
	.rx(rx),
	.tx(),
	.rd_data(rd_data),
	.rx_empty(rx_empty),
	.tx_full()
);
always @(posedge clk or negedge reset_n)
begin
	if(~reset_n)
		rgb_reg <= 0;
	else
		rgb_reg <= rgb_next;
end
assign vga_rgb = rgb_reg;
endmodule