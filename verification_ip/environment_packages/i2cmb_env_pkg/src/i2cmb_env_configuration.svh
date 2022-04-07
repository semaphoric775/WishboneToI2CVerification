class i2cmb_env_configuration extends ncsu_configuration;

    i2c_configuration i2c_agent_config;
    wb_configuration wb_agent_config;
    bit core_enable_interrupts = 1;
    bit address_invalid_bus_id;
    rand int num_connected_i2c_busses;
    rand int num_i2c_devices_per_bus;

    constraint num_connected_i2c_busses_c {
        num_connected_i2c_busses <= 16;
        num_i2c_devices_per_bus < 4;
    }

    covergroup env_configuration_cg;
        option.per_instance = 1;
        option.name = name;

        coverpoint core_enable_interrupts;
        coverpoint num_connected_i2c_busses;
        coverpoint address_invalid_bus_id;
        coverpoint num_i2c_devices_per_bus;
    endgroup

    function new(string name="");
        super.new(name);
        env_configuration_cg = new;
        i2c_agent_config = new("i2c_agent_config");
        wb_agent_config = new("wb_agent_config");
        i2c_agent_config.sample_coverage();
        wb_agent_config.sample_coverage();
    endfunction

    function void sample_coverage();
        env_configuration_cg.sample();
    endfunction

    function void set_core_enable_interrupts(bit cei);
        this.core_enable_interrupts = cei;
    endfunction

endclass