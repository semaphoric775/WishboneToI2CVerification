make clean compile optimize
make run_cli TESTNAME=i2cmb_test_base TEST_SEED=2022 MAX_SEQ=200
make run_cli TESTNAME=i2cmb_test_base TEST_SEED=12345 MAX_SEQ=200
make run_cli TESTNAME=i2cmb_test_base TEST_SEED=745 MAX_SEQ=50
make run_cli TESTNAME=i2cmb_test_base TEST_SEED=13 MAX_SEQ=5
make run_cli TESTNAME=i2cmb_test_base TEST_SEED=62 MAX_SEQ=4
make run_directed_test_cli  TESTNAME=i2cmb_test_regs
