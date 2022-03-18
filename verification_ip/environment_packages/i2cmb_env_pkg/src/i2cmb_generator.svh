class i2cmb_generator extends ncsu_object;
    `ncsu_register_object(i2cmb_generator)

    parameter CSR=2'b00;
    parameter DPR=2'b01;
    parameter CMDR=2'b10;
    parameter FSMR=2'b11;
    wb_agent wb_master_agent;
    i2c_agent i2c_slave_agent;

    bit[7:0] addr = 8'h22;
    bit useRepeatedStart = 1'b0;
    bit[7:0] seq_write_data[];
    bit[7:0] seq_read_data[];
    bit[7:0] wb_write_data[1];

    function new(string name = "");
        super.new(name);
    endfunction

    virtual task run();
        seq_write_data = new[32];
        for(int i = 0; i < 32; i++) begin
            seq_write_data[i] = i;
        end

        fork
        begin : WISHBONE_SIM_FLOW
        initializeCore(8'h05);
        wishboneWriteData(addr, seq_write_data, 1'b1);
        wishboneReadData(addr, 32, seq_read_data);

        for(int i = 0; i < 128; i++) begin
            if(i%2 == 0) begin // write case
                wb_write_data[0] = 64 + (i/2);
                wishboneWriteData(addr, wb_write_data, 1'b1);
            end else begin
                wishboneReadData(addr, 1, seq_read_data);
            end
        end

        end

        begin : I2C_SIM_FLOW
            i2c_transaction t = new;
            bit[7:0] i2c_write_data[] = new[32];
            bit[7:0] i2c_alternating_data[] = new[1];
            for(int i = 0; i < 32; i++) begin
                i2c_write_data[i] = 64 + i;
            end
            i2c_slave_agent.bl_get(t);
            t = new;
            t.data = i2c_write_data;
            i2c_slave_agent.bl_put(t);
            for(int i = 0; i < 128; i++) begin
                if(i%2 == 0) begin // read case
                    t = new;
                    i2c_slave_agent.bl_get(t);
                end else begin
                    i2c_alternating_data[0] = 63 - ((i-1)/2);
                    t = new;
                    t.data = i2c_alternating_data;
                    i2c_slave_agent.bl_put(t);
                end
            end
        end
        join

        $display("*-----------------------*");
        $display("Simulation Finished");
        $display("Warnings %d, Errors %d, Fatals, %d", ncsu_warnings, ncsu_errors, ncsu_fatals);
        if((ncsu_warnings == 0) && (ncsu_errors == 0) && (ncsu_fatals == 0)) $display("ALL TESTS PASSED");
        $display("*-----------------------*");
        $finish();
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

    local task wishboneWriteData(
        input bit[7:0] addr,
        input bit[7:0] data[],
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