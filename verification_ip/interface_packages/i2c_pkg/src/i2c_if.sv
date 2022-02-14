import types_pkg::*;
`timescale 1ns / 10ps

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
assign sda = sda_we ? sda_o : 1'bz;

typedef enum {START, STOP, DATA} i2c_bit_type;

// ****************************************************************************             
    task get_link_status(output i2c_bit_type bt, output bit data);
	fork : GET_COND
	    begin : DATA_CASE
		@(posedge scl);
		data = sda;
		bt = DATA;
	    end
	    begin : START_CASE
		forever begin
		    @(negedge sda)
		    if(scl) begin
			bt = START; 
			break;
		    end
		end
	    end
	    begin : STOP_CASE
		forever begin
		   @(posedge sda)
		   if(scl) begin
			bt = STOP;
			break;
		   end
		end
	    end
	join_any
	return;
    endtask

// ****************************************************************************             
    task send_ack();
	@(posedge scl)
	sda_we = 1;
	sda_o = 0;
	@(negedge scl)
	sda_we = 0;
    endtask

// ****************************************************************************             
    task send_bit(bit b);
	@(posedge scl)
	sda_we = 1;
	sda_o = b;
	@(negedge scl)
	sda_we = 0;
    endtask

// ****************************************************************************             
   task wait_for_i2c_transfer (output i2c_op_t op, output bit[I2C_DATA_WIDTH-1:0] write_data[]);
	bit[I2C_ADDR_WIDTH-1:0] addr;
	bit[I2C_DATA_WIDTH-1:0] write_data_queue[$];
	bit[I2C_DATA_WIDTH-1:0] packet;

	i2c_bit_type bt;
	bit one_data_bit;
	
	do get_link_status(bt, one_data_bit); while(bt != START);
	repeat(I2C_ADDR_WIDTH)
	    begin
		get_link_status(bt, one_data_bit);
		addr = {addr, one_data_bit};
	    end

	if(addr != I2C_DEVICE_ADDR)
	    return;

	@(posedge scl)
	op = sda ? READ : WRITE;	

	send_ack();

	if(op == READ)
		return;

	forever begin
	    repeat(I2C_DATA_WIDTH) begin
		get_link_status(bt, one_data_bit);
		if(bt == STOP || bt == START) begin 
		    write_data = write_data_queue;
		    return;
		end
		packet = {packet, one_data_bit};
	    end
	    write_data_queue.push_front(packet);
	    send_ack();
	end
   endtask

// ****************************************************************************              
     task provide_read_data (input bit [I2C_DATA_WIDTH-1:0] read_data []   ,output bit transfer_complete);
	transfer_complete = 0;
	for(int i=0; i<read_data.size(); i++) begin
	    for(int j=I2C_DATA_WIDTH-1; j >= 0; j--) begin
		//send MSB first
		send_bit(read_data[i][j]);
	    end 
	    @(posedge scl);
	    //nack condition detected
	    if(sda == 1) begin
		transfer_complete = 1;
		return;
	    end	   
	end 
     endtask

// ****************************************************************************             
    task monitor( output bit [I2C_ADDR_WIDTH-1:0] addr, output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] data[$]);
	bit[I2C_DATA_WIDTH-1:0] packet;

	i2c_bit_type bt;
	bit one_data_bit;
	
	do get_link_status(bt, one_data_bit); while(bt != START);
	repeat(I2C_ADDR_WIDTH)
	    begin
		get_link_status(bt, one_data_bit);
		addr = {addr, one_data_bit};
	    end

	if(addr != I2C_DEVICE_ADDR)
	    return;

	@(posedge scl);
	op = sda ? READ : WRITE;	

	@(posedge scl);
	@(negedge scl);

	forever begin
	    repeat(I2C_DATA_WIDTH) begin
		get_link_status(bt, one_data_bit);
		if(bt == STOP) begin 
		    return;
		end
		packet = {packet, one_data_bit};
	    end
	    data.push_front(packet);
	    @(posedge scl);
	    @(negedge scl);
	end
    endtask
// ****************************************************************************              

endinterface
