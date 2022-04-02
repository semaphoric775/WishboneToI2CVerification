class wb_coverage extends ncsu_component#(.T(wb_transaction));

    wb_configuration configuration;

    covergroup wb_transaction_cg;
        option.per_instance = 1;
        option.name = get_full_name();
    endgroup

    function new(string name = "", ncsu_component #(T) parent = null);
        super.new(name, parent);
        wb_transaction_cg = new;
    endfunction

    function void set_configuration(wb_configuration cfg);
        configuration = cfg;
    endfunction

    virtual function void nb_put(T trans);
        wb_transaction_cg.sample();
    endfunction
endclass