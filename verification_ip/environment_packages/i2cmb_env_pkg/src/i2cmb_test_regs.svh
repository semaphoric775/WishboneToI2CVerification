import wb_pkg::*;

class i2cmb_test_regs extends ncsu_component;

    virtual wb_if bus;
    //shorthands for wishbone register offsets
    parameter CSR=2'b00;
    parameter DPR=2'b01;
    parameter CMDR=2'b10;
    parameter FSMR=2'b11;

    bit[7:0] wb_out;

    function new(string name = "", ncsu_component_base  parent = null);
        super.new(name, parent);
    endfunction

    virtual task run();
        if ( !(ncsu_config_db#(virtual wb_if)::get("tst.env.wb_agent", this.bus))) begin
            $display("wb_agent::ncsu_config_db::get() call for BFM handle failed for name: %s ",get_full_name());
        end
        $display("I2CMB_TEST_REGS: Acquired handle to Wishbone bus");

        bus.wait_for_reset();
        bus.reset_bus();

        $display("I2CMB_TEST_REGS: Checking default register values");
        bus.master_read(CSR, wb_out);
        assert(wb_out == 8'h00) else begin
            ncsu_errors++;
            $display("I2CMB_TEST_REGS: CSR Default Value Wrong");
        end

        bus.master_read(DPR, wb_out);
        assert(wb_out == 8'h00) else begin
            ncsu_errors++;
            $display("I2CMB_TEST_REGS: DPR Default Value Wrong");
        end

        bus.master_read(CMDR, wb_out);
        assert(wb_out == 8'h80) else begin
            ncsu_errors++;
            $display("I2CMB_TEST_REGS: CMDR Default Value Wrong");
        end

        bus.master_read(FSMR, wb_out);
        assert(wb_out == 8'h00) else begin
            ncsu_errors++;
            $display("I2CMB_TEST_REGS: FSMR Default Value Wrong");
        end

        $display("I2CMB_TEST_REGS: Register Default Values Pass");

        $display("I2CMB_TEST_REGS: Testing CSR Write Permissions at Startup");
        bus.master_write(CSR, 8'b00111111);
        bus.master_read(CSR, wb_out);
        assert(wb_out == 8'h00) else begin
            ncsu_errors++;
            $display("I2CMB_TEST_REGS: CSR Bit Permissions at Startup Incorrect");
        end

        $display("I2CMB_TEST_REGS: CSR[5:0] correctly RO before core startup");

        $display("*----------------------------------------------*");
        $display("Tests Finished");
        $display("Warnings %d, Errors %d, Fatals, %d", ncsu_warnings, ncsu_errors, ncsu_fatals);
        if((ncsu_warnings == 0) && (ncsu_errors == 0) && (ncsu_fatals == 0)) $display("ALL TESTS PASSED");
        else $display("TESTS FAILED OR WARNINGS TRIGGERED");
        $display("*----------------------------------------------*");
        $finish;
    endtask
endclass