class i2cmb_env_configuration extends ncsu_configuration;

    i2c_configuration i2c_agent_config;
    wb_configuration wb_agent_config;
    bit core_enable_interrupts;

    function new(string name="");
        super.new(name);
        i2c_agent_config = new("i2c_agent_config");
        wb_agent_config = new("wb_agent_config");
        core_enable_interrupts = 1;
    endfunction

    function set_core_enable_interrupts(bit cei);
        this.core_enable_interrupts = cei;
    endfunction

endclass