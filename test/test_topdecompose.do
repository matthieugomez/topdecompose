* =============================================================================
* Tests for topdecompose
* =============================================================================

clear all
set more off

* -----------------------------------------------------------------------------
* Test 1: Basic decomposition on synthetic data
* Verify that total = within + between + demography
* -----------------------------------------------------------------------------
di _newline "=== Test 1: Basic decomposition ==="
clear
set seed 12345
set obs 200
gen id = _n
expand 3
bys id: gen year = 2000 + _n - 1
* Drop some observations to create an unbalanced panel (births/deaths)
drop if runiform() < 0.05
gen wealth = 10 + 5 * runiform()
bys year (wealth): gen top = _n >= 0.9 * _N
tsset id year
topdecompose wealth, top(top) clear detail
* Check decomposition identity
gen diff = abs(total - (within + between + demography))
assert diff < 1e-6
* Check sub-components
gen diff2 = abs(between - (inflow + outflow))
assert diff2 < 1e-6
gen diff3 = abs(demography - (birth + death + popgrowth))
assert diff3 < 1e-6
di "Test 1 passed"

* -----------------------------------------------------------------------------
* Test 2: Balanced panel (no births/deaths)
* Demography terms should be zero
* -----------------------------------------------------------------------------
di _newline "=== Test 2: Balanced panel ==="
clear
set seed 12345
set obs 100
gen id = _n
expand 3
bys id: gen year = 2000 + _n - 1
gen wealth = 10 + 5 * runiform()
bys year (wealth): gen top = _n >= 0.9 * _N
tsset id year
topdecompose wealth, top(top) clear detail
assert abs(birth) < 1e-10
assert abs(death) < 1e-10
assert abs(popgrowth) < 1e-10
assert abs(demography) < 1e-10
di "Test 2 passed"

* -----------------------------------------------------------------------------
* Test 3: Prefix option
* Verify output variables have the specified prefix
* -----------------------------------------------------------------------------
di _newline "=== Test 3: Prefix option ==="
clear
set seed 12345
set obs 100
gen id = _n
expand 2
bys id: gen year = 2000 + _n - 1
gen wealth = 10 + 5 * runiform()
bys year (wealth): gen top = _n >= 0.9 * _N
tsset id year
topdecompose wealth, top(top) prefix(w_) clear
confirm variable w_total
confirm variable w_within
confirm variable w_between
confirm variable w_inflow
confirm variable w_outflow
confirm variable w_demography
confirm variable w_birth
confirm variable w_death
confirm variable w_popgrowth
di "Test 3 passed"

* -----------------------------------------------------------------------------
* Test 4: Save option
* Verify output is saved to file and original data preserved
* -----------------------------------------------------------------------------
di _newline "=== Test 4: Save option ==="
clear
set seed 12345
set obs 100
gen id = _n
expand 2
bys id: gen year = 2000 + _n - 1
gen wealth = 10 + 5 * runiform()
bys year (wealth): gen top = _n >= 0.9 * _N
tsset id year
local N_before = _N
topdecompose wealth, top(top) save("/tmp/topdecompose_test.dta") replace
* Original data should be preserved
assert _N == `N_before'
confirm variable wealth
* Saved file should exist and contain the decomposition
preserve
use "/tmp/topdecompose_test.dta", clear
confirm variable total
confirm variable within
restore
di "Test 4 passed"

* -----------------------------------------------------------------------------
* Test 5: Error when dataset is not tsset
* -----------------------------------------------------------------------------
di _newline "=== Test 5: Error when not tsset ==="
clear
set obs 10
gen id = _n
gen year = 2000
gen wealth = runiform()
gen top = _n > 5
cap topdecompose wealth, top(top) clear
assert _rc != 0
di "Test 5 passed"

* -----------------------------------------------------------------------------
* Test 6: Error when top has invalid values
* -----------------------------------------------------------------------------
di _newline "=== Test 6: Error when top has invalid values ==="
clear
set obs 100
gen id = _n
expand 2
bys id: gen year = 2000 + _n - 1
gen wealth = runiform()
gen top = 2
tsset id year
cap topdecompose wealth, top(top) clear
assert _rc != 0
di "Test 6 passed"

* -----------------------------------------------------------------------------
* Test 7: Forbes 400 example runs without error
* -----------------------------------------------------------------------------
di _newline "=== Test 7: Forbes 400 example ==="
* Run from the repo root: stata-mp -b do test/test_topdecompose.do
import delimited "example/forbes400_2011_2017.csv", clear
egen id = group(name)
tsset id year
topdecompose networth, top(top) clear detail
* Should have 6 transition periods (2011-2012, ..., 2016-2017)
assert _N == 6
* Population growth should be zero (always 400 individuals)
assert abs(popgrowth) < 1e-10
* Decomposition identity
gen diff = abs(total - (within + between + demography))
assert diff < 1e-6
di "Test 7 passed"

* -----------------------------------------------------------------------------
di _newline "=== All tests passed ==="
