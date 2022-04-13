xml2ucdb -format Excel /afs/unity.ncsu.edu/users/e/epmurphy/Documents/ece745proj/docs/i2cmb_test_plan.xml i2cmb_test_plan.ucdb
add testbrowser /afs/unity.ncsu.edu/users/e/epmurphy/Documents/ece745proj/project_benches/proj_3/sim/i2cmb_test_base.12345.ucdb
add testbrowser /afs/unity.ncsu.edu/users/e/epmurphy/Documents/ece745proj/project_benches/proj_3/sim/i2cmb_test_regs.12345.ucdb
add testbrowser /afs/unity.ncsu.edu/users/e/epmurphy/Documents/ece745proj/project_benches/proj_3/sim/i2cmb_test_plan.ucdb
vcover merge -stats=none -strip 0 -totals merge.ucdb /afs/unity.ncsu.edu/users/e/epmurphy/Documents/ece745proj/project_benches/proj_3/sim/i2cmb_test_plan.ucdb /afs/unity.ncsu.edu/users/e/epmurphy/Documents/ece745proj/project_benches/proj_3/sim/i2cmb_test_base.12345.ucdb /afs/unity.ncsu.edu/users/e/epmurphy/Documents/ece745proj/project_benches/proj_3/sim/i2cmb_test_regs.12345.ucdb
add testbrowser /afs/unity.ncsu.edu/users/e/epmurphy/Documents/ece745proj/project_benches/proj_3/sim/merge.ucdb
