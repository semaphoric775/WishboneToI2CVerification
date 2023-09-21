export ECE745_PROJECT_HOME ?= $(PWD)/../../..

include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/environment_packages/i2cmb_env_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/ncsu_pkg/Makefile

TEST_SEED ?= 12345
TESTNAME ?= i2cmb_test_base
MAX_SEQ ?= 100

clean: 
	rm -rf work *.wlf transcript

comp_I2C_MB:
	vcom ../rtl/iicmb_int_pkg.vhd
	vcom ../rtl/iicmb_pkg.vhd
	vcom -cover f ../rtl/mbyte.vhd
	vcom -cover f ../rtl/mbit.vhd
	vcom ../rtl/bus_state.vhd
	vcom ../rtl/filter.vhd
	vcom ../rtl/conditioner.vhd
	vcom ../rtl/conditioner_mux.vhd
	vcom ../rtl/iicmb_m.vhd
	vcom ../rtl/regblock.vhd
	vcom ../rtl/wishbone.vhd
	vcom -cover sbceft ../rtl/iicmb_m_wb.vhd

comp_bench: comp_ncsu_pkg comp_wb_pkg comp_i2c_pkg comp_i2cmb_env_pkg 
	vlog ../testbench/top.sv

optimize:
	vopt +acc top -o optimized_debug_top_tb

compile: comp_I2C_MB comp_bench optimize

run_gui:
	vsim -sv_seed $(TEST_SEED) -i -classdebug -msgmode both -do "set NoQuitOnFinish 1; do wave.do" +TESTNAME=$(TESTNAME) +MAX_SEQ=$(MAX_SEQ) optimized_debug_top_tb &

run_cli:
	vsim  -coverage -c -sv_seed $(TEST_SEED) -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(TESTNAME)_$(TEST_SEED); coverage save $(TESTNAME).$(TEST_SEED).ucdb; quit -f" +TESTNAME=$(TESTNAME) +MAX_SEQ=$(MAX_SEQ) optimized_debug_top_tb

run_directed_test_cli:
	vsim  -coverage -c -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(TESTNAME); coverage save $(TESTNAME).ucdb; quit -f" +TESTNAME=$(TESTNAME) +MAX_SEQ=$(MAX_SEQ) optimized_debug_top_tb


cli: clean compile optimize run_cli

debug: clean compile optimize run_gui

convert_testplan:
	xml2ucdb -format Excel ../../../docs/i2cmb_test_plan.xml ./i2mcb_test_plan.ucdb
	add testbrowser ./*.udcb

merge_coverage:
	vcover merge -stats=none -strip -totals sim_and_testplan_merged.ucdb ./*.ucdb

report_coverage:
	vcover report -details -html -htmldir covhtmlreport -assert -directive -cvg -code bcefst -threshL 50 -threshH 90 ./sim_and_testplan_merged.ucdb

merge_coverage_with_test_plan:
	vsim -do load_ucdbs_and_merge_with_test_plan.do
