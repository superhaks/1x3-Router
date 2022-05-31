`timescale 1us/1us
`include "router.v"
`include "transmitter.v"
module router_tb;
// parameter DATA_WIDTH_TB = 8;
parameter [7:0] TS1_TB = 8'hA;
parameter [7:0] TS2_TB = 8'hB;
parameter [7:0] TS3_TB = 8'hC;
reg write_clk_tb, read_clk_tb, rst_tb;
wire [7:0] packet_out1_tb, packet_out2_tb, packet_out3_tb;
reg start_packet;
reg [7:0] srcid_tb, dstid_tb;
reg [2:0] data_size_tb, count_tb;
wire [7:0] packet_in_tb;
wire packet_valid_tb, start_of_packet_tb, end_of_packet_tb;
wire stop_packet_tb;
transmitter trans (.clk(write_clk_tb), .rst(rst_tb), .srcid(srcid_tb), .dstid(dstid_tb), .packet_gen_output(packet_in_tb), 
.packet_gen_valid(packet_valid_tb), .packet_starting(start_of_packet_tb), .packet_ending(end_of_packet_tb), .actual_size(data_size_tb), .stop_packet(stop_packet_tb), .start_packet_gen(start_packet));

router #(.TS1(TS1_TB), .TS2(TS2_TB), .TS3(TS3_TB)) 
router_inst ( .rst(rst_tb), .clk1(write_clk_tb), .clk2(read_clk_tb), .packet_valid_i(packet_valid_tb), .packet_in(packet_in_tb), .stop_packet_send(stop_packet_tb), 
.packet_valid_o1(pktvalid_o1_tb), .packet_out1(packet_out1_tb), .packet_valid_o2(pktvalid_o2_tb), .packet_out2(packet_out2_tb), .packet_valid_o3(pktvalid_o3_tb), .packet_out3(packet_out3_tb));

initial begin
	write_clk_tb = 1;
	forever begin
		#2 write_clk_tb = ~write_clk_tb;
	end
end

initial begin
	read_clk_tb =1;
	forever begin
		#5 read_clk_tb = ~read_clk_tb;
	end
end

initial begin
	rst_tb = 1;
	#10;
	rst_tb = 0;
end

always@(posedge write_clk_tb or posedge rst_tb) begin
	if(rst_tb == 1)
		count_tb <=0;
	else if(end_of_packet_tb == 1)
		count_tb <= count_tb+1;
	else
		count_tb <= count_tb;
end

initial begin
	start_packet = 0;
	srcid_tb = 0;
	dstid_tb = 0;
	data_size_tb = 0;
	#15;
	@(posedge write_clk_tb);
	start_packet = 1;
	srcid_tb = TS1_TB;
	dstid_tb = 8'hA;
	data_size_tb = 5;
	@(posedge write_clk_tb);
	@(end_of_packet_tb);
	@(posedge write_clk_tb);
	srcid_tb = TS2_TB;
	dstid_tb = 8'h82;
	data_size_tb = 7;
	@(posedge write_clk_tb);
	@(end_of_packet_tb);
	@(posedge write_clk_tb);
	srcid_tb = TS2_TB;
	dstid_tb = 8'hFF;
	data_size_tb = 3;
	@(posedge write_clk_tb);
	@(end_of_packet_tb);
	@(posedge write_clk_tb);
	srcid_tb = TS3_TB;
	//dstid_tb = 8'h98;
	dstid_tb = 8'h256;
	data_size_tb = 6;
	@(posedge write_clk_tb);
	@(end_of_packet_tb);
	@(posedge write_clk_tb);
	srcid_tb = 8'hF;
	dstid_tb = 8'hB;
	data_size_tb = 4;
	@(posedge write_clk_tb);
	@(end_of_packet_tb);
end
initial $vcdpluson;
initial begin
	forever begin
		@(count_tb);
	if(count_tb == 5) begin 
		start_packet = 0;
		wait(!(pktvalid_o1_tb || pktvalid_o2_tb || pktvalid_o3_tb) );
		@(posedge write_clk_tb);
		@(posedge write_clk_tb);
		@(posedge write_clk_tb);
		@(posedge write_clk_tb);
		$finish; 
	end
	end
end
endmodule
