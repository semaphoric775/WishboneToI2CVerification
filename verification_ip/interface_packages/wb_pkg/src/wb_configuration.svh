class wb_configuration extends ncsu_configuration;
    bit monitor_show_transactions;
    bit collect_coverage;

    covergroup wb_configuration_cg;
        option.per_instance = 1;
        option.name = name;
    endgroup

    function new(string name=""); 
        super.new(name);
        monitor_show_transactions = 0;
    endfunction
    
    function sample_coverage();
        wb_configuration_cg.sample();
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