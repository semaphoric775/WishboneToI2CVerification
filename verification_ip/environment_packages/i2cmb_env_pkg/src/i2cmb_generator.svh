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