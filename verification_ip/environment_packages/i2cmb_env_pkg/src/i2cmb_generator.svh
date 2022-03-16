class i2cmb_generator extends ncsu_object;
    `ncsu_register_object(i2cmb_generator)

    parameter CSR=2'b00;
    parameter DPR=2'b01;
    parameter CMDR=2'b10;
    parameter FSMR=2'b11;
    wb_agent wb_master_agent;
    i2c_agent i2c_slave_agent;

    bit[7:0] tmp;
    bit[7:0] addr = 8'h22;
    bit useRepeatedStart = 1'b0;
    wb_transaction wb_startup_seq[3];
    wb_transaction seq_writes[$];
    wb_transaction wb_read_requests[$];
    bit[7:0] seq_write_data[];

    function new(string name = "");
        super.new(name);
    endfunction

    virtual task run();
        fork
        begin : WISHBONE_SIM_FLOW
        wb_transaction wb_data_from_i2c;
        seq_write_data = new[32];
        foreach(wb_startup_seq[i]) begin
            wb_startup_seq[i] = new;
        end
        for(int i = 0; i < 32; i++) begin
            seq_write_data[i] = i;
        end

        //uncomment to enable write test flow
        //genWriteTransactions(seq_writes, addr, seq_write_data, useRepeatedStart);
        genReadTransactionPreamble(wb_read_requests, addr, 1'b1);

        wb_master_agent.bus.wait_for_reset();
        /*          WISHBONE STARTUP SEQUENCE       */
        //core enable
        wb_startup_seq[0].address = CSR;
        wb_startup_seq[0].data = 8'b11xxxxxx;
        wb_master_agent.bl_put(wb_startup_seq[0]);

        wb_master_agent.bus.wait_for_reset();
        //setting bus ID
        wb_startup_seq[1].address = DPR;
        wb_startup_seq[1].data = 8'h05;
        wb_master_agent.bl_put(wb_startup_seq[1]);

        wb_startup_seq[2].address = CMDR;
        wb_startup_seq[2].data = 8'bxxxxx110;
        wb_master_agent.bl_put(wb_startup_seq[2]);

        wb_master_agent.bus.wait_for_interrupt();
        wb_master_agent.bus.master_read(CMDR, tmp);
        
        // Test Single Write
        foreach(seq_writes[i]) begin
            //null in wb_transaction sequence is used to denote that the IRQ flag must be cleared
            if(seq_writes[i] == null) clearIRQ();
            else wb_master_agent.bl_put(seq_writes[i]);
        end

        foreach(wb_read_requests[i]) begin
            //null in wb_transaction sequence is used to denote that the IRQ flag must be cleared
            if(wb_read_requests[i] == null) clearIRQ();
            else wb_master_agent.bl_put(wb_read_requests[i]);
        end;
        wb_master_agent.bl_get(wb_data_from_i2c);
        end

        begin : I2C_SIM_FLOW
            //i2c_transaction t;
            //i2c_slave_agent.bl_put(t);
            i2c_transaction i2c_to_wb_data = new;
            bit[7:0] i2c_write_data[] = new[1];
            i2c_write_data[0] = 8'h61;
            i2c_to_wb_data.data = i2c_write_data;
            i2c_slave_agent.bl_put(i2c_to_wb_data);
        end
        join
    endtask

    function void set_i2c_agent(i2c_agent agent);
        this.i2c_slave_agent = agent;
    endfunction

    function void set_wb_agent(wb_agent agent);
        this.wb_master_agent = agent;
    endfunction

    local task clearIRQ();
        bit[7:0] tmp;
        wb_master_agent.bus.wait_for_interrupt();
        wb_master_agent.bus.master_read(CMDR, tmp);
    endtask

    // make this generic, not hardcoded, later
    local function void genReadTransactionPreamble(
        ref wb_transaction trans[$],
        input bit[7:0] addr,
        input bit sendNack
    );
    wb_transaction tmp = new;

    tmp.address = CMDR;
    tmp.data = 8'bxxxxx100;
    trans.push_back(tmp);

    tmp = null;
    trans.push_back(tmp);

    tmp = new;
    tmp.address = DPR;
    tmp.data = (addr << 1) + 1'b1;
    trans.push_back(tmp);

    tmp = new;
    tmp.address = CMDR;
    tmp.data = 8'bxxxxx001;
    trans.push_back(tmp);

    tmp = null;
    trans.push_back(tmp);

    tmp = new;
    tmp.address = CMDR;
    if(sendNack) tmp.data = 8'bxxxxx011;
    else tmp.data = 8'bxxxxx010;
    trans.push_back(tmp);

    tmp = null;
    trans.push_back(tmp);
    endfunction

    // make this generic, not hardcoded, later
    local function void genWriteTransactions(
        ref wb_transaction trans[$],
        input bit[7:0] addr,
        input bit[7:0] data[],
        input bit useRepeatedStart);
        
        wb_transaction tmp = new;
        //start transaction
        tmp.address = CMDR;
        tmp.data = 8'bxxxxx100;
        trans.push_back(tmp);
        //wait after this first transaction in the run task
        tmp = null;
        trans.push_back(tmp);

        //I2C address transaction
        tmp = new;
        tmp.address = DPR;
        tmp.data = addr << 1;
        trans.push_back(tmp);

        tmp = new;
        tmp.address = CMDR;
        tmp.data = 8'bxxxxx001;
        trans.push_back(tmp);
        //wait after this transaction in the run task
        tmp = null;
        trans.push_back(tmp);
        
        for(int i = 0; i < data.size(); i++) begin
            tmp = new;
            tmp.address = DPR;
            tmp.data = data[i];
            trans.push_back(tmp);
            
            tmp = new;
            tmp.address = CMDR;
            tmp.data = 8'bxxxxx001;
            trans.push_back(tmp);
            //wait after this transaction
            tmp = null;
            trans.push_back(null);
        end

        if(!useRepeatedStart) begin
            tmp = new;
            tmp.address = CMDR;
            tmp.data = 8'bxxxxx101;
            trans.push_back(tmp);
            //wait after this transaction
            tmp = null;
            trans.push_back(null);
        end
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