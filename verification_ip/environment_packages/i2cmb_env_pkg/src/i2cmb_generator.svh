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
        wb_transaction wb_data_from_i2c;
        seq_write_data = new[32];
        foreach(wb_startup_seq[i]) begin
            wb_startup_seq[i] = new;
        end
        for(int i = 0; i < 32; i++) begin
            seq_write_data[i] = i;
        end

        //uncomment to enable write test flow
        genWriteTransactions(seq_writes, addr, seq_write_data, useRepeatedStart);
        genReadTransactionPreamble(wb_read_requests, addr, 1'b0);

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
        fork
        begin : WISHBONE_SIM_FLOW
        // Test Single Write
        sendWbTransactionsBlPut(seq_writes);

        sendWbTransactionsBlPut(wb_read_requests);
        wb_master_agent.bl_get(wb_data_from_i2c);

        repeat (30) begin
            wb_read_requests.delete();
            genReadRequest(wb_read_requests, 1'b0);
            sendWbTransactionsBlPut(wb_read_requests);
            wb_master_agent.bl_get(wb_data_from_i2c);
        end
        wb_read_requests.delete();
        genReadRequest(wb_read_requests, 1'b1);

        sendWbTransactionsBlPut(wb_read_requests);
        wb_master_agent.bl_get(wb_data_from_i2c);

        for(int i = 0; i < 128; i++) begin
            if(i%2==0) begin // write case
                seq_writes.delete();
                seq_write_data = new[1];
                seq_write_data[0] = 64 + (i/2);
                genWriteTransactions(seq_writes, addr, seq_write_data, useRepeatedStart);
                sendWbTransactionsBlPut(seq_writes);
            end else begin // read case
                wb_read_requests.delete();
                genReadTransactionPreamble(wb_read_requests, addr, 1'b1);
                sendWbTransactionsBlPut(wb_read_requests);
                wb_master_agent.bl_get(wb_data_from_i2c);
            end
        end
        end

        begin : I2C_SIM_FLOW
            i2c_transaction t = new;
            bit[7:0] i2c_write_data[] = new[32];
            i2c_transaction i2c_to_wb_data = new;
            for(int i = 0; i < 32; i++) begin
                i2c_write_data[i] = 100+i;
            end
            i2c_slave_agent.bl_get(t);
            i2c_to_wb_data.data = i2c_write_data;
            t = new;
            i2c_slave_agent.bl_put(i2c_to_wb_data);

            i2c_write_data.delete();
            i2c_write_data = new[1];
            i2c_to_wb_data.data = i2c_write_data;
            for(int i = 0; i < 128; i++) begin
                if(i%2 == 0) begin // read from wishbone master
                    t = new;
                    i2c_slave_agent.bl_get(t);
                end else begin
                    i2c_write_data[0] = 63 - ((i-1)/2);
                    i2c_to_wb_data.data = i2c_write_data;
                    i2c_slave_agent.bl_put(i2c_to_wb_data);
                end
            end
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

    local task sendWbTransactionsBlPut(
        wb_transaction trans[$]
    );
        foreach(trans[i]) begin
            //null in wb_transaction sequence is used to denote that the IRQ flag must be cleared
            if(trans[i] == null) clearIRQ();
            else wb_master_agent.bl_put(trans[i]);
        end
    endtask

    //generates read transaction request without address/start bit
    local function void genReadRequest(
        ref wb_transaction trans[$],
        input bit sendNack
    );
    wb_transaction tmp = new;
    tmp.address = CMDR;
    if(sendNack) tmp.data = 8'bxxxxx011;
    else tmp.data = 8'bxxxxx010;
    trans.push_back(tmp);

    tmp = null;
    trans.push_back(tmp);

    endfunction

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