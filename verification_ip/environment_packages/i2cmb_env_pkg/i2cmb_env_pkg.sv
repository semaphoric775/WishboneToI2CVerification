package i2cmb_env_pkg;
    import ncsu_pkg::*;
    `include "../../ncsu_pkg/ncsu_macros.svh"
    import i2c_pkg::*;
    import wb_pkg::*;

    `include "src/i2cmb_env_configuration.svh"
    `include "src/i2cmb_predictor.svh"
    `include "src/i2cmb_coverage.svh"
    `include "src/i2cmb_scoreboard.svh"
    `include "src/i2cmb_generator.svh"
    `include "src/i2cmb_environment.svh"
    `include "src/i2cmb_test_base.svh"
    `include "src/i2cmb_test_regs.svh"
endpackage
