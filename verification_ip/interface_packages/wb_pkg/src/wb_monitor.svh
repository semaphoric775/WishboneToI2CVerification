class wb_monitor extends ncsu_component#(.T(wb_transaction));

    wb_configuration configuration;
    virtual wb_if bus;

    T monitored_trans;
    ncsu_component #(T) agent;

    function new(string name = "", ncsu_component_base  parent = null); 
        super.new(name,parent);
    endfunction

    function void set_configuration(wb_configuration cfg);
        configuration = cfg;
    endfunction

    function void set_agent(ncsu_component#(T) agent);
        this.agent = agent;
    endfunction

    virtual task run ();
        bus.wait_for_reset();
        forever begin
            monitored_trans = new("monitored_trans");
            if( enable_transaction_viewing) begin
                monitored_trans.start_time = $time;
            end
            bus.master_monitor(monitored_trans.address,
                        monitored_trans.data,
                        monitored_trans.we);
            if(configuration.monitor_show_transactions) begin
                $display("%s wb_monitor::run() address 0x%x data 0x%x",
                    get_full_name(),
                    monitored_trans.address,
                    monitored_trans.data,);
            end
            agent.nb_put(monitored_trans);
            if ( enable_transaction_viewing) begin
                monitored_trans.end_time = $time;
                monitored_trans.add_to_wave(transaction_viewing_stream);
            end
        end
    endtask

endclass