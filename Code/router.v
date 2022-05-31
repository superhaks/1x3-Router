//Router Testbench:
//Authors: Sneha, Hazim, Ramya
//References: 1. http://www.ijvdcs.org/uploads/625143IJVDCS4170-22.pdf

`include "read.v" // READ Control Unit Module
`include "write.v" // WRITE FSM Module
`include "fifo.v" //Asynchronous FIFO module
//`include "fifoo.v" //FIFO 

module router (
input rst, 
input clk1, 
input clk2,
input [7:0] packet_in, 
input packet_valid_i,
output packet_valid_o1,
output packet_valid_o2, 
output packet_valid_o3,
output stop_packet_send,
output [7:0] packet_out1,
output [7:0] packet_out2,
output [7:0] packet_out3);

parameter [7:0] TS1 = 1;
parameter [7:0] TS2 = 2;
parameter [7:0] TS3 = 3;
parameter DATA_WIDTH = 8;
 
reg [7:0] buff_out;
wire fifo1_full, fifo1_wen, fifo1_ren, fifo1_empty;
wire [15:0] fifo1_datain, fifo1_dataout;
wire fifo2_full, fifo2_wen, fifo2_ren, fifo2_empty;
wire [7:0] fifo2_dataout;
 
always@(posedge clk1, posedge rst) begin
	if(rst == 1)
		buff_out <= 0;
	else if(packet_valid_i==1)
		buff_out <= packet_in;
	else
		buff_out <= buff_out;
end

write write_inst ( .rst(rst), .clk(clk1), .buff_out(buff_out), .src1(TS1), .src2(TS2), .src3(TS3), .packet_valid(packet_valid_i), .fifo1_full(fifo1_full), 
.fifo2_wen(fifo2_wen), .stop_packet(stop_packet_send), .fifo1_wen(fifo1_wen), .fifo1_datain(fifo1_datain));

read read_inst ( .rst(rst), .clk(clk2), .packet_valid_o1(packet_valid_o1), .packet_output_1(packet_out1), .packet_valid_o2(packet_valid_o2), .packet_output_2(packet_out2), .packet_valid_o3(packet_valid_o3), .packet_output_3(packet_out3), .fifo1_ren(fifo1_ren),  .fifo1_empty(fifo1_empty), .fifo1_datain(fifo1_dataout), .fifo2_ren(fifo2_ren), .fifo2_empty(fifo2_empty), .fifo2_data(fifo2_dataout)); 

fifo#(.DATA_WIDTH(16), .DEPTH(2)) fifo1_inst(.data_output(fifo1_dataout), .write_inc(fifo1_wen), .full(fifo1_full), .read_inc(fifo1_ren), .empty(fifo1_empty), .data_in(fifo1_datain), .read_clk(clk2), .write_clk(clk1), .reset(rst));

//afifo#(.dsize(16), .asize(2)) fifo1_inst(.rdata(fifo1_dataout), .wren(fifo1_wen), .wfull(fifo1_full), .rden(fifo1_ren), .rempty(fifo1_empty), .wdata(fifo1_datain), .rclk(clk1), .wclk(clk2), .wrstn(rst), .rrstn(rst));

fifo#(.DATA_WIDTH(DATA_WIDTH), .DEPTH(64)) fifo2_inst(.data_output(fifo2_dataout), .write_inc(fifo2_wen), .full(fifo2_full), .read_inc(fifo2_ren), .empty(fifo2_empty), .data_in(buff_out), .read_clk(clk2), .write_clk(clk1), .reset(rst));

//afifo#(.dsize(DATA_WIDTH), .asize(64)) fifo2_inst(.rdata(fifo2_dataout), .wren(fifo2_wen), .wfull(fifo2_full), .rden(fifo2_ren), .rempty(fifo2_empty), .wdata(buff_out), .rclk(clk1), .wclk(clk2), .wrstn(rst), .rrstn(rst));

endmodule
