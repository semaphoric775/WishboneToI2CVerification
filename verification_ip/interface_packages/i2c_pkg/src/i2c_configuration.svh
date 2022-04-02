class i2c_configuration extends ncsu_configuration;
    bit monitor_show_transactions;
    bit collect_coverage;

    covergroup i2c_configuration_cg;
        option.per_instance = 1;
        option.name = name;
    endgroup

    function new(string name="");
        super.new(name);
        monitor_show_transactions = 0;
    endfunction

    function void sample_coverage();
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