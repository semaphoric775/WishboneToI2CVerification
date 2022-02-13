import types_pkg::*;

interface i2c_if	#(
	int I2C_ADDR_WIDTH=7,
	int I2C_DATA_WIDTH=8,
	bit[I2C_ADDR_WIDTH-1:0] I2C_DEVICE_ADDR
	)
(
    input wire scl,
    triand sda
);

logic sda_o;
bit sda_we = 0;
bit stop_detected=0;
assign sda = sda_we ? sda_o : 1'bz;
always @(posedge sda) 
     if(scl) begin 
	stop_detected = 1;
	@(scl) stop_detected = 0;
     end

// ****************************************************************************             
   task wait_for_i2c_transfer (output i2c_op_t op, output bit[I2C_DATA_WIDTH-1:0] write_data[]);
	bit[I2C_ADDR_WIDTH-1:0] addr;
	bit[I2C_DATA_WIDTH-1:0] write_data_queue[$];
	bit[I2C_DATA_WIDTH-1:0] packet;
	@(negedge sda && scl);
	repeat(I2C_ADDR_WIDTH) begin
	    @(posedge scl) addr = {addr, sda};
	end
	if(addr != I2C_DEVICE_ADDR) begin
	    return;
	end
	@(posedge scl)
	op = sda ? READ : WRITE;

	//pull line low for ack bit
	@(posedge scl)
	sda_we = 1;
	sda_o = 0;
	@(negedge scl)
	sda_we = 0;

	//hand control back to the testbench if a read operation
	if(op == READ) return;
	
	//start capturing transmission data
	forever begin
	    repeat(I2C_DATA_WIDTH) begin
	        @(posedge scl or stop_detected)
		if(stop_detected) begin
		    return;
	    	end
		packet = {packet, sda};	
	    end
	    write_data_queue.push_back(packet);
	    //pull sda low for acknowledge bit
	    //during one data valid window
	    @(posedge scl)
	    sda_we = 1;
	    sda_o = 0;
	    @(negedge scl)
	    sda_we = 0;
	    write_data = write_data_queue;
	end
   endtask

// ****************************************************************************              
task provide_read_data (input bit [I2C_DATA_WIDTH-1:0] read_data []   ,output bit transfer_complete);
    transfer_complete = 0;
    for(int i = 0; i < read_data.size(); i=i+1) begin
	sda_we = 1;
	for(int j = I2C_DATA_WIDTH; j > 0; j=j-1) begin
	    @(posedge scl) sda_o = read_data[i][j];
	end
	sda_we = 0;
	@(posedge scl)
	if(!sda) begin
	    transfer_complete = 1;
	    return;
	end
    end 
    //data exhausted returns transfer not completed
    sda_we = 0;
    return;
endtask

// ****************************************************************************             
    task monitor( output bit [I2C_ADDR_WIDTH-1:0] addr, output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] data[$]);
	bit [I2C_DATA_WIDTH-1:0] packet;
	//block until start condition
	@(negedge sda && scl);
	repeat(I2C_ADDR_WIDTH) begin
	    @(posedge scl) addr = {addr, sda};
	end

	//get operation type
	@(posedge scl)
	op = sda ? READ : WRITE;

	//skip ack bit
	@(posedge scl)

	forever begin
	   repeat(I2C_DATA_WIDTH) begin
		@(posedge scl or stop_detected) packet = {packet, sda};
		if(stop_detected) begin
		    return;
		end
	   end 
	   data.push_front(packet);
	end
    endtask
// ****************************************************************************              

endinterface
