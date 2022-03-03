class wb_agent extends ncsu_component#(.T(wb_transaction));

    wb_configuration configuration;
    wb_driver driver;
    wb_monitor monitor;
    ncsu_component #(T) subscribers[$];
    virtual wb_if bus;

    function new(string name = "", ncsu_component_base  parent = null); 
        super.new(name,parent);
        if ( !(ncsu_config_db#(virtual wb_if)::get(get_full_name(), this.bus))) begin;
            $display("wb_agent::ncsu_config_db::get() call for BFM handle failed for name: %s ",get_full_name());
            $finish;
        end
    endfunction

    function void set_configuration(wb_configuration cfg);
        configuration = cfg;
    endfunction

    virtual function void build();
        //build monitor and driver
        driver = new("driver",this);
        driver.set_configuration(configuration);
        driver.build();
        driver.bus = this.bus;
        monitor = new("monitor",this);
        monitor.set_configuration(configuration);
        monitor.set_agent(this);
        monitor.enable_transaction_viewing = 1;
        monitor.build();
        monitor.bus = this.bus;
    endfunction

    virtual function void nb_put(T trans);
        foreach (subscribers[i]) subscribers[i].nb_put(trans);
    endfunction

    virtual task bl_put(T trans);
        driver.bl_put(trans);
    endtask

    virtual function void connect_subscriber(ncsu_component#(T) subscriber);
        subscribers.push_back(subscriber);
    endfunction

    virtual task run();
        fork monitor.run(); join_none
    endtask

endclass