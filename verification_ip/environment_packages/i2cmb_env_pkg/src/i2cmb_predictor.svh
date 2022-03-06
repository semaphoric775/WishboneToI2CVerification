class i2cmb_predictor extends ncsu_component#(.T(wb_transaction));

    ncsu_component#(.T(i2c_transaction)) scoreboard;
    i2c_transaction transport_trans;
    i2cmb_env_configuration configuration;

    function new(string name = "", ncsu_component_base  parent = null); 
        super.new(name,parent);
    endfunction

    function void set_configuration(i2cmb_env_configuration cfg);
        configuration = cfg;
    endfunction

    virtual function void set_scoreboard(ncsu_component#(.T(i2c_transaction))  scoreboard);
        this.scoreboard = scoreboard;
    endfunction
endclass