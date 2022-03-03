package wb_pkg;

    import ncsu_pkg::*;
    //evil hacky relative paths to fix compilation error
    //the Makefile in proj_2/sim/ should include the ncsu_macros file without issue
    //compiling does not work in this case
    `include "../../ncsu_pkg/ncsu_macros.svh"

    `include "src/wb_transaction.svh"
    `include "src/wb_reg_defines.svh"
    `include "src/wb_configuration.svh"
    `include "src/wb_driver.svh"
    `include "src/wb_monitor.svh"
    `include "src/wb_agent.svh"
endpackage
