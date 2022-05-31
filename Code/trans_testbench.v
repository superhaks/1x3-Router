//Transmitter Testbench:
//Authors: Sneha, Hazim, Ramya
//References: 1. http://www.ijvdcs.org/uploads/625143IJVDCS4170-22.pdf

`timescale 1us/1us
`include "transmitter.v"
module packet_gen_tb;
parameter TS1_TB = 5;
parameter TS2_TB = 6;
parameter TS3_TB = 7;
reg wr_clk_tb, rd_clk_tb, rst_tb, start_pkt, stop_packet_tb;
reg [7:0] srcid_tb, dstid_tb;
reg [2:0] num_data_tb, count_tb;
wire [7:0] packet_in;
wire packet_valid, sop_tb, eop_tb;
transmitter DUT (.clk(wr_clk_tb), .rst(rst_tb), .srcid(srcid_tb), .dstid(dstid_tb), .packet_gen_output(packet_in),
.packet_gen_valid(packet_valid), .packet_starting(sop_tb), .packet_ending(eop_tb), .actual_size(num_data_tb),
.stop_packet(stop_packet_tb), .start_packet_gen(start_pkt));
initial begin
	wr_clk_tb = 1;
	forever begin
		#2 wr_clk_tb = ~wr_clk_tb;
	end
end
initial begin
	rst_tb = 1;
	#10;
	rst_tb = 0;
end
always@(posedge wr_clk_tb or posedge rst_tb) begin
	if(rst_tb == 1)
		count_tb <=0;
	else if(eop_tb == 1)
		count_tb <= count_tb+1;
	else
		count_tb <= count_tb;
end
initial begin
	#20
	//randsel = $urandom_range(1, 4);
	stop_packet_tb =0;
	start_pkt = 0;
	srcid_tb = 0;
	dstid_tb = 0;
	num_data_tb = 0;
	#4;
	start_pkt = 1;
	srcid_tb = TS1_TB;
	dstid_tb = 8'hF8;
	num_data_tb = 4;
	@(eop_tb);
	@(posedge wr_clk_tb);
	stop_packet_tb = 1;
	@(posedge wr_clk_tb);
	@(posedge wr_clk_tb);
	@(posedge wr_clk_tb);
	stop_packet_tb = 0;
	srcid_tb = TS2_TB;
	dstid_tb = 8'h8;
	num_data_tb = 5;
	@(eop_tb);
	@(posedge wr_clk_tb);
	srcid_tb = TS2_TB;
	dstid_tb = 8'h45;
	num_data_tb = 7;
	@(posedge wr_clk_tb);
	@(eop_tb);
	// @(posedge wr_clk_tb);
	srcid_tb = TS3_TB;
	dstid_tb = 8'hF;
	num_data_tb = 4;
	@(eop_tb);
end
initial $vcdpluson;
initial begin
	forever begin
		@(count_tb);
		if(count_tb == 4)
		$finish;
	end
end
endmodule