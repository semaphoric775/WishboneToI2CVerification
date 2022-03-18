class i2cmb_scoreboard extends ncsu_component#(.T(i2c_transaction));
    function new(string name = "", ncsu_component_base  parent = null); 
        super.new(name,parent);
    endfunction

    T trans_out; // throwaway variable for nb_transport method
    // Queues for storing transactions
    // since the order of nb_put and nb_transport depends
    // on read/write requests, queues cache transactions
    T real_transactions[$];
    T predicted_transactions[$];

    virtual function void nb_transport(input T input_trans, output T output_trans);
        $display({get_full_name()," nb_transport: expected transaction ",input_trans.convert2string()});
        predicted_transactions.push_back(input_trans);
        output_trans = trans_out;
        update_comparisons();
    endfunction

    virtual function void nb_put(T trans);
        $display({get_full_name()," nb_put: actual transaction ",trans.convert2string()});
        real_transactions.push_back(trans);
        update_comparisons();
    endfunction

    //check expected and real output if needed
    local function void update_comparisons();
        if((predicted_transactions.size() > 0) && (real_transactions.size() > 0)) begin
            if ( predicted_transactions[0].compare(real_transactions[0]) ) $display({get_full_name()," wb_transaction->i2c_transaction MATCH!"});
            else begin
                ncsu_errors++;
                $warning({get_full_name()," wb_transaction->i2c_transaction DIFFER!"});
            end
            predicted_transactions.pop_front();
            real_transactions.pop_front();
        end
    endfunction
endclass