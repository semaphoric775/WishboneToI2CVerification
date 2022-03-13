class i2cmb_generator extends ncsu_object;
    `ncsu_register_object(i2cmb_generator)

    wb_agent wb_master_agent;
    i2c_agent i2c_slave_agent;

    function new(string name = "");
        super.new(name);
    endfunction

    virtual task run();
        //TODO
    endtask

    function void set_i2c_agent(i2c_agent agent);
        this.i2c_slave_agent = agent;
    endfunction

    function void set_wb_agent(wb_agent agent);
        this.wb_master_agent = agent;
    endfunction

endclass

/* testflow from top.sv

i2c_op_t i2c_if_op;
bit[I2C_DATA_WIDTH-1:0] i2c_if_write_data[];
bit i2c_transfer_complete;
bit [I2C_DATA_WIDTH-1:0] i2c_read_data [] = new[32];

//I2C Read/Writes
initial
    begin : TEST_FLOW_I2C
    //TEST 1: 32 incrementing values from wishbone to I2C
    i2c_bus.wait_for_i2c_transfer(i2c_if_op, i2c_if_write_data);

    //TEST 2: 32 decrementing values read from I2C

    //fill byte array transmitted to wishbone
    for(int i = 0; i < 32; i++) 
        i2c_read_data[i] = 100+i;

    // Wait for read operation
    i2c_bus.wait_for_i2c_transfer(i2c_if_op, i2c_if_write_data);
    assert(i2c_if_op == READ) else $error("Expected read request from wishbone master");
    //send data back
    i2c_bus.provide_read_data(i2c_read_data, i2c_transfer_complete);

    //TEST 3: alternating read and writes
    for(int i = 0; i < 128; i++) begin
        if(i%2 == 0) begin //reading from wishbone
            i2c_bus.wait_for_i2c_transfer(i2c_if_op, i2c_if_write_data);
        end else begin // sending data back to wishbone
            i2c_bus.wait_for_i2c_transfer(i2c_if_op, i2c_if_write_data);
            i2c_read_data[0] = 63 - ((i-1)/2);
            i2c_bus.provide_read_data(i2c_read_data, i2c_transfer_complete);
        end
    end
    end

byte to_write;
byte wb_out;

//wishbone testflow
initial
    begin : TEST_FLOW
    #1151
    //wb_bus.master_write(adr, data);
    
    //enable core with interrupts
    wb_bus.master_write(CSR, 8'b11xxxxxx);

    //set bus ID    
    wb_bus.master_write(DPR, 8'h05);
    wb_bus.master_write(CMDR, 8'bxxxxx110);

    @(!irq) wb_bus.master_read(CMDR, wb_out);

   
    //TEST 1: transmit 0 to 31 to i2c bus in one transmission
    wb_bus.master_write(CMDR, 8'bxxxxx100);
    @(!irq) wb_bus.master_read(CMDR, wb_out);
    // (slave address left shifted 1) + 0 for write
    // see OpenCores I2C spec example 3
    wb_bus.master_write(DPR, 8'h22 << 1);
    //write command
    wb_bus.master_write(CMDR, 8'bxxxxx001);
    @(!irq) wb_bus.master_read(CMDR, wb_out);
    for(int i = 0; i < 32; i++) begin
        wb_bus.master_write(DPR, i);
        wb_bus.master_write(CMDR, 8'bxxxxx001);
        $display("WISHBONE MONITOR  Sending 0x%h to I2C interface", i[7:0]);
        @(!irq) wb_bus.master_read(CMDR, wb_out);
    end
    wb_bus.master_write(CMDR, 8'bxxxx101);

    wb_bus.master_write(DPR, 8'h05);
    wb_bus.master_write(CMDR, 8'bxxxxx110);
    @(!irq) wb_bus.master_read(CMDR, wb_out);

    //TEST 2: Read 64 to 127 from I2C bus
    wb_bus.master_write(CMDR, 8'bxxxxx100);
    @(!irq) wb_bus.master_read(CMDR, wb_out);
    // (slave address left shifted 1) + 1 for write
    // see OpenCores I2C spec example 3
    wb_bus.master_write(DPR, (8'h22 << 1)+1'b1);
    //write command
    wb_bus.master_write(CMDR, 8'bxxxxx001);
    @(!irq) wb_bus.master_read(CMDR, wb_out);
    // generate read requests with ACK 31 times
    for(int i = 0; i < 31; i++) begin
        wb_bus.master_write(CMDR, 8'bxxxxx010);
        @(!irq) wb_bus.master_read(CMDR, wb_out);
        wb_bus.master_read(DPR, wb_out);
        $display("WISHBONE MONITOR  Recieved 0x%h from I2C interface", wb_out);
    end
    // generate final read request with NACK
    wb_bus.master_write(CMDR, 8'bxxxxx011);
    @(!irq) wb_bus.master_read(CMDR, wb_out);
    wb_bus.master_read(DPR, wb_out);
    $display("WISHBONE MONITOR  Recieved 0x%h from I2C interface", wb_out);

    // generate stop and clear IRQ
    wb_bus.master_write(CMDR, 8'bxxxx101);
    @(!irq) wb_bus.master_read(CMDR, wb_out);

    //TEST 3: alternating incrementing and decrementing reads and writes
    for(int i = 0; i < 128; i++) begin
        wb_bus.master_write(CMDR, 8'bxxxxx100);
        @(!irq) wb_bus.master_read(CMDR, wb_out);
        // (slave address left shifted 1) + 1 for write
        // see OpenCores I2C spec example 3
        //alternate between reading and writing
        wb_bus.master_write(DPR, (8'h22 << 1)+(i%2));
        //write operation
        wb_bus.master_write(CMDR, 8'bxxxxx001);
        @(!irq) wb_bus.master_read(CMDR, wb_out);
        if(i%2 == 0) begin // write case
            to_write = 64+(i/2);
            wb_bus.master_write(DPR, to_write);
            wb_bus.master_write(CMDR, 8'bxxxxx001);
            $display("WISHBONE MONITOR  Writing 0x%h to I2C interface", to_write);
            @(!irq) wb_bus.master_read(CMDR, wb_out);
            wb_bus.master_write(CMDR, 8'bxxxx101);
            @(!irq) wb_bus.master_read(CMDR, wb_out);
        end else begin
            wb_bus.master_write(CMDR, 8'bxxxxx011);
            @(!irq) wb_bus.master_read(CMDR, wb_out);
            wb_bus.master_read(DPR, wb_out);
            $display("WISHBONE MONITOR  Received 0x%h from I2C interface", wb_out);
            wb_bus.master_write(CMDR, 8'bxxxx101);
            @(!irq) wb_bus.master_read(CMDR, wb_out);
        end
    end
    end
    */