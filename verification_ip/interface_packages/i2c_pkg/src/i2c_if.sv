interface i2c_if	#(
	int I2C_ADDR_WIDTH=7,
	int I2C_DATA_WIDTH=8,
	bit[I2C_ADDR_WIDTH-1:0] I2C_DEVICE_ADDR
	)
(
    input wire scl,
    triand sda
);

typedef enum bit {WRITE=0, READ} i2c_op_t;
logic sda_o;
bit sda_we = 0;
bit stop_detected=0;
assign sda = sda_we ? sda_o : 1'bz;
always @(posedge sda) if(scl) stop_detected = 1;

// ****************************************************************************             
   task wait_for_i2c_transfer (output i2c_op_t op, output bit[I2C_DATA_WIDTH-1:0] write_data[]);
	bit[I2C_ADDR_WIDTH-1:0] addr;
	bit[I2C_DATA_WIDTH-1:0] write_data_queue[$];
	bit[I2C_DATA_WIDTH-1:0] packet;
	@(negedge sda && scl);
	$display("Start condition detected");
	repeat(I2C_ADDR_WIDTH) begin
	    @(posedge scl) addr = {addr, sda};
	end
	if(addr != I2C_DEVICE_ADDR) begin
	    return;
	end
	@(posedge scl)
	op = sda ? READ : WRITE;

	@(posedge scl)
	sda_we = 1;
	sda_o = 0;
	@(negedge scl)
	sda_we = 0;

	//hand control back to the testbench if a read operation
	if(op == READ) return;
	
	//clear stop bit flag
	stop_detected = 0;
	//start capturing transmission data
	forever begin
	    repeat(I2C_DATA_WIDTH) begin
	        @(posedge scl or stop_detected)
		if(stop_detected) begin
		    stop_detected = 0;
		    return;
	    	end
		packet = {packet, sda};	
	    end
	    write_data_queue.push_back(packet);
	    $display("Read packet 0x%h", packet);
	    //pull sda low for acknowledge bit
	    @(posedge scl)
	    sda_we = 1;
	    sda_o = 0;
	    @(negedge scl)
	    sda_we = 0;
	    write_data = write_data_queue;
	end
   endtask

// ****************************************************************************              
// ****************************************************************************             
    task provide_read_data (input bit [I2C_DATA_WIDTH-1:0] read_data[], output bit transfer_complete);

    endtask

// ****************************************************************************             
    task monitor( output bit [I2C_ADDR_WIDTH-1:0] addr, output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] data[]);

    endtask
// ****************************************************************************              

endinterface
