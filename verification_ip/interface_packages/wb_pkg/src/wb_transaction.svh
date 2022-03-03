`include "wb_reg_defines.svh";

class wb_transaction extends ncsu_transaction;
    `ncsu_register_object(wb_transaction)

    bit [1:0] reg_offset;
    bit[7:0] command; 
    
    function new(string name="");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return {super.convert2string(),$sformatf("Register: 0x%x command 0x%x")};
    endfunction

    function bit compare(wb_transaction rhs);
        return ((this.reg_offset == rhs.reg_offset) && (this.command == rhs.command));
    endfunction

    virtual function void add_to_wave(int transaction_viewing_stream_h);

    endfunction
endclass
