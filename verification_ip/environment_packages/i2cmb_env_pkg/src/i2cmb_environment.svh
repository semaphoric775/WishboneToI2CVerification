class i2cmb_environment extends ncsu_object;
    `ncsu_register_object(i2cmb_environment)

    i2cmb_env_configuration configuration;
    wb_agent wb_master_agent;
    i2c_agent i2c_slave_agent;
    i2cmb_predictor pred;
    i2cmb_scoreboard scbd;

    function new(string name="");
        super.new(name);
    endfunction

    function void set_configuration(i2cmb_env_configuration cfg);
        configuration = cfg;
    endfunction

    virtual function void build();
        wb_master_agent = new("wb_agent");
        wb_master_agent.set_configuration(configuration.wb_agent_config);
        wb_master_agent.build();
        i2c_slave_agent = new("i2c_slave_agent");
        i2c_slave_agent.set_configuration(configuration.i2c_agent_config);
        i2c_slave_agent.build();
        pred = new("pred");
        pred.set_configuration(configuration);
        pred.build();
        scbd = new("scbd");
        scbd.build();
        wb_master_agent.connect_subscriber(pred);
        pred.set_scoreboard(scbd);
        i2c_slave_agent.connect_subscriber(scbd);
    endfunction

    function wb_agent get_wb_agent();
        return wb_master_agent;
    endfunction

    function i2c_agent get_i2c_agent();
        return i2c_slave_agent;
    endfunction

    virtual task run();
        wb_master_agent.run();
        i2c_slave_agent.run();
    endtask
endclass