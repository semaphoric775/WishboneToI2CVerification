import i2c_pkg::*;

class i2cmb_predictor extends ncsu_component#(.T(wb_transaction));
    parameter CSR=2'b00;
    parameter DPR=2'b01;
    parameter CMDR=2'b10;
    parameter FSMR=2'b11;

    //states used to track the wishbone transaction progress
    //there is also likely a procedural way to do this
    //scoreboard will receive predicted transaction if a stop/start bit after the initial start is detected when writing to the wishbone
    //or when a read request with a NACK is sent
    local typedef enum {
        WAITING, TRANSACTION_STARTED, SENDING_ADDRESS,
        WRITE_TRANSACTION_STARTED, READ_TRANSACTION_STARTED,
        WRITE_TRANSACTION_IN_PROGRESS} 
    trans_state;
    local trans_state current_state = WAITING;

    ncsu_component#(.T(i2c_transaction)) scoreboard;
    i2c_transaction predicted_trans;
    i2cmb_env_configuration configuration;
    //dummy transaction used in scbd
    i2c_transaction throwaway;
    //CHANGE FROM HARDCODED
    bit[7:0] predicted_trans_data[$];

    function new(string name = "", ncsu_component_base  parent = null); 
        super.new(name,parent);
    endfunction

    function void set_configuration(i2cmb_env_configuration cfg);
        configuration = cfg;
    endfunction

    virtual function void set_scoreboard(ncsu_component#(.T(i2c_transaction))  scoreboard);
        this.scoreboard = scoreboard;
    endfunction

    virtual function void nb_put(T trans);
    //add compatability for IRQ & polling mode
        case (current_state)
        WAITING: begin
            //move to transaction started if start bit detected,
            //create new i2c transaction object
            if((trans.address == CMDR) && (trans.data[2:0] == 3'b100)) begin
                current_state = TRANSACTION_STARTED;
            end else current_state = WAITING;
        end
        TRANSACTION_STARTED: begin
            if((trans.address == CMDR) && (trans.data[7])) begin
                current_state = SENDING_ADDRESS;
            end
        end
        SENDING_ADDRESS: begin
            predicted_trans = new;
            predicted_trans_data.delete();
            //3 cases all resolved with throwing away LSB and right shifting by 1
            if(trans.address == DPR) begin
                predicted_trans.addr = trans.data >> 1;
                //read transaction
                if(trans.data[0]) begin
                    predicted_trans.trans_type = READ;
                    current_state = READ_TRANSACTION_STARTED;
                end else begin // write transaction
                    predicted_trans.trans_type = WRITE;
                    current_state = WRITE_TRANSACTION_STARTED;
                end
            end
        end
        WRITE_TRANSACTION_STARTED: begin
            if(trans.address == CMDR) begin
                current_state = WRITE_TRANSACTION_IN_PROGRESS;
            end
        end
        WRITE_TRANSACTION_IN_PROGRESS: begin
            if(trans.address == DPR) begin
                predicted_trans_data.push_back(trans.data);
            end else if(trans.address == CMDR) begin
                //repeated start case
                if(trans.data[2:0] == 3'b100) begin
                    predicted_trans.data = predicted_trans_data;
                    current_state = TRANSACTION_STARTED;
                    scoreboard.nb_transport(predicted_trans, throwaway);
                end
                //stop bit case
                if(trans.data[2:0] == 3'b101) begin
                    predicted_trans.data = predicted_trans_data;
                    current_state = WAITING;
                    scoreboard.nb_transport(predicted_trans, throwaway);
                end
            end
        end
        default: current_state = WAITING;
        endcase

        //$display({get_full_name()," nb_put: actual ",trans.convert2string()});
    endfunction
endclass