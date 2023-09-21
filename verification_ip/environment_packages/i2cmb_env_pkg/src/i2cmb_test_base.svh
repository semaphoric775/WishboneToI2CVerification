class i2cmb_test_base extends ncsu_component;

    i2cmb_env_configuration cfg;
    i2cmb_environment env;
    i2cmb_generator gen;

    function new(string name = "", ncsu_component_base  parent = null);
        super.new(name, parent);
        cfg = new("cfg");
        cfg.randomize();
        cfg.sample_coverage();
        env = new("env", this);
        env.set_configuration(cfg);
        env.build();
        gen = new("gen", this);
        gen.set_wb_agent(env.get_wb_agent());
        gen.set_i2c_agent(env.get_i2c_agent());

        //notify generator of device configuration
        //another way of doing this would be using the factory to get a unique generator
        gen.cei = cfg.core_enable_interrupts;
        gen.valid_i2c_addrs = cfg.valid_i2c_addrs;
        gen.repeated_start_allowed = cfg.wb_agent_config.repeated_start_allowed;
        gen.address_invalid_bus_id = cfg.address_invalid_bus_id;
        gen.valid_i2c_busses = cfg.valid_i2c_busses;
    endfunction

    virtual task run();
        env.run();
        gen.run();
    endtask
endclass