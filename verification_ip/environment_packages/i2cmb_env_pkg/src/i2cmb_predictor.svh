import i2c_pkg::*;

class i2cmb_predictor extends ncsu_component#(.T(wb_transaction));
    //shorthands for wishbone register offsets
    parameter CSR=2'b00;
    parameter DPR=2'b01;
    parameter CMDR=2'b10;
    parameter FSMR=2'b11;

    //states used to track transaction progress
    //NOTE: the predictor model assumes a valid sequence of operations from the generator,
    //  predictor model also assumes interrupts are enabled, polling the CMDR is also possible
    local typedef enum {
        WAITING, TRANSACTION_STARTED, SENDING_ADDRESS,
        WRITE_TRANSACTION_STARTED, READ_TRANSACTION_STARTING,
        WRITE_TRANSACTION_IN_PROGRESS, READ_TRANSACTION_W_NACK,
        READ_TRANSACTION_NO_NACK} 
    trans_state;
    local trans_state current_state;

    ncsu_component#(.T(i2c_transaction)) scoreboard;
    i2cmb_env_configuration configuration;

    i2c_transaction predicted_trans;
    i2c_transaction throwaway; //throwaway transaction to use scoreboards nb_transport function

    bit[7:0] predicted_trans_data[$];

    function new(string name = "", ncsu_component_base  parent = null); 
        super.new(name,parent);
        current_state = WAITING;
    endfunction

    function void set_configuration(i2cmb_env_configuration cfg);
        configuration = cfg;
    endfunction

    virtual function void set_scoreboard(ncsu_component#(.T(i2c_transaction))  scoreboard);
        this.scoreboard = scoreboard;
    endfunction

    virtual function void nb_put(T trans);
        case (current_state)
        WAITING: begin
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

            if(trans.address == DPR) begin
                predicted_trans.addr = trans.data >> 1;
                if(trans.data[0]) begin
                    predicted_trans.trans_type = READ;
                    current_state = READ_TRANSACTION_STARTING;
                end else begin
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
        READ_TRANSACTION_STARTING: begin
            if(trans.address == CMDR) begin
                if(trans.data == 3'b010) begin
                    current_state = READ_TRANSACTION_NO_NACK;
                end
                if (trans.data == 3'b011) begin
                    current_state = READ_TRANSACTION_W_NACK;
                end
            end
        end
        READ_TRANSACTION_NO_NACK: begin
            if(trans.address == DPR) begin
                predicted_trans_data.push_back(trans.data);
                current_state = READ_TRANSACTION_STARTING;
            end
        end
        READ_TRANSACTION_W_NACK: begin
            if(trans.address == DPR) begin
                predicted_trans_data.push_back(trans.data);
                predicted_trans.data = predicted_trans_data;
                current_state = WAITING;
                scoreboard.nb_transport(predicted_trans, throwaway);
            end
        end
        default: current_state = WAITING;
        endcase

    endfunction
endclass