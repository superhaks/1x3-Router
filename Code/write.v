//Transmitter Testbench:
//Authors: Sneha, Hazim, Ramya
//References: 1. http://www.ijvdcs.org/uploads/625143IJVDCS4170-22.pdf

module write( 
input rst, 
input clk, 
input [7:0] buff_out, 
input [7:0] src1, 
input [7:0] src2, 
input [7:0] src3, 
input packet_valid, 
input fifo1_full,
output reg fifo2_wen, 
output reg stop_packet, 
output reg fifo1_wen, 
output reg [15:0] fifo1_datain);

parameter [2:0] S1_IDLE = 3'b000; 
parameter [2:0] S2_VALIDITY_CHECK = 3'b001;
parameter [2:0] S3_SOURCE_VALIDITY_CHECK = 3'b010;
parameter [2:0] S4_DESTINATION = 3'b011;
parameter [2:0] S5_DATA_SIZE = 3'b100;
parameter [2:0] S6_DATA = 3'b101;
parameter [2:0] S7_CRC = 3'b110;

wire done;
reg load_data_count, clear_data_count, fifo1_valid;
reg [2:0] cs, ns, data_counter;
reg [15:0] temp_fifo1;

assign done = (data_counter == 1)&& (cs == S6_DATA);

always @ (posedge clk or posedge rst) begin
	if (rst == 1)
		cs <= S1_IDLE;
	else
		cs <= ns;
end
always@(posedge clk or posedge rst) begin
	if(rst) begin
		data_counter <= 0;
	end
	else begin
		if(load_data_count) begin
			data_counter <= buff_out;
		end
		else if(clear_data_count == 1) begin
			data_counter <=0;
		end
		else if (data_counter ==1) begin
			data_counter <= data_counter;
		end
		else begin
			data_counter <= data_counter -1;
		end
	end
end
always @(packet_valid, src1, src2, src3, fifo1_full, done, cs) begin
	case(cs)
		S1_IDLE : begin
			fifo1_wen =0;
			stop_packet =0;
			fifo2_wen =0;
			fifo1_valid = 0;
			load_data_count =0;
			temp_fifo1 =0; 
			fifo1_datain=0;
			clear_data_count =0;
			if (rst == 0) 
				ns <= S1_IDLE;
			else 
				ns <= S2_VALIDITY_CHECK;
		end
		S2_VALIDITY_CHECK: begin
			clear_data_count = 0;
			fifo2_wen = 0;
			if(packet_valid == 1 && fifo1_full == 0) 
				ns <= S3_SOURCE_VALIDITY_CHECK;
			else 
				ns <= S2_VALIDITY_CHECK;
			if(fifo1_full == 1)
				stop_packet = 1;
			else
				stop_packet = 0;
		end
		S3_SOURCE_VALIDITY_CHECK : begin
			clear_data_count = 0;
			if((buff_out == src1 || buff_out == src2 || buff_out == src3) &&
			(packet_valid == 1 && fifo1_full == 0)) begin
				fifo1_valid = 1;
				fifo2_wen = 1;
			end
			else 
				fifo2_wen = 0;
			if(fifo1_full == 1)
				stop_packet = 1;
			else
				stop_packet = 0;
			if(packet_valid == 1 && fifo1_full == 0) 
				ns <= S4_DESTINATION;
			else
				ns <= S3_SOURCE_VALIDITY_CHECK;
		end
		S4_DESTINATION : begin 
			temp_fifo1[7:0] = buff_out;
			ns <= S5_DATA_SIZE;
		end
		S5_DATA_SIZE : begin
			temp_fifo1[15:8] = buff_out + 4;
			fifo1_datain = temp_fifo1;
			load_data_count = 1;
			if(fifo1_valid == 1)
			fifo1_wen = 1;
			ns <= S6_DATA;
		end
		S6_DATA : begin
			fifo1_wen =0;
			fifo1_valid =0;
			load_data_count = 0;
			if(done == 1)
				ns <= S7_CRC;
			else
				ns <= S6_DATA;
		end
		S7_CRC : begin
			clear_data_count = 1;
			if(fifo1_full == 1)
				stop_packet = 1;
			else
				stop_packet = 0;
			if(packet_valid ==1)
				ns <= S3_SOURCE_VALIDITY_CHECK;
			else
				ns <= S2_VALIDITY_CHECK;
		end
		default : ns <= S1_IDLE;
	endcase
end
endmodule
