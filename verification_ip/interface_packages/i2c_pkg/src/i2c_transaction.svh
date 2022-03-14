import i2c_pkg::*;

class i2c_transaction #(int I2C_DATA_WIDTH = 8, int I2C_ADDR_WIDTH = 7) extends ncsu_transaction;
    `ncsu_register_object(i2c_transaction)

    bit [I2C_ADDR_WIDTH-1:0] addr;
    i2c_op_t trans_type;
    bit [I2C_DATA_WIDTH-1:0] data[];

    function new(string name="");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return {super.convert2string(),$sformatf("Address: 0x%x Type: %s Data 0x%x", addr, trans_type, data)};
    endfunction

    function bit compare(i2c_transaction rhs);
        return ((this.addr == rhs.addr) && (this.trans_type == rhs.trans_type) && (this.data == rhs.data));
    endfunction

    virtual function void add_to_wave(int transaction_viewing_stream_h);
        super.add_to_wave(transaction_viewing_stream_h);
        $add_attribute(transaction_view_h, addr,"addr");
        $add_attribute(transaction_view_h, trans_type,"optype");
        //$add_attribute(transaction_view_h, data, "data");
    endfunction
endclass