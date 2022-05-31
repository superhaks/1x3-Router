//Transmitter Source Code:
//Authors: Sneha, Hazim, Ramya
//References: 1. http://www.ijvdcs.org/uploads/625143IJVDCS4170-22.pdf
module transmitter (
input clk, 
input rst, 
input [7:0] srcid, 
input [7:0] dstid, 
output [7:0] transmitter_output, 
output reg transmitter_valid,
output reg packet_starting, 
output reg packet_ending, 
input [2:0] actual_size, 
input stop_packet, 
input start_packet_gen);

parameter [2:0] S1_IDLE = 3'b000;
parameter [2:0] S2_SRCID_GEN = 3'b001;
parameter [2:0] S3_DSTID_GEN = 3'b010;
parameter [2:0] S4_SIZE_GEN = 3'b011;
parameter [2:0] S5_DATA_GEN = 3'b100;
parameter [2:0] S6_CRC_GEN = 3'b101;

//input [7:0] srcid, dstid;	
//input clk, rst, stop_packet, start_packet_gen;
//input [2:0] actual_size;
//output [7:0] transmitter_output;
//output reg transmitter_valid, packet_starting, packet_ending;
reg [7:0] temp_packet, crc_gen, data;
reg [2:0] cs, ns;
reg gen_crc, clr_crc, load_data_count, clr_data_cnt;
reg [2:0] data_counter;
wire count_done;

assign transmitter_output = temp_packet;
assign count_done = (data_counter == 1)&& (cs == S5_DATA_GEN);

always@(posedge clk or posedge rst) begin
	if(rst)
		cs <= S1_IDLE;
	else
		cs <= ns;
end
always@(posedge clk or posedge rst) begin
	if(rst) begin
		data_counter <= 0;
		data <= 0;
	end

	else begin
		if(load_data_count) begin
			data_counter <= actual_size;
			data <=1;
		end
		else if(clr_data_cnt == 1) begin
			data_counter <=0;
			data <= 1;
		end
		else if (data_counter ==1) begin
			data_counter <= data_counter;
			data <= data;
		end
		else begin
			data_counter <= data_counter -1;
			data <= data+1;
		end
	end
end
always@(stop_packet, cs, srcid, dstid, start_packet_gen, data, actual_size) begin
	case(cs)
		S1_IDLE : begin
			transmitter_valid = 0;
			packet_ending = 0;
			packet_starting = 0;
			temp_packet = 0;
			clr_data_cnt = 0;
			load_data_count = 0;
			clr_crc = 0;
			if( start_packet_gen == 0 || stop_packet == 1)
				ns <= S1_IDLE;
			else
				ns <= S2_SRCID_GEN;
		end
		S2_SRCID_GEN : begin
			packet_ending =0;
			clr_crc = 1;
			temp_packet = srcid;
			clr_data_cnt = 1;
			if(start_packet_gen ==0)
				ns <= S1_IDLE;
			else if(stop_packet == 1) begin
				ns <= S2_SRCID_GEN;
				transmitter_valid = 0;
			end
			else begin
				ns <= S3_DSTID_GEN;
				transmitter_valid = 1;
				packet_starting = 1;
			end
		end
		S3_DSTID_GEN : begin
			clr_crc = 0;
			clr_data_cnt = 0;
			temp_packet = dstid;
			packet_starting = 0;
			//if(start_packet_gen ==1)
			//ns <= S3_DSTID_GEN;
			//else
			ns <= S4_SIZE_GEN;
		end

		S4_SIZE_GEN: begin
			temp_packet = actual_size;
			load_data_count = 1;
			ns <= S5_DATA_GEN;
		end
		S5_DATA_GEN: begin
			temp_packet = data;
			gen_crc = 1;
			load_data_count = 0;
			if(count_done ==1) begin
				ns <= S6_CRC_GEN;
			end
			else
				ns <= S5_DATA_GEN;
		end
		S6_CRC_GEN: begin
			packet_ending = 1;
			gen_crc = 0;
			temp_packet = crc_gen;
			if(start_packet_gen == 1)
				ns <= S2_SRCID_GEN;
			else
				ns <= S1_IDLE;
		end
		default: ns <= S1_IDLE;
	endcase
end
// CRC generator
always@(posedge clk or posedge rst) begin
	if(rst)
		crc_gen <= 0;
	else if(clr_crc == 1)
		crc_gen <= 0;
	else if(gen_crc)
		crc_gen <= temp_packet ^ crc_gen;
	else
		crc_gen <= crc_gen;
end
endmodule