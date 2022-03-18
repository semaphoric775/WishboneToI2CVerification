class wb_configuration extends ncsu_configuration;
    bit monitor_show_transactions;

    function new(string name=""); 
        super.new(name);
        monitor_show_transactions = 0;
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