module fifo( data_output, write_inc, full, read_inc, empty, data_in, read_clk, 
write_clk, reset);

parameter DATA_WIDTH = 8;
parameter DEPTH = 8; 

output reg [DATA_WIDTH - 1 : 0] data_output;
input [DATA_WIDTH - 1 : 0] data_in;
output full;
output empty;
input write_inc, read_inc;
input read_clk, write_clk;
input reset;
reg [$clog2(DEPTH) : 0] read_ptr, read_sync_1, read_sync_2;
reg [$clog2(DEPTH) : 0] write_ptr, wr_sync_1, wr_sync_2;
reg [DATA_WIDTH-1 : 0] mem [DEPTH-1 : 0];
wire [$clog2(DEPTH) : 0] read_ptr_b, read_ptr_g;
wire [$clog2(DEPTH) : 0] write_ptr_b, write_ptr_g;
wire [$clog2(DEPTH)-1 : 0] read_mem_ptr;
wire [$clog2(DEPTH)-1 : 0] write_mem_ptr;
assign write_mem_ptr = write_ptr[$clog2(DEPTH)-1:0];
assign read_mem_ptr = read_ptr[$clog2(DEPTH)-1:0];
//Write pointer increment and write logic//
always @(posedge write_clk or posedge reset) begin
	if (reset) 
		write_ptr <= 0;
	else if (write_inc == 1 && full == 0) begin 
		write_ptr <= write_ptr + 1;
		mem[write_mem_ptr] <= data_in;
	end
	else
		write_ptr <= write_ptr;
end
//Read Pointer Increment
always @(posedge read_clk or posedge reset) begin
	if (reset) begin
		read_ptr <= 0;
	end
	else if (read_inc == 1 && empty == 0) begin 
		read_ptr <= read_ptr + 1;
		data_output <= mem[read_mem_ptr];
	end
	else
		read_ptr <= read_ptr;
end
// Synchronizing Grey code converted Read Pointer to Write clock Domain
always @(posedge write_clk or posedge reset) begin
	if(reset == 1) begin
		read_sync_1 <= 0;
		read_sync_2 <= 0;
	end
	else begin
		read_sync_1 <= read_ptr_g;
		read_sync_2 <= read_sync_1;
	end
end
//Synchronizig Grey code converted Write pointer to Read clock domain
always @(posedge read_clk or posedge reset) begin
	if(reset == 1) begin
		wr_sync_1 <= 0;
		wr_sync_2 <= 0;
	end
	else begin
		wr_sync_1 <= write_ptr_g;
		wr_sync_2 <= wr_sync_1;
	end
end
// Memory Data Read
//assign data_output = mem[read_mem_ptr];
//return Full
assign full = returnFull(read_ptr_b, write_ptr);
// return Empty
assign empty = returnEmpty(read_ptr, write_ptr_b);
// Write pointer Binary2Gray
assign write_ptr_g = write_ptr ^ (write_ptr>>1);
//Read Pointer Binary2Gray
assign read_ptr_g = read_ptr ^ (read_ptr>>1);
// Write Pointer Gray2Binary
genvar i;
generate
	assign write_ptr_b[$clog2(DEPTH)] = wr_sync_2[$clog2(DEPTH)];
	for(i=$clog2(DEPTH)-1; i>=0; i=i-1) begin : WrGtoB
		assign write_ptr_b[i] = wr_sync_2[i] ^ write_ptr_b[i+1];
	end
endgenerate
//Read Pointer Gray2Binary
genvar j;
generate 
	assign read_ptr_b[$clog2(DEPTH)] = read_sync_2[$clog2(DEPTH)];
	for(j=$clog2(DEPTH)-1; j>=0; j=j-1) begin : RdGtoB
		assign read_ptr_b[j] = read_sync_2[j] ^ read_ptr_b[j+1];
	end
endgenerate
// Function to calculate Empty Condition
function returnEmpty(input [$clog2(DEPTH):0] rdptr, input [$clog2(DEPTH):0] wrptr);
begin
	if(rdptr == wrptr)
		returnEmpty = 1'b1;
	else
		returnEmpty = 1'b0;
	end
endfunction
// Function to calculate Full condition
function returnFull(input [$clog2(DEPTH):0]rdptr, input [$clog2(DEPTH):0]wrptr);
begin
	if(wrptr[$clog2(DEPTH)-1:0] == rdptr[$clog2(DEPTH)-1:0] &&
	write_ptr[$clog2(DEPTH)] != read_ptr[$clog2(DEPTH)])
		returnFull = 1;
	else
		returnFull = 0;
end
endfunction
endmodule
