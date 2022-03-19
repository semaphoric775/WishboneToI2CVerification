import i2c_pkg::*;

class i2c_driver extends ncsu_component#(.T(i2c_transaction));

    function new(string name = "", ncsu_component_base  parent = null); 
        super.new(name,parent);
    endfunction

    virtual i2c_if bus;
    i2c_configuration configuration;
    i2c_transaction i2c_trans;
    bit transaction_completed = 0;

    function void set_configuration(i2c_configuration cfg);
        configuration = cfg;
    endfunction
    
    virtual task bl_put(input T trans);
        bus.provide_read_data(trans.data, transaction_completed);
    endtask

    virtual task bl_get(output T trans);
        trans = new;
        bus.wait_for_i2c_transfer(trans.trans_type, trans.data);
    endtask

endclass