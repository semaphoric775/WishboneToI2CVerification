`timescale 1ns / 10ps

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
	#113	rst=1'b0;
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
	$display("Wishbone monitor	Data: 0x%h, Address: 0x%h, WE: 0x%b", wb_monitor_data, wb_monitor_addr, wb_monitor_we);
	@(posedge clk);
	end

// ****************************************************************************
// Define the flow of the simulation

parameter
	CSR = 2'b00,
	DPR = 2'b01,
	CMDR = 2'b10,
	FSMR = 2'b11;

logic [WB_DATA_WIDTH-1:0] wb_out;

//task wait_for_i2c_transfer(output i2c_op_t op, output bit[I2C_DATA_WIDTH-1:0] write_data[]);
bit i2c_if_op;
bit[I2C_DATA_WIDTH-1:0] i2c_if_write_data[];

//i2c testflow
initial
	begin : TEST_FLOW_I2C
	    i2c_bus.wait_for_i2c_transfer(i2c_if_op, i2c_if_write_data);
	    $display("Completed I2C wait task");
	end

//wishbone testflow
initial
	begin : TEST_FLOW
	#1151
	//wb_bus.master_write(adr, data);
	
	//example 6-1
	wb_bus.master_write(CSR, 8'b11xxxxxx);

	//example 6-3
	wb_bus.master_write(DPR, 8'h05);
	wb_bus.master_write(CMDR, 8'bxxxxx110);

	@(!irq) wb_bus.master_read(CMDR, wb_out);

	//start command
	wb_bus.master_write(CMDR, 8'bxxxxx100);

	@(!irq) wb_bus.master_read(CMDR, wb_out);

	wb_bus.master_write(DPR, 8'h44);
	//write command
	wb_bus.master_write(CMDR, 8'bxxxxx001);

	@(!irq) wb_bus.master_read(CMDR, wb_out);

	wb_bus.master_write(DPR, 8'h78);
	wb_bus.master_write(CMDR, 8'bxxxxx001);
	@(!irq) wb_bus.master_read(CMDR, wb_out);

	wb_bus.master_write(CMDR, 8'bxxxx101);
	@(!irq) wb_bus.master_read(CMDR, wb_out);
	end

// ****************************************************************************
// Instantiate the I2C slave Bus Functional Model

i2c_if	    #(
	.I2C_DATA_WIDTH(I2C_DATA_WIDTH),
	.I2C_ADDR_WIDTH(I2C_ADDR_WIDTH),
	.I2C_DEVICE_ADDR(8'h22)
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
  .dat_i(dat_rd_i)
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
