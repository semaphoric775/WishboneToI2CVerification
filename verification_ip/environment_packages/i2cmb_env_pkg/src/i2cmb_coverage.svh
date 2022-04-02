import i2c_pkg::*;

class i2cmb_coverage extends ncsu_component;

    i2cmb_env_configuration configuration;
    i2c_transaction coverage_transaction;

    covergroup i2cmb_coverage_cg;
        option.per_instance = 1;
        option.name = get_full_name();
    endgroup

  function void set_configuration(i2cmb_env_configuration cfg);
  	configuration = cfg;
  endfunction

    function new(string name="", ncsu_component_base  parent = null);
        super.new(name, parent);
    endfunction

    virtual function void nb_put(T trans);
        i2cmb_coverage_cg.sample();
    endfunction

endclass