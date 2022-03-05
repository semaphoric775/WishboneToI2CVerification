import i2c_pkg::*;

class i2c_driver extends ncsu_component#(.T(i2c_transaction));

    function new(string name = "", ncsu_component_base  parent = null); 
        super.new(name,parent);
    endfunction

    virtual i2c_if bus;
    i2c_configuration configuration;
    i2c_transaction i2c_trans;

    function void set_configuration(i2c_configuration cfg);
        configuration = cfg;
    endfunction
    
    virtual task bl_put(T trans);
        $display({get_full_name(), " ", trans.convert2string()});
        if(trans.trans_type == WRITE) begin // I2C device has data written to it
            //TODO
        end else begin // I2C device providing data
            //TODO
        end
    endtask

endclass