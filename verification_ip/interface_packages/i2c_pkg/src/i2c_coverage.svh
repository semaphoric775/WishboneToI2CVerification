class i2c_coverage extends ncsu_component#(.T(i2c_transaction));
    i2c_configuration configuration;

    covergroup i2c_transaction_cg;
        option.per_instance = 1;
        option.name = name;
    endgroup

    function new(string name = "", ncsu_component #(T) parent = null);
        super.new(name, parent);
        i2c_transaction_cg = new;
    endfunction

    function void set_configuration(i2c_configuration cfg);
        configuration = cfg;
    endfunction

    virtual function void nb_put(T trans);
        if(verbosity_level > NCSU_MEDIUM) begin
            $display("I2C_COVERAGE: Sampling trans %p at time %d", trans, $time);
        end
        i2c_transaction_cg.sample();
    endfunction
endclass