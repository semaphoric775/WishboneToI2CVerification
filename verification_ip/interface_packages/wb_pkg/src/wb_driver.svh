class wb_driver extends ncsu_component#(.T(wb_transaction));

    function new(string name = "", ncsu_component_base parent = null);
        super.new(name, parent);
    endfunction

    virtual wb_if bus;
    wb_configuration configuration;

    function void set_configuration(wb_configuration cfg);
        configuration = cfg;
    endfunction

    virtual task bl_put(T trans);
        //$display({get_full_name(), " ", trans.convert2string()});
        bus.master_write(trans.address, trans.data);
    endtask

    virtual task bl_get(output T trans);
        trans = new;
        bus.master_read(2'b01, trans.data);
        //$display({get_full_name(), " ", trans.convert2string()});
    endtask

endclass