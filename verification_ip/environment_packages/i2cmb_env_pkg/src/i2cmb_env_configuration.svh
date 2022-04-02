class i2cmb_env_configuration extends ncsu_configuration;

    i2c_configuration i2c_agent_config;
    wb_configuration wb_agent_config;
    bit core_enable_interrupts;

    covergroup env_configuration_cg;
        option.per_instance = 1;
        option.name = name;

        coverpoint core_enable_interrupts;
    endgroup

    function new(string name="");
        super.new(name);
        i2c_agent_config = new("i2c_agent_config");
        wb_agent_config = new("wb_agent_config");
        core_enable_interrupts = 1;
    endfunction

    function void sample_coverage();
        env_configuration_cg.sample();
    endfunction

    function set_core_enable_interrupts(bit cei);
        this.core_enable_interrupts = cei;
    endfunction

endclass