class i2cmb_generator extends ncsu_component;

    //shorthands for wishbone register offsets
    parameter CSR=2'b00;
    parameter DPR=2'b01;
    parameter CMDR=2'b10;
    parameter FSMR=2'b11;

    wb_agent wb_master_agent;
    i2c_agent i2c_slave_agent;

    //1 byte to write to wishbone master when requested
    bit[7:0] i2c_current_write_data[1];
    //arbitrary limit on the number of read, write, switch bus sequences allowed in one sim
    // sim time is the only expense of increasing this
    int max_sequences;

    //arbitrary limits
    // Most possible bugs would likely come from multiple devices and busses
    // or untested features, like master arbitration and clock synchronization
    // reliably testing these limits would just take more sim time
    int max_number_bytes_per_write = 5;
    int max_number_bytes_per_read = 5;

    //set from the env_configuration

    //core enable interrupt, sets whether polling mode or interrupt is used
    bit cei;
    bit repeated_start_allowed;
    //array of valid I2C device addresses
    //using addresses not connected is fine,
    //but requires changes to BFM and agent with limited added value
    bit[6:0] valid_i2c_addrs[];
    bit address_invalid_bus_id;

    bit[7:0] valid_i2c_busses[];

    //lock on switching busses when past transaction assumed repeated start
    //must terminate a transaction with a stop, or start a new one on same bus
    bit lock_repeated_start = 1;

    function new(string name = "", ncsu_component_base  parent = null);
        super.new(name, parent);
    endfunction

    virtual task run();
        i2c_slave_agent.switch_bus(4'b0000);
        initializeCore(8'h00);
        wb_master_agent.bus.wait_for_num_clocks(20);

    if ( !$value$plusargs("MAX_SEQ=%d", max_sequences)) begin
      $display("FATAL: +MAX_SEQ plusarg not found on command line");
      $fatal;
    end

        $display("******** TEST FLOW STARTING ********");
        $display("VALID I2C DEVICE IDS ARE %p, max busses", valid_i2c_addrs);
        $display("BUSSES AVAILABLE FOR USE ARE %p", valid_i2c_busses);
        $display("REPEATED START ALLOWED: %b", repeated_start_allowed);
        $display("SWITCHING TO INVALID BUS ALLOWED: %b", address_invalid_bus_id);
        $display("CORE SET TO USE IRQ: %b", cei);

        fork
            begin : WISHBONE_SIM_FLOW
                $display("*------- STARTING WISHBONE_SIM_FLOW -------*");
                repeat(max_sequences) begin
                    if(lock_repeated_start) begin
                        randcase
                            4: readSequence();
                            4: writeSequence();
                            2: switchBusSequence();
                        endcase
                    end
                    else begin
                        randcase
                            5: readSequence();
                            5: writeSequence();
                        endcase
                    end
                end

                #200000;
            end

            begin : I2C_SIM_FLOW
                i2c_transaction i2c_current_trans;
                forever begin
                    //sim flow if data is still available
                    i2c_current_trans = new;
                    i2c_slave_agent.bl_get(i2c_current_trans);
                    if(i2c_current_trans.trans_type == READ) begin
                        i2c_current_trans = new;
                        //reset state variable for tracking transaction progress
                        i2c_slave_agent.driver.transaction_completed = 0;
                        //send data while requested by wishbone master
                        while(!i2c_slave_agent.driver.transaction_completed) begin
                            i2c_current_write_data[0] = $urandom_range(1, 255);
                            i2c_current_trans.data = i2c_current_write_data;
                            i2c_slave_agent.bl_put(i2c_current_trans);
                        end
                    end
                end
            end
        join_any

        //delay to let the scoreboard & predictor check the last transaction
        #500;
        $display("*----------------------------------------------*");
        $display("Tests Finished");
        $display("Warnings %d, Errors %d, Fatals, %d", ncsu_warnings, ncsu_errors, ncsu_fatals);
        if((ncsu_warnings == 0) && (ncsu_errors == 0) && (ncsu_fatals == 0)) $display("ALL TESTS PASSED");
        else $display("TESTS FAILED OR WARNINGS TRIGGERED");
        $display("*----------------------------------------------*");
        $finish;
    endtask

    //decision tree tasks for randomly doing read, writes, switch busses

    local task writeSequence();
        //10 is arbitrary max here, this could be increased for further testing
        int num_bytes_to_write = $urandom_range(1, max_number_bytes_per_write);
        //get random valid I2C address
        bit[7:0] addr = valid_i2c_addrs[$urandom_range(0, valid_i2c_addrs.size() - 1)];
        wb_transaction tmp = new;
        bit[7:0] random_bytes[$];
        $display("I2CMB_GENERATOR STARTING WRITE SEQUENCE, WRITING %d bytes TO ADDRESS 0x%h", num_bytes_to_write, addr);
        tmp.address = CMDR;
        tmp.data = 8'bxxxxx100;
        wb_master_agent.bl_put(tmp);

        clearIRQ();

        tmp = new;
        tmp.address = DPR;
        tmp.data = addr << 1;
        wb_master_agent.bl_put(tmp);

        tmp = new;
        tmp.address = CMDR;
        tmp.data = 8'bxxxxx001;
        wb_master_agent.bl_put(tmp);

        clearIRQ();

        repeat(num_bytes_to_write) begin
            //random byte to send
            tmp = new;
            tmp.randomize();
            tmp.address = DPR;
            wb_master_agent.bl_put(tmp);

            tmp = new;
            tmp.address = CMDR;
            tmp.data = 8'bxxxxx001;
            wb_master_agent.bl_put(tmp);

            clearIRQ();
        end

        if(repeated_start_allowed) begin
            randcase
                5: begin //send stop bit
                    tmp = new;
                    tmp.address = CMDR;
                    tmp.data = 8'bxxxxx101;
                    wb_master_agent.bl_put(tmp);
                    lock_repeated_start = 1;
                    clearIRQ();
                end
                5: lock_repeated_start = 0; //don't send stop bit, and force generator to send another transaction
            endcase
        end else begin
            tmp = new;
            tmp.address = CMDR;
            tmp.data = 8'bxxxxx101;
            wb_master_agent.bl_put(tmp);
            lock_repeated_start = 1;
            clearIRQ();
        end
    endtask

    local task readSequence();
        int num_bytes_to_read = $urandom_range(1, max_number_bytes_per_read);
        //get random valid I2C address
        bit[7:0] addr = valid_i2c_addrs[$urandom_range(0, valid_i2c_addrs.size() - 1)];
        wb_transaction tmp = new;
        $display("I2CMB_GENERATOR STARTING READ SEQUENCE, REQUESTING %d bytes from address 0x%h", num_bytes_to_read, addr);

        tmp.address = CMDR;
        tmp.data = 8'bxxxxx100;
        wb_master_agent.bl_put(tmp);

        clearIRQ();

        tmp = new;
        tmp.address = DPR;
        tmp.data = (addr << 1) + 1'b1;
        wb_master_agent.bl_put(tmp);

        tmp = new;
        tmp.address = CMDR;
        tmp.data = 8'bxxxxx001;
        wb_master_agent.bl_put(tmp);

        clearIRQ();
        repeat (num_bytes_to_read - 1) begin
            tmp = new;
            tmp.address = CMDR;
            tmp.data = 8'bxxxxx010;
            wb_master_agent.bl_put(tmp);

            clearIRQ();

            tmp = new;
            //get byte from DPR
            wb_master_agent.bl_get(tmp);
        end

        //send final read request with a NACK
        tmp = new;
        tmp.address = CMDR;
        tmp.data = 8'bxxxxx011;
        wb_master_agent.bl_put(tmp);

        clearIRQ();

        //get final bit of data
        tmp = new;
        wb_master_agent.bl_get(tmp);

        //same situation as write sequence
        //fine to not send a start bus provided busses aren't switched
        tmp = new;
        tmp.address = CMDR;
        tmp.data = 8'bxxxxx101;
        wb_master_agent.bl_put(tmp);
        lock_repeated_start = 1;
        clearIRQ();
    endtask

    local task switchBusSequence();
        bit[7:0] newBusID;
        wb_transaction tmp = new;
        if(address_invalid_bus_id) newBusID = $urandom_range(0, 30);
        else newBusID = $urandom_range(0, 15);
        $display("I2CMB_GENERATOR SWITCHING SELECTED I2C BUS TO 0x%h", newBusID);
        if(newBusID < 16) i2c_slave_agent.switch_bus(newBusID[3:0]);

        tmp.address = DPR;
        tmp.data = newBusID;
        wb_master_agent.bl_put(tmp);

        tmp = new;
        tmp.address = CMDR;
        tmp.data = 8'bxxxxx110;
        wb_master_agent.bl_put(tmp);

        clearIRQ();
    endtask

    function void set_i2c_agent(i2c_agent agent);
        this.i2c_slave_agent = agent;
    endfunction

    function void set_wb_agent(wb_agent agent);
        this.wb_master_agent = agent;
    endfunction

    local task clearIRQ();
        bit[7:0] tmp;
        //IRQ raised
        if(cei) begin
            wb_master_agent.bus.wait_for_interrupt();
            wb_master_agent.bus.master_read(CMDR, tmp);
        end else begin //IRQ not raised, polling mode
            do begin
                wb_master_agent.bus.master_read(CMDR, tmp);
            end while(tmp[7] == 1'b0);
            return;
        end
    endtask

    //task to reset DUT and set busID
    local task initializeCore(input byte busID);
        wb_transaction tmp = new;
        tmp.address = CSR;
        if(cei) tmp.data = 8'b11xxxxxx;
        else tmp.data = 8'b1xxxxxxx;
        wb_master_agent.bl_put(tmp);

        wb_master_agent.bus.wait_for_reset();
        
        tmp = new;
        tmp.address = DPR;
        tmp.data = busID;
        wb_master_agent.bl_put(tmp);

        tmp = new;
        tmp.address = CMDR;
        tmp.data = 8'bxxxxx110;
        wb_master_agent.bl_put(tmp);

        clearIRQ();
    endtask

endclass