class i2cmb_test extends ncsu_object;
    `ncsu_register_object(i2cmb_test);
    i2cmb_env_configuration cfg;
    i2cmb_environment env;
    i2cmb_generator gen;

    function new(string name = "");
        super.new(name);
        cfg = new("cfg");
        env = new("env");
        env.set_configuration(cfg);
        env.build();
        gen = new("gen");
        gen.set_wb_agent(env.get_wb_agent());
        gen.set_i2c_agent(env.get_i2c_agent());
    endfunction

    virtual task run();
        env.run();
        gen.run();
    endtask
endclass