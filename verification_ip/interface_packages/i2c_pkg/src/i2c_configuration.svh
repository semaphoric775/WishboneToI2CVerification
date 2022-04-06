class i2c_configuration extends ncsu_configuration;
    bit monitor_show_transactions;
    rand bit en_clock_stretching;

    covergroup i2c_configuration_cg;
        option.per_instance = 1;
        option.name = name;

        coverpoint en_clock_stretching;
    endgroup

    function new(string name="");
        super.new(name);
        monitor_show_transactions = 0;
        i2c_configuration_cg = new;
    endfunction

    function void sample_coverage();
        if(verbosity_level > NCSU_LOW) begin
            $display("I2C_CONFIGURATION: Sampling Coverage at time %d", $time);
        end
        i2c_configuration_cg.sample();
    endfunction

    virtual function string convert2string();
        return {super.convert2string};
    endfunction

    virtual function void enable_monitor_show_transactions();
        monitor_show_transactions = 1;
    endfunction

    virtual function void disable_monitor_show_transactions();
        monitor_show_transactions = 0;
    endfunction
endclass