import i2c_pkg::*;

`timescale 1ns / 10ps

interface i2c_if    #(
    int I2C_ADDR_WIDTH=7,
    int I2C_DATA_WIDTH=8,
    int NUM_I2C_BUSSES=16
    )
(
    triand[NUM_I2C_BUSSES] scl,
    triand[NUM_I2C_BUSSES] sda,
    input wire rst_i,
    input wire clk
);

// SDA output values and write enable
logic sda_o;
bit sda_we = 0;

// SCL output values and write enable
logic scl_o;
bit scl_we = 0;

//bus to select out of maximum of 16
//default to bus 0 -- mux can't connect nowhere
reg[3:0] selected_bus_id = 4'b0000;

wire sda_curr;
wire scl_curr;
assign sda_curr = sda[selected_bus_id];
assign scl_curr = scl[selected_bus_id];

//generate 16x1 mux
genvar i;
generate
    for(i = 0; i < 16; i++) begin
        assign sda[i] = (selected_bus_id == i) ? (sda_we ? sda_o : 1'bz) : 1'bz;
        assign scl[i] = (selected_bus_id == i) ? (scl_we ? scl_o : 1'bz) : 1'bz;
    end
endgenerate

typedef enum {START, STOP, DATA} i2c_bit_type;

// ****************************************************************************             
// Task to get data from sda && scl line
//  can return a START, STOP, or DATA condition
//  if data is detected (posedge scl happens before a start or stop condition)
//  it is passed back as an output 
    task get_link_status(output i2c_bit_type bt, output bit data);
        fork : GET_COND
            begin : DATA_CASE
                @(posedge scl_curr);
                data = sda_curr;
                bt = DATA;
            end
            begin : START_CASE
                forever begin
                    @(negedge sda_curr)
                    if(scl_curr) begin
                        bt = START; 
                        break;
                    end
                end
            end
            begin : STOP_CASE
                forever begin
                   @(posedge sda_curr)
                   if(scl_curr) begin
                        bt = STOP;
                        break;
                       end
                end
            end
        join_any // task will exit once any condition detected
        return;
    endtask

// trigger for assertion
reg sending_ack = 0;

// ****************************************************************************             
// Pulls sda line low to acknowledge I2C master
    task send_ack();
        @(posedge scl_curr)
        sda_o = 0;
        sda_we = 1;
        @(negedge scl_curr)
        sending_ack = 1;
        sda_we = 0;
        sending_ack = 0;
    endtask

// ****************************************************************************             
// Immediately sends bit over sda line
//  cannot change on clock edge since this would be an I2C violation

    task send_bit(bit b);
        sda_o = b;
        sda_we = 1;
        @(negedge scl_curr)
        sda_we = 0;
    endtask

// ****************************************************************************             
    bit wait_for_i2c_transfer_repeated_start = 1'b0;

    property ack_bit_sends;
        @(posedge sending_ack) disable iff(rst_i) sda_curr == 1'b0;
    endproperty

    assert property(ack_bit_sends) else $warning("INTERFACE WARNING: I2C acknowledge bit not sent at time %d", $time);

    task wait_for_i2c_transfer (output i2c_op_t op, output bit[I2C_DATA_WIDTH-1:0] write_data[]);
    //temporary storage values
    bit[I2C_ADDR_WIDTH-1:0] addr_tmp;
    bit[I2C_DATA_WIDTH-1:0] write_data_queue[$];
    //data from one I2C transmission
    bit[I2C_DATA_WIDTH-1:0] packet;

    i2c_bit_type bt;
    bit one_data_bit;
    
    
    //clears queue to remove previous transmissions 
    write_data_queue.delete();

    if(!wait_for_i2c_transfer_repeated_start) do get_link_status(bt, one_data_bit); while(bt != START);
    else wait_for_i2c_transfer_repeated_start = 1'b0;

    repeat(I2C_ADDR_WIDTH)
        begin
                get_link_status(bt, one_data_bit);
                assert(bt == DATA) else $error("Faulty I2C Address Transmission");
                addr_tmp = {addr_tmp, one_data_bit};
        end

    @(posedge scl_curr) op = sda_curr ? READ : WRITE; 
    @(negedge scl_curr)
    send_ack();

    if(op == READ)
        return;

    forever begin
        repeat(I2C_DATA_WIDTH) begin
            get_link_status(bt, one_data_bit);
            //exit on new start or stop bit
            if(bt != DATA) begin 
                write_data = write_data_queue;
                if(bt == START) begin
                    wait_for_i2c_transfer_repeated_start = 1'b1;
                end
                return;
            end
            packet = {packet, one_data_bit};
        end
        write_data_queue.push_back(packet);
        send_ack();
    end
   endtask

// **************************************************************************** 
// Same as wait_for_transfer task, but pauses transaction once during address transmission,
//  once during write transaction   
    task wait_for_i2c_transfer_clock_stretch (output i2c_op_t op, output bit[I2C_DATA_WIDTH-1:0] write_data[]);
    //temporary storage values
    int wr_pause_idx;
    bit[I2C_ADDR_WIDTH-1:0] addr_tmp;
    bit[I2C_DATA_WIDTH-1:0] write_data_queue[$];
    //data from one I2C transmission
    bit[I2C_DATA_WIDTH-1:0] packet;

    i2c_bit_type bt;
    bit one_data_bit;
    int wr_bit_count;
    
    //clears queue to remove previous transmissions 
    write_data_queue.delete();
    //randomize where clock is stretched
    wr_pause_idx = $urandom_range(1,5);
    wr_bit_count = 0;
    

    if(!wait_for_i2c_transfer_repeated_start) do get_link_status(bt, one_data_bit); while(bt != START);
    else wait_for_i2c_transfer_repeated_start = 1'b0;

    repeat(I2C_ADDR_WIDTH)
        begin
            get_link_status(bt, one_data_bit);
            assert(bt == DATA) else $error("Faulty I2C Address Transmission");
            addr_tmp = {addr_tmp, one_data_bit};
        end

    @(posedge scl_curr) op = sda_curr ? READ : WRITE; 
    @(negedge scl_curr)
    send_ack();

    if(op == READ)
        return;

    forever begin
        repeat(I2C_DATA_WIDTH) begin
            get_link_status(bt, one_data_bit);
            //exit on new start or stop bit
            if(bt != DATA) begin 
                write_data = write_data_queue;
                if(bt == START) begin
                    wait_for_i2c_transfer_repeated_start = 1'b1;
                end
                return;
            end
            packet = {packet, one_data_bit};
            wr_bit_count++;
            if(wr_bit_count == wr_pause_idx) begin
                //give clock cycle time to complete before pulling scl to gnd
                @(negedge scl_curr);
                scl_o = 0;
                scl_we = 1;
                #20000
                scl_we = 0;
            end
        end
        write_data_queue.push_back(packet);
        send_ack();
    end
   endtask

// ****************************************************************************              
    task provide_read_data (input bit [I2C_DATA_WIDTH-1:0] read_data [], output bit transfer_complete);
        transfer_complete = 0;
        for(int i=0; i<read_data.size(); i++) begin
            for(int j=I2C_DATA_WIDTH-1; j >= 0; j--) begin
                send_bit(read_data[i][j]);
            end 
            @(posedge scl_curr);
            //nack condition detected
            if(sda_curr == 1) begin
                transfer_complete = 1;
                return;
            end    
            @(negedge scl_curr);
        end // quit task with transfer_complete=0 if read_data exhausted
    endtask

// ****************************************************************************
    bit monitor_repeated_start = 1'b0;

    task monitor( output bit [I2C_ADDR_WIDTH-1:0] addr, output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] data[]);
    bit[I2C_DATA_WIDTH-1:0] packet;
    bit[I2C_DATA_WIDTH-1:0] data_queue[$];

    i2c_bit_type bt;
    bit one_data_bit;
    
    //reset data_queue
    data_queue.delete();

    if(!monitor_repeated_start) do get_link_status(bt, one_data_bit); while(bt != START);
    else monitor_repeated_start = 1'b0;

    repeat(I2C_ADDR_WIDTH) begin
        get_link_status(bt, one_data_bit);
        addr = {addr, one_data_bit};
    end

    @(posedge scl_curr);
    op = sda_curr ? READ : WRITE;    

    //skip ack bit
    @(posedge scl_curr);
    @(negedge scl_curr);

    forever begin
        repeat(I2C_DATA_WIDTH) begin
            get_link_status(bt, one_data_bit);
            if(bt != DATA) begin
                if(bt == START) begin
                    monitor_repeated_start = 1'b1;
                end
                data = data_queue;
                return;
            end
            packet = {packet, one_data_bit};
        end
        data_queue.push_back(packet);
        //check if bit is NACK in the case of a read from master
        @(posedge scl_curr);
        if(op == READ) begin
            if(sda_curr == 1'b1) begin
                data = data_queue;
                return;
            end
        end
        @(negedge scl_curr);
    end
    endtask

    function void set_bus(bit[3:0] new_id);
        selected_bus_id = new_id;
    endfunction
endinterface
