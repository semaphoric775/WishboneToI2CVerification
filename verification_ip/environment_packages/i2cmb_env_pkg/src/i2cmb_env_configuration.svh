class i2cmb_env_configuration extends ncsu_configuration;

    i2c_configuration i2c_agent_config;
    wb_configuration wb_agent_config;
    //polling or IRQ option
    rand bit core_enable_interrupts;
    //switch to invalid bus ID in test
    rand bit address_invalid_bus_id;
    //number of busses used in test
    rand int num_connected_i2c_busses;
    //array of bus numbers in use
    rand bit[7:0] valid_i2c_busses[];

    rand int num_i2c_devices_per_bus;
    rand bit[6:0] valid_i2c_addrs[];

    constraint num_connected_i2c_busses_c {
        num_connected_i2c_busses <= 16;
        num_connected_i2c_busses > 0;
        num_i2c_devices_per_bus < 16;
        num_i2c_devices_per_bus > 0;
    }

    constraint valid_i2c_addrs_c {
        foreach (valid_i2c_addrs[i])
            valid_i2c_addrs[i] inside {[1:128]};
            valid_i2c_addrs.size() == num_i2c_devices_per_bus;
            unique{valid_i2c_addrs};
    }

    constraint valid_i2c_busses_c {
            foreach (valid_i2c_busses[i])
            valid_i2c_busses[i] inside {[0:15]};
            valid_i2c_busses.size() == num_i2c_devices_per_bus;
            unique{valid_i2c_busses};
    }

    covergroup env_configuration_cg;
        option.per_instance = 1;
        option.name = name;

        //more bins are an option here
        //only expense is sim time
        //prioritizing testing IDs at extreme highs and lows
        coverpoint core_enable_interrupts;
        num_connected_i2c_busses: coverpoint num_connected_i2c_busses {
            bins num_connected_i2c_busses_range[4] = {[1:16]};
        }
        coverpoint address_invalid_bus_id;
        num_i2c_devices_per_bus: coverpoint num_i2c_devices_per_bus {
            //more bins could be hit with further CRT
            //goal is to make sure DUT can handle multiple devices
            //while also testing few enough deevices to ensure response is not red herring
            bins num_i2c_devices_per_bus_range[2] = {[1:16]};
        }

    endgroup

    function new(string name="");
        super.new(name);
        env_configuration_cg = new;
        i2c_agent_config = new("i2c_agent_config");
        wb_agent_config = new("wb_agent_config");
        i2c_agent_config.randomize();
        wb_agent_config.randomize();
        i2c_agent_config.sample_coverage();
        wb_agent_config.sample_coverage();
        if(verbosity_level > NCSU_LOW) begin
            $display("I2C Configuration Enable Clock Stretching: %b", i2c_agent_config.en_clock_stretching);
        end
    endfunction

    function void sample_coverage();
        env_configuration_cg.sample();
    endfunction

    function void set_core_enable_interrupts(bit cei);
        this.core_enable_interrupts = cei;
    endfunction

endclass
