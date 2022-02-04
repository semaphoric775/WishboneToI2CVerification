interface i2c_if	#(
	int I2C_ADDR_WIDTH=7,
	int I2C_DATA_WIDTH=8
	)
(
    input wire scl,
    triand sda
);

typedef enum bit {WRITE, READ} i2c_op_t;

// ****************************************************************************             
   task wait_for_i2c_transfer (output i2c_op_t op, output bit[I2C_DATA_WIDTH-1:0] write_data[]);
	bit[I2C_ADDR_WIDTH-1:0] addr;
	$display("Wait task for started");
	@(!sda && scl);
	$display("Start condition detected");
	repeat(I2C_ADDR_WIDTH) begin
	    //@(posedge scl) addr = {addr, sda} << 1;
	    $display("clocking address bit");
	end
	$display("Read address 0x%x", addr);
	$display("Exiting wait task");
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
