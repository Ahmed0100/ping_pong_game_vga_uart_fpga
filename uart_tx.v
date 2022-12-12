module uart_tx
#(parameter DBIT=8, SB_TICK=16)
(
	input clk,reset_n,
	input tx_start, s_tick,
	input [7:0] din,
	input [3:0] data_bits,
	input [5:0] stop_bits,
	input [1:0] parity_bits,
	output reg tx_done_tick,
	output tx
);
localparam [2:0]
	IDLE=3'b000,
	START=3'b001,
	DATA=3'b010,
	PARITY=3'b011,
	STOP=3'b100;

reg [2:0] current_state,next_state;
reg [5:0] s_reg,s_next;
reg [2:0] n_reg,n_next;
reg [7:0] b_reg,b_next;
reg tx_reg,tx_next;
reg [7:0] din_temp;

always @(posedge clk or negedge reset_n)
begin
	if(~reset_n)
	begin
		current_state <= IDLE;
		s_reg <= 0;
		n_reg <=0;
		b_reg <=0;
		tx_reg <= 1;
	end
	else
	begin
		current_state <= next_state;
		s_reg <= s_next;
		n_reg <= n_next;
		b_reg <= b_next;
		tx_reg <= tx_next;
	end
end	
always @*
begin
	next_state = current_state;
	tx_done_tick=0;
	s_next =s_reg;
	n_next = n_reg;
	b_next = b_reg;
	tx_next = tx_reg;
	din_temp = 0;
	case(current_state)
		IDLE:
		begin
			tx_next = 1;
			if(tx_start)
			begin
				s_next = 0;
				b_next = din;
				next_state = START;
			end
		end
		START:
			begin
				tx_next = 0;
				if(s_tick)
					if(s_reg == 15)
					begin
						next_state = DATA;
						s_next = 0;
						n_next = 0;
					end
					else
						s_next = s_reg  +1;
			end
		DATA:
			begin
				tx_next = b_reg[0];
				if(s_tick)
					if(s_reg == 15)
					begin
						s_next = 0;
						b_next = b_reg>>1;
						if(n_reg == data_bits-1)
							next_state = PARITY;
						else
							n_next = n_reg + 1;
					end
					else
						s_next = s_reg + 1;
				end
		PARITY:
		begin
			if(parity_bits == 0)
				next_state = STOP;
			else
			begin
				din_temp = (data_bits ==8)? din : din[6:0];
				tx_next =(parity_bits == 1)? {!{^din_temp}}:{^din_temp};
				if(s_tick == 1)
					if(s_reg == 15)
					begin
						next_state = STOP;
						s_next = 0;
					end
					else
						s_next = s_reg + 1;
			end
		end
		STOP:
			begin
				tx_next = 1;
				if(s_tick)
					if(s_reg == stop_bits-1)
					begin
						next_state = IDLE;
						tx_done_tick = 1;
					end
					else
						s_next = s_reg + 1;
			end
		default:
			next_state = IDLE;
	endcase
end
assign tx = tx_reg;
endmodule