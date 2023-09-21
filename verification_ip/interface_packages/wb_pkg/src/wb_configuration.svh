class wb_configuration extends ncsu_configuration;
    bit monitor_show_transactions;
    rand bit repeated_start_allowed;

    covergroup wb_configuration_cg;
        option.per_instance = 1;
        option.name = name;

        coverpoint repeated_start_allowed;
    endgroup

    function new(string name=""); 
        super.new(name);
        monitor_show_transactions = 0;
        wb_configuration_cg = new;
    endfunction
    
    function sample_coverage();
        if(verbosity_level > NCSU_LOW) begin
            $display("WB_CONFIGURATION: Sampling Coverage at time %d", $time);
        end
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