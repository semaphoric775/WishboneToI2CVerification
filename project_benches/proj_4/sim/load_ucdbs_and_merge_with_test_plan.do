xml2ucdb -format Excel ../../../docs/i2cmb_test_plan.xml ./i2cmb_test_plan.ucdb
add testbrowser ./*.ucdb

vcover merge -stats=none -strip -totals sim_and_testplan_merged.ucdb ./*.ucdb
add testbrowser sim_and_testplan_merged.ucdb
