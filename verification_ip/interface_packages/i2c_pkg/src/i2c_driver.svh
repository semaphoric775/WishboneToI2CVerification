import i2c_pkg::*;

class i2c_driver extends ncsu_component#(.T(i2c_transaction));

    function new(string name = "", ncsu_component_base  parent = null); 
        super.new(name,parent);
        if ( !(ncsu_config_db#(virtual i2c_if)::get(get_full_name(), this.bus))) begin;
            $display("i2c_agent::ncsu_config_db::get() call for BFM handle failed for name: %s ",get_full_name());
            $finish;
        end
    endfunction

    virtual i2c_if bus;
    i2c_configuration configuration;
    i2c_transaction i2c_trans;

    function void set_configuration(i2c_configuration cfg);
        configuration = cfg;
    endfunction
    
    virtual task bl_put(T trans);
        //CHANGE THIS FROM HARDCODED
        bit[7:0] tmp[];
        bit transfer_complete;
        bus.wait_for_i2c_transfer(trans.trans_type, tmp);
        if(trans.trans_type !== READ) begin
            $warning("Expected read transaction from wishbone master");
        end
        bus.provide_read_data(trans.data, transfer_complete);
        if(!transfer_complete) begin
            $warning("Wishbone master requests more data");
        end
    endtask

    virtual task bl_get(output T trans);
        i2c_op_t op;
        trans = new;
        bus.wait_for_i2c_transfer(trans.trans_type, trans.data);
    endtask

endclass