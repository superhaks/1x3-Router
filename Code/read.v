module read( 
input rst, 
input clk,
input fifo1_empty, 
input fifo2_empty,
input [15:0] fifo1_datain,
input [7:0] fifo2_data, 
output packet_valid_o1, 
output packet_valid_o2,
output packet_valid_o3,
output [7:0] packet_output_1,
output [7:0] packet_output_2, 
output [7:0] packet_output_3, 
output reg fifo1_ren, 
output reg fifo2_ren);

parameter [2:0] WAIT_FIFO1 = 3'b000; 
parameter [2:0] READ_FIFO1 = 3'b001;
parameter [2:0] DECODE_FIFO1 = 3'b010;
parameter [2:0] READ_PACKET_DATA = 3'b011;
parameter [2:0] READ_NEXT_FIFO1 = 3'b100;

wire done;
reg load_packet_count, clear_packet_count, packet_valid, packet_dec_en;
reg [1:0] select_output, select_output_reg;
reg[7:0] temp_packet_data;
reg [2:0] cs, ns;
reg [7:0] packet_counter;

assign done = (packet_counter == 1);
assign packet_output_1 = (select_output_reg == 1)? temp_packet_data : 0;
assign packet_output_2 = (select_output_reg == 2)? temp_packet_data : 0;
assign packet_output_3 = (select_output_reg == 3)? temp_packet_data : 0;
assign packet_valid_o1 = (select_output_reg == 1)? packet_valid : 0;
assign packet_valid_o2 = (select_output_reg == 2)? packet_valid : 0;
assign packet_valid_o3 = (select_output_reg == 3)? packet_valid : 0;

always @ (posedge clk or posedge rst) begin
	if (rst == 1)
		cs <= WAIT_FIFO1;
	else
		cs <= ns;
end
always @ (posedge clk or posedge rst) begin
	if (rst == 1)
		select_output_reg <= 0;
	else
		select_output_reg <= select_output;
end
always@(posedge clk or posedge rst) begin
	if(rst) begin
		packet_counter <= 0;
	end
	else begin
		if(load_packet_count) begin
			packet_counter <= fifo1_datain[15:8];
		end
		else if(clear_packet_count == 1) begin
			packet_counter <=0;
		end
		else if ((packet_counter ==1) || (fifo2_empty == 1) || (packet_dec_en == 0)) begin
			packet_counter <= packet_counter;
		end
		else
			packet_counter <= packet_counter -1;
	end
end
always @(fifo1_empty, fifo2_empty, done, cs, fifo1_datain, packet_counter, 
fifo2_data) begin
	case(cs)
		WAIT_FIFO1 : begin
			fifo1_ren =0;
			load_packet_count =0;
			packet_dec_en =0;
			temp_packet_data =0;
			select_output=0;
			clear_packet_count =1;
			packet_valid = 0;
			fifo2_ren = 0;
			if(fifo1_empty == 0)
				ns <= READ_FIFO1;
			else 
				ns <= WAIT_FIFO1;
		end
		READ_FIFO1: begin
			clear_packet_count =0;
			packet_dec_en = 0;
			packet_valid = 0;
			fifo1_ren = 1;
			ns <= DECODE_FIFO1;
		end
		DECODE_FIFO1 : begin
			fifo1_ren = 0;
			fifo2_ren = 1;
			clear_packet_count =0;
			load_packet_count = 1;
			packet_dec_en =0;
			if(0 <= fifo1_datain[7:0] && fifo1_datain[7:0] <= 127)
				select_output = 1;
			else if( 128 <= fifo1_datain[7:0] && fifo1_datain[7:0] <= 195)
				select_output = 2;
			else if( 196 <= fifo1_datain[7:0] && fifo1_datain[7:0] <=255)
				select_output = 3;
			else
				select_output = 0;
			if(fifo2_empty == 1)
				ns <= DECODE_FIFO1;
			else 
				ns <= READ_PACKET_DATA;
			if(packet_counter >= 1)
				temp_packet_data = fifo2_data;
			else
				temp_packet_data = 0;
		end
		READ_PACKET_DATA : begin
			load_packet_count = 0;
			packet_dec_en = 1;
			packet_valid = 1;
			temp_packet_data = fifo2_data;
			if(packet_counter == 3 & fifo1_empty == 0)
				ns <= READ_NEXT_FIFO1;
			else if(done == 1 && fifo1_empty == 1)
				ns <= WAIT_FIFO1;
			else
				ns <= READ_PACKET_DATA;
		end
		READ_NEXT_FIFO1: begin
			temp_packet_data = fifo2_data;
			if(fifo1_empty == 0) 
				fifo1_ren = 1;
			else
				fifo1_ren = 0;
			if(fifo1_empty == 0)
				ns <= DECODE_FIFO1;
			else
				ns <= WAIT_FIFO1;
			end 
		default : ns <= WAIT_FIFO1;
	endcase
end
endmodule
