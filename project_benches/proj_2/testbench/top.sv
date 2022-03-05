`timescale 1ns / 10ps

// import the i2c_op_t type
import i2c_pkg::*;

module top();

parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;
parameter int NUM_I2C_BUSSES = 1;
parameter int I2C_DATA_WIDTH = 8;
parameter int I2C_ADDR_WIDTH = 7;

bit  clk;
bit  rst = 1'b1;
wire cyc;
wire stb;
wire we;
tri1 ack;
wire [WB_ADDR_WIDTH-1:0] adr;
wire [WB_DATA_WIDTH-1:0] dat_wr_o;
wire [WB_DATA_WIDTH-1:0] dat_rd_i;
wire irq;
tri  [NUM_I2C_BUSSES-1:0] scl;
tri  [NUM_I2C_BUSSES-1:0] sda;

// **************************************************************************** 
// Clock generator

initial
    begin: CLK_GEN 
        clk=1'b0;
    end
always
    #5 clk = !clk;

// ****************************************************************************
// Reset generator

initial
    begin : RST_GEN
        #113    rst=1'b0;
    end

// ****************************************************************************
// Monitor Wishbone bus and display transfers in the transcript

// dummy storage variables for monitoring task
logic [WB_ADDR_WIDTH-1:0] wb_monitor_addr;
logic [WB_DATA_WIDTH-1:0] wb_monitor_data;
logic wb_monitor_we;

initial
    forever begin : WB_MONITORING
        wb_bus.master_monitor(wb_monitor_addr, wb_monitor_data, wb_monitor_we);
        //I turned off wishbone monitor output to avoid cluttering the transcript
        //  instead logging the read/writes for the i2c and wishbone interfaces

        //uncomment the next line to get wishbone_monitor output
        //$display("Wishbone monitor    Data: 0x%h, Address: 0x%h, WE: 0x%b", wb_monitor_data, wb_monitor_addr, wb_monitor_we);
        @(posedge clk);
    end

// ****************************************************************************
// Monitor I2C bus and display transfers in the transcript

// storage variables for I2C monitoring task
bit [I2C_ADDR_WIDTH-1:0] i2c_monitor_addr;
i2c_op_t i2c_monitor_op;
bit [I2C_DATA_WIDTH-1:0] i2c_monitor_data[];

initial
    forever begin : MONITOR_I2C_BUS
        i2c_bus.monitor(i2c_monitor_addr, i2c_monitor_op, i2c_monitor_data);
        //i2c_monitor_data can be of variable length
        //  I know that it is one byte in this instance
        //  the [0] is to force the %d specifier to display
        //  an unsigned value

        if(i2c_monitor_op == WRITE)
            $display("I2C_BUS WRITE Transfer      Data: 0x%h, Address 0x%h", i2c_monitor_data, i2c_monitor_addr);
        else
            $display("I2C_BUS READ Transfer      Data: 0x%h, Address 0x%h", i2c_monitor_data, i2c_monitor_addr);
        @(posedge clk);
    end

// ****************************************************************************
// Wishbone interface control register offsets
parameter
    CSR = 2'b00,
    DPR = 2'b01,
    CMDR = 2'b10,
    FSMR = 2'b11;

// ****************************************************************************
// Define the flow of the simulation

// I2C interface input and output arguments
i2c_op_t i2c_if_op;
bit[I2C_DATA_WIDTH-1:0] i2c_if_write_data[];
bit i2c_transfer_complete;
bit [I2C_DATA_WIDTH-1:0] i2c_read_data [] = new[32];

//I2C Read/Writes
initial
    begin : TEST_FLOW_I2C
    //TEST 1: 32 incrementing values from wishbone to I2C
    i2c_bus.wait_for_i2c_transfer(i2c_if_op, i2c_if_write_data);

    //TEST 2: 32 decrementing values read from I2C

    //fill byte array transmitted to wishbone
    for(int i = 0; i < 32; i++) 
        i2c_read_data[i] = 100+i;

    // Wait for read operation
    i2c_bus.wait_for_i2c_transfer(i2c_if_op, i2c_if_write_data);
    assert(i2c_if_op == READ) else $error("Expected read request from wishbone master");
    //send data back
    i2c_bus.provide_read_data(i2c_read_data, i2c_transfer_complete);

    //TEST 3: alternating read and writes
    for(int i = 0; i < 128; i++) begin
        if(i%2 == 0) begin //reading from wishbone
            i2c_bus.wait_for_i2c_transfer(i2c_if_op, i2c_if_write_data);
        end else begin // sending data back to wishbone
            i2c_bus.wait_for_i2c_transfer(i2c_if_op, i2c_if_write_data);
            i2c_read_data[0] = 63 - ((i-1)/2);
            i2c_bus.provide_read_data(i2c_read_data, i2c_transfer_complete);
        end
    end
    end

byte to_write;
byte wb_out;

//wishbone testflow
initial
    begin : TEST_FLOW
    #1151
    //wb_bus.master_write(adr, data);
    
    //enable core with interrupts
    wb_bus.master_write(CSR, 8'b11xxxxxx);

    //set bus ID    
    wb_bus.master_write(DPR, 8'h05);
    wb_bus.master_write(CMDR, 8'bxxxxx110);

    @(!irq) wb_bus.master_read(CMDR, wb_out);

   
    //TEST 1: transmit 0 to 31 to i2c bus in one transmission
    wb_bus.master_write(CMDR, 8'bxxxxx100);
    @(!irq) wb_bus.master_read(CMDR, wb_out);
    // (slave address left shifted 1) + 0 for write
    // see OpenCores I2C spec example 3
    wb_bus.master_write(DPR, 8'h22 << 1);
    //write command
    wb_bus.master_write(CMDR, 8'bxxxxx001);
    @(!irq) wb_bus.master_read(CMDR, wb_out);
    for(int i = 0; i < 32; i++) begin
        wb_bus.master_write(DPR, i);
        wb_bus.master_write(CMDR, 8'bxxxxx001);
        $display("WISHBONE MONITOR  Sending 0x%h to I2C interface", i[7:0]);
        @(!irq) wb_bus.master_read(CMDR, wb_out);
    end
    wb_bus.master_write(CMDR, 8'bxxxx101);

    wb_bus.master_write(DPR, 8'h05);
    wb_bus.master_write(CMDR, 8'bxxxxx110);
    @(!irq) wb_bus.master_read(CMDR, wb_out);

    //TEST 2: Read 64 to 127 from I2C bus
    wb_bus.master_write(CMDR, 8'bxxxxx100);
    @(!irq) wb_bus.master_read(CMDR, wb_out);
    // (slave address left shifted 1) + 1 for write
    // see OpenCores I2C spec example 3
    wb_bus.master_write(DPR, (8'h22 << 1)+1'b1);
    //write command
    wb_bus.master_write(CMDR, 8'bxxxxx001);
    @(!irq) wb_bus.master_read(CMDR, wb_out);
    // generate read requests with ACK 31 times
    for(int i = 0; i < 31; i++) begin
        wb_bus.master_write(CMDR, 8'bxxxxx010);
        @(!irq) wb_bus.master_read(CMDR, wb_out);
        wb_bus.master_read(DPR, wb_out);
        $display("WISHBONE MONITOR  Recieved 0x%h from I2C interface", wb_out);
    end
    // generate final read request with NACK
    wb_bus.master_write(CMDR, 8'bxxxxx011);
    @(!irq) wb_bus.master_read(CMDR, wb_out);
    wb_bus.master_read(DPR, wb_out);
    $display("WISHBONE MONITOR  Recieved 0x%h from I2C interface", wb_out);

    // generate stop and clear IRQ
    wb_bus.master_write(CMDR, 8'bxxxx101);
    @(!irq) wb_bus.master_read(CMDR, wb_out);

    //TEST 3: alternating incrementing and decrementing reads and writes
    for(int i = 0; i < 128; i++) begin
        wb_bus.master_write(CMDR, 8'bxxxxx100);
        @(!irq) wb_bus.master_read(CMDR, wb_out);
        // (slave address left shifted 1) + 1 for write
        // see OpenCores I2C spec example 3
        //alternate between reading and writing
        wb_bus.master_write(DPR, (8'h22 << 1)+(i%2));
        //write operation
        wb_bus.master_write(CMDR, 8'bxxxxx001);
        @(!irq) wb_bus.master_read(CMDR, wb_out);
        if(i%2 == 0) begin // write case
            to_write = 64+(i/2);
            wb_bus.master_write(DPR, to_write);
            wb_bus.master_write(CMDR, 8'bxxxxx001);
            $display("WISHBONE MONITOR  Writing 0x%h to I2C interface", to_write);
            @(!irq) wb_bus.master_read(CMDR, wb_out);
            wb_bus.master_write(CMDR, 8'bxxxx101);
            @(!irq) wb_bus.master_read(CMDR, wb_out);
        end else begin
            wb_bus.master_write(CMDR, 8'bxxxxx011);
            @(!irq) wb_bus.master_read(CMDR, wb_out);
            wb_bus.master_read(DPR, wb_out);
            $display("WISHBONE MONITOR  Received 0x%h from I2C interface", wb_out);
            wb_bus.master_write(CMDR, 8'bxxxx101);
            @(!irq) wb_bus.master_read(CMDR, wb_out);
        end
    end
    end

// ****************************************************************************
// Instantiate the I2C slave Bus Functional Model

i2c_if      #(
    .I2C_DATA_WIDTH(I2C_DATA_WIDTH),
    .I2C_ADDR_WIDTH(I2C_ADDR_WIDTH)
    )
i2c_bus (
    .scl(scl), 
    .sda(sda)
);

// ****************************************************************************

// ****************************************************************************
// Instantiate the Wishbone master Bus Functional Model
wb_if       #(
      .ADDR_WIDTH(WB_ADDR_WIDTH),
      .DATA_WIDTH(WB_DATA_WIDTH)
      )
wb_bus (
  // System sigals
  .clk_i(clk),
  .rst_i(rst),
  // Master signals
  .cyc_o(cyc),
  .stb_o(stb),
  .ack_i(ack),
  .adr_o(adr),
  .we_o(we),
  // Slave signals
  .cyc_i(),
  .stb_i(),
  .ack_o(),
  .adr_i(),
  .we_i(),
  // Shred signals
  .dat_o(dat_wr_o),
  .dat_i(dat_rd_i),
  .irq_i(irq)
  );

// ****************************************************************************
// Instantiate the DUT - I2C Multi-Bus Controller
\work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_BUSSES)) DUT
  (
    // ------------------------------------
    // -- Wishbone signals:
    .clk_i(clk),         // in    std_logic;                            -- Clock
    .rst_i(rst),         // in    std_logic;                            -- Synchronous reset (active high)
    // -------------
    .cyc_i(cyc),         // in    std_logic;                            -- Valid bus cycle indication
    .stb_i(stb),         // in    std_logic;                            -- Slave selection
    .ack_o(ack),         //   out std_logic;                            -- Acknowledge output
    .adr_i(adr),         // in    std_logic_vector(1 downto 0);         -- Low bits of Wishbone address
    .we_i(we),           // in    std_logic;                            -- Write enable
    .dat_i(dat_wr_o),    // in    std_logic_vector(7 downto 0);         -- Data input
    .dat_o(dat_rd_i),    //   out std_logic_vector(7 downto 0);         -- Data output
    // ------------------------------------
    // ------------------------------------
    // -- Interrupt request:
    .irq(irq),           //   out std_logic;                            -- Interrupt request
    // ------------------------------------
    // ------------------------------------
    // -- I2C interfaces:
    .scl_i(scl),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
    .sda_i(sda),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
    .scl_o(scl),         //   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
    .sda_o(sda)          //   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
    // ------------------------------------
  );


endmodule
