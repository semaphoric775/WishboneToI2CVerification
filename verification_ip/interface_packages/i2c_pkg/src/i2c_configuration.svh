class i2c_configuration extends ncsu_configuration;
    //possible additions
    //multiple agents driving interface to simulate
    //multiple I2C devices, differing frequencies
    //clock stretching?

    function new(string name="");
        super.new(name);
    endfunction

    virtual function string convert2string();
     return {super.convert2string};
    endfunction
endclass