module fifo #(parameter D_WIDTH=8, ADDR_WIDTH=4)
(
	input clk,reset_n,
	input rd,wr,
	input [D_WIDTH-1:0] wr_data,
	output reg empty,full,
	output [D_WIDTH-1:0] rd_data
);
reg [D_WIDTH-1:0] mem[2**ADDR_WIDTH-1:0];
reg [ADDR_WIDTH-1:0] wr_ptr,rd_ptr;
wire [ADDR_WIDTH-1:0] wr_ptr_succ,rd_ptr_succ;
wire wr_en;

assign rd_data = mem[rd_ptr];
assign wr_en = wr && !full;
assign wr_ptr_succ = wr_ptr + 1;
assign rd_ptr_succ = rd_ptr + 1;

always @(posedge clk or negedge reset_n)
begin
	
	if(~reset_n)
		mem[wr_ptr] <= 0;
	else if(wr_en)
		mem[wr_ptr] <= wr_data;

	if(~reset_n)
	begin
		wr_ptr <= 0;
		rd_ptr<=0;
		full <= 0;
		empty<=0;
	end
	else
		case({wr,rd})
			2'b01:
			begin
				if(~empty)
				begin
					rd_ptr <= rd_ptr_succ;
					full <= 0;
					if(rd_ptr_succ == wr_ptr)
						empty <= 1;
				end
			end
			2'b10:
			begin
				if(!full)
				begin
					wr_ptr <= wr_ptr_succ;
					empty <= 0;
					if(wr_ptr_succ == rd_ptr)
						full <= 1;
				end
			end
			2'b11:
			begin
				wr_ptr <= wr_ptr_succ;
				rd_ptr <= rd_ptr_succ;
			end
		endcase
end

endmodule