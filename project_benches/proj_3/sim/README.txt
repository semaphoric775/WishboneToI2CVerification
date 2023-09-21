To run full test_suite
add questa2020.4
./testlist.sh
make merge_coverage_with_test_plan


Project notes:
    Most coverage is gathered when the DUT is run with fastest configuration (no polling)
    It would be better to fully test the DUT in every configuration, but out of consideration
    for computing power and time constraints, this is tested to a limited extent
    FSM coverage is also only tested with valid I2C devices, so a few valid states will not be reached
