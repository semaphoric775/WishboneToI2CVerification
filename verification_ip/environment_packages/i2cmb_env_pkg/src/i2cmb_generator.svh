class i2cmb_generator extends ncsu_object;
    `ncsu_register_object(i2cmb_generator)

    ncsu_component#(.T(wb_transaction)) wb_agent;
    ncsu_component#(.T(i2c_transaction)) i2c_agent;

    function new(string name = "");
        super.new(name);
    endfunction

    virtual task run();
        //TODO
    endtask

    function void set_i2c_agent(ncsu_component#(.T(i2c_transaction)) agent);
        this.i2c_agent = agent;
    endfunction

    function void set_wb_agent(ncsu_component#(.T(i2c_transaction)) agent);
        this.wb_agent = agent;
    endfunction

endclass