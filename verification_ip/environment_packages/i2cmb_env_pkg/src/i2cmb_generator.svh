class i2cmb_generator extends ncsu_component;

    //shorthands for wishbone register offsets
    parameter CSR=2'b00;
    parameter DPR=2'b01;
    parameter CMDR=2'b10;
    parameter FSMR=2'b11;

    wb_agent wb_master_agent;
    i2c_agent i2c_slave_agent;

    bit useStop = 1'b1;
    bit[7:0] i2c_device_addr;

    bit[7:0] wb_write_queue[$];
    bit[7:0] wb_data_from_i2c[];
    bit[7:0] i2c_write_data[$];
    bit[7:0] i2c_current_write_data[1];

    int seq_write_num_trans_to_send;
    int seq_read_count = 32;


    function new(string name = "");
        super.new(name);
    endfunction

    virtual task run();
        i2c_device_addr = 8'h22;
        initializeCore(8'h05);

        //create array of data for I2C sequential and alternating reads
        for(int i = 0; i < 32; i++) begin
            i2c_write_data.push_back(100+i);
        end
        for(int i = 0; i < 64; i++) begin
            i2c_write_data.push_back(63-i);
        end

        fork
            begin : WISHBONE_SIM_FLOW
                int num_to_read;
                int seq_write_upper_bound = 31;
                int seq_write_lower_bound = 0;

                //TEST 1: writing 32 incrementing values from 0 to 31
                $display("Simulation beginning test 1, writing 32 incrementing values from 0 to 31");
                while(seq_write_lower_bound < 32) begin
                    seq_write_num_trans_to_send = $urandom_range(1, seq_write_upper_bound-seq_write_lower_bound);
                    wb_write_queue.delete();
                    for(int i = seq_write_lower_bound + 1; i <= seq_write_lower_bound + seq_write_num_trans_to_send; i++) begin
                        wb_write_queue.push_back(i-1);
                    end
                    wishboneWriteData(i2c_device_addr, wb_write_queue, useStop);
                    seq_write_lower_bound = seq_write_lower_bound + seq_write_num_trans_to_send;
                end

                $display("Simulation beginning test 2, reading 32 incrementing values from 100 to 131");
                //TEST 2: reading 32 incrementing values from 64 to 127
                while(seq_read_count > 0) begin
                    num_to_read = $urandom_range(1, seq_read_count);
                    wishboneReadData(i2c_device_addr, num_to_read, wb_data_from_i2c);
                    seq_read_count -= num_to_read;
                    $display("Reading %d packets from i2c, %d left", num_to_read, seq_read_count);
                end

                //TEST 3: Alternating reads & writes
                $display("Simulation beginning test 3, alternating reads and writes for 64 transfers");
                $display("  - write data from 64 to 127, read data from 63 to 0");
                for(int i = 0; i < 128; i++) begin
                    if(i % 2 == 0) begin
                        wb_write_queue.delete();
                        wb_write_queue.push_back(64 + (i/2));
                        wishboneWriteData(i2c_device_addr, wb_write_queue, useStop);
                    end else begin
                        wishboneReadData(i2c_device_addr, 1, wb_data_from_i2c);
                    end
                end
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
                            i2c_current_write_data[0] = i2c_write_data.pop_front();
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

    //task to reset DUT and set busID
    local task initializeCore(input byte busID);
        wb_transaction tmp = new;
        tmp.address = CSR;
        tmp.data = 8'b11xxxxxx;
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

    //requests numBytesToRead transmissions from I2C device at addr, appends to output queue
    local task wishboneReadData(
        input bit[7:0] addr,
        input int numBytesToRead,
        output bit[7:0] dataFromI2C[$]
    );
        wb_transaction tmp = new;
        dataFromI2C.delete();
        tmp.address = CMDR;
        tmp.data = 8'bxxxxx100;
        wb_master_agent.bl_put(tmp);

        clearIRQ();

        tmp = new;
        tmp.address = DPR;
        tmp.data = (addr << 1)+1'b1;
        wb_master_agent.bl_put(tmp);

        tmp = new;
        tmp.address = CMDR;
        tmp.data = 8'bxxxxx001;
        wb_master_agent.bl_put(tmp);

        clearIRQ();
        repeat (numBytesToRead - 1) begin
            tmp = new;
            tmp.address = CMDR;
            tmp.data = 8'bxxxxx010;
            wb_master_agent.bl_put(tmp);

            clearIRQ();

            tmp = new;
            wb_master_agent.bl_get(tmp);
            dataFromI2C.push_back(tmp.data);
        end
        tmp = new;
        tmp.address = CMDR;
        tmp.data = 8'bxxxxx011;
        wb_master_agent.bl_put(tmp);

        clearIRQ();

        tmp = new;
        wb_master_agent.bl_get(tmp);
        dataFromI2C.push_back(tmp.data);
    endtask

    // writes unpacked data array to I2C device with addr, option to send stop bit
    local task wishboneWriteData(
        input bit[7:0] addr,
        input bit[7:0] data[$],
        input bit sendStop
    );
        wb_transaction tmp = new;
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

        foreach(data[i]) begin
            tmp = new;
            tmp.address = DPR;
            tmp.data = data[i];
            wb_master_agent.bl_put(tmp);

            tmp = new;
            tmp.address = CMDR;
            tmp.data = 8'bxxxxx001;
            wb_master_agent.bl_put(tmp);

            clearIRQ();
        end

        if(sendStop) begin
            tmp = new;
            tmp.address = CMDR;
            tmp.data = 8'bxxxxx101;
            wb_master_agent.bl_put(tmp);

            clearIRQ();
        end
    endtask

endclass