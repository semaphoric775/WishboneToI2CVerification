import i2c_pkg::*;

class i2cmb_coverage extends ncsu_component#(.T(i2c_transaction));

    i2cmb_env_configuration configuration;
    i2c_transaction coverage_transaction;
    bit [7-1:0] addr;
    i2c_op_t trans_type;

    covergroup i2cmb_coverage_cg;
        option.per_instance = 1;
        option.name = get_full_name();

        trans_type: coverpoint trans_type
        {
            bins READ = {READ};
            bins WRITE = {WRITE};
        }

        addr: coverpoint addr {
            bins addr_range[8] = {[1:$]};
        }

        addrXtrans_type: cross trans_type, addr;
    endgroup

  function void set_configuration(i2cmb_env_configuration cfg);
  	configuration = cfg;
  endfunction

    function new(string name="", ncsu_component_base  parent = null);
        super.new(name, parent);
        i2cmb_coverage_cg = new;
    endfunction

    virtual function void nb_put(T trans);
        if(verbosity_level > NCSU_MEDIUM) begin
            $display("I2CMB_COVERAGE: sampling transaction %p at time %d", trans, $time);
        end
        this.addr = trans.addr;
        this.trans_type = trans.trans_type;
        i2cmb_coverage_cg.sample();
    endfunction

endclass