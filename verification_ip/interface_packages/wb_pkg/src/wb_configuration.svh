class wb_configuration extends ncsu_configuration;
    //ADD To this later
    //repeated starts, differing widths, frequencies, added delay, clock stretching???

    function new(string name=""); 
        super.new(name);
    endfunction
    
    virtual function string convert2string();
     return {super.convert2string};
  endfunction
endclass