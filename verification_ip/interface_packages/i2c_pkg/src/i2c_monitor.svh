class i2c_monitor extends ncsu_component#(.T(i2c_transaction));

    i2c_configuration configuration;
    virtual i2c_if bus;

    T monitored_trans;
    ncsu_component #(T) agent;

    function new(string name = "", ncsu_component_base  parent = null); 
        super.new(name,parent);
    endfunction

    function void set_configuration(i2c_configuration cfg);
        configuration = cfg;
    endfunction

    function void set_agent(ncsu_component#(T) agent);
        this.agent = agent;
    endfunction

    virtual task run ();
        forever begin
            monitored_trans = new("monitored_trans");
            if ( enable_transaction_viewing) begin
                monitored_trans.start_time = $time;
            end
            bus.monitor(monitored_trans.addr,
                        monitored_trans.trans_type,
                        monitored_trans.data);
            if(configuration.monitor_show_transactions) begin
                $display("%s i2c_monitor::run() address 0x%x optype %s data 0x%x",
                    get_full_name(),
                    monitored_trans.addr,
                    monitored_trans.trans_type,
                    monitored_trans.data);
            end
            agent.nb_put(monitored_trans);
            if ( enable_transaction_viewing) begin
                monitored_trans.end_time = $time;
                monitored_trans.add_to_wave(transaction_viewing_stream);
            end
        end
    endtask

endclass