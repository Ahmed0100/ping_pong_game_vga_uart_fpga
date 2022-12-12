module uart_rx #(parameter DBIT=8, SB_TICK=16)
(
	input clk,reset_n,
	input rx,s_tick,
	input [3:0] data_bits,
	input [5:0] stop_bits,
	input [1:0] parity_bits,
	output reg rx_done_tick,
	output [7:0] dout,
	output reg parity_error,
	output reg frame_error
);

	localparam [2:0]
	IDLE =3'b000,
	START=3'b001,
	DATA=3'b010,
	PARITY=3'b011,
	STOP=3'b100;
	
	reg [2:0] current_state,next_state;
	reg [5:0] s_reg,s_next;
	reg [2:0] n_reg,n_next;
	reg [7:0] b_reg,b_next;
	reg parity_error_next,frame_error_next;

	always @(posedge clk or negedge reset_n)
	begin
		if(~reset_n)
		begin
			current_state<= IDLE;
			s_reg<=0;
			n_reg <=0;
			b_reg <=0;
			frame_error <=0;
			parity_error<=0;
		end
		else 
		begin
			current_state <= next_state;
			n_reg <= n_next;
			s_reg <= s_next;
			b_reg <= b_next;
			parity_error <= parity_error_next;
			frame_error <= frame_error_next;
		end
	end
	always @*
	begin
		next_state = current_state;
		rx_done_tick=0;
		s_next = s_reg;
		b_next = b_reg;
		n_next = n_reg;
		parity_error_next = parity_error;
		frame_error_next = frame_error;
		
		case(current_state)
			IDLE:
				if(~rx)
				begin
					next_state = START;
					s_next = 0;
				end
			START:
				if(s_tick)
					if(s_reg == 7)
					begin
						next_state = DATA;
						s_next = 0;
						n_next = 0;
					end
					else
						s_next = s_reg + 1;
			DATA:
			 if(s_tick)
				if(s_reg == 15)
				begin
					s_next = 0;
					b_next = {rx,b_reg[7:1]};
					if(n_reg == data_bits-1)
						next_state = PARITY;
					else
						n_next = n_reg + 1;
				end
				else
					s_next = s_reg + 1;
			PARITY:
			begin
				if(parity_bits == 0) next_state = STOP;
				else 
				begin
					if(s_tick)
						if(s_reg == 15)
						begin
							parity_error_next = (parity_bits == 1)? !{^{dout,rx}}:{^{dout,rx}};
							s_next = 0;
							next_state = STOP;
						end
						else 
							s_next = s_reg + 1;
				end
			end
			STOP:
				if(s_tick)
					if(s_reg==stop_bits-1)
					begin
						frame_error_next = ~rx;
						next_state = IDLE;
						rx_done_tick = 1;
					end
					else
						s_next = s_reg + 1;
		endcase
	end
	assign dout = (data_bits == 8)? b_reg : (b_reg >> 1);
endmodule