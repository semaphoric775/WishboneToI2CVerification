class wb_transaction_rand_data #(int WB_ADDR_WIDTH = 2, int WB_DATA_WIDTH = 8) extends wb_transaction;
    `ncsu_register_object(wb_transaction_rand_data)

    bit [WB_ADDR_WIDTH-1:0] address;
    randc bit [WB_DATA_WIDTH-1:0] data;
    bit we;

    constraint data_c {
        data inside {[0:255]};
    }

    function new(string name="");
        super.new(name);
        this.address = 2'b01;
    endfunction

    virtual function string convert2string();
        return {super.convert2string(),$sformatf("Address: 0x%x Data 0x%x", this.address, this.data)};
    endfunction

    function bit compare(wb_transaction rhs);
        return ((this.address == rhs.address) && (this.data == rhs.data));
    endfunction

    virtual function void add_to_wave(int transaction_viewing_stream_h);
        super.add_to_wave(transaction_viewing_stream_h);
        $add_attribute(transaction_view_h, address, "address");
        $add_attribute(transaction_view_h, data,"data");
    endfunction
endclass