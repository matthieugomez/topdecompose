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
* Test 8: Frequency weights
* Weighting by an integer equals duplicating observations; weights that vary
* over time within an individual are rejected
* -----------------------------------------------------------------------------
di _newline "=== Test 8: Frequency weights ==="
clear
set seed 12345
set obs 200
gen id = _n
gen wt = 1 + floor(3 * runiform())
expand 3
bys id: gen year = 2000 + _n - 1
drop if runiform() < 0.05
gen wealth = 10 + 5 * runiform()
bys year (wealth): gen top = _n >= 0.9 * _N
tsset id year
tempfile weighted
topdecompose wealth [fw=wt], top(top) save(`weighted') detail
* Same decomposition on the dataset where each individual is duplicated wt times
expand wt
bys id year: gen copy = _n
egen id2 = group(id copy)
tsset id2 year
topdecompose wealth, top(top) clear detail
foreach v in total within inflow outflow birth death popgrowth N_P0 N_P1 {
	rename `v' dup_`v'
}
merge 1:1 year1 using `weighted', assert(match) nogen
foreach v in total within inflow outflow birth death popgrowth N_P0 N_P1 {
	assert reldif(`v', dup_`v') < 1e-6
}
* Time-varying weights are rejected
clear
set obs 100
gen id = _n
expand 2
bys id: gen year = 2000 + _n - 1
gen wealth = runiform()
bys year (wealth): gen top = _n >= 0.9 * _N
gen wt = 1 + (year == 2001)
tsset id year
cap topdecompose wealth [fw=wt], top(top) clear
assert _rc == 198
di "Test 8 passed"

* -----------------------------------------------------------------------------
* Test 9: top0() and top1()
* top(x) is the same as top0(x) top1(x); with different variables, the result is the same as
* running each period separately with the top at t-1 given by top0 and the top at t by top1
* -----------------------------------------------------------------------------
di _newline "=== Test 9: top0() and top1() ==="
clear
set seed 12345
set obs 300
gen id = _n
expand 6
bys id: gen year = 2000 + _n - 1
drop if runiform() < 0.08
gen wealth = exp(rnormal())
bys year (wealth): gen top0 = _n > 0.85 * _N
bys year (wealth): gen top1 = _n > 0.80 * _N
* some individuals are excluded from the period ending at t
replace top1 = . if runiform() < 0.03
tsset id year
tempfile data both short
save `data'
topdecompose wealth, top(top0) detail save(`short')
topdecompose wealth, top0(top0) top1(top0) detail clear
cf _all using `short'
use `data', clear
topdecompose wealth, top0(top0) top1(top1) detail save(`both')
forval y = 2001/2005 {
	use `data', clear
	keep if inlist(year, `y' - 1, `y')
	gen top = cond(year == `y' - 1, top0, top1)
	tsset id year
	tempfile p`y'
	topdecompose wealth, top(top) detail save(`p`y'')
}
clear
forval y = 2001/2005 {
	append using `p`y''
}
foreach v of varlist total-q1 {
	rename `v' loop_`v'
}
merge 1:1 year1 using `both', assert(match) nogen
foreach v of varlist total-q1 {
	assert reldif(`v', loop_`v') < 1e-10
}
* top() cannot be combined with top0() or top1(), and top0() needs top1()
use `data', clear
cap topdecompose wealth, top(top0) top1(top1) clear
assert _rc == 198
cap topdecompose wealth, top0(top0) clear
assert _rc == 198
di "Test 9 passed"

* -----------------------------------------------------------------------------
* Test 10: by()
* Same results as running the decomposition separately within each group, including for
* individuals who move between groups (they exit one group and enter the other)
* -----------------------------------------------------------------------------
di _newline "=== Test 10: by() ==="
clear
set seed 12345
set obs 300
gen id = _n
expand 4
bys id: gen year = 2000 + _n - 1
gen wealth = exp(rnormal())
gen str1 grp = cond(runiform() < 0.5, "a", "b")
bys grp year (wealth): gen top = _n > 0.85 * _N
tsset id year
tempfile data res
save `data'
topdecompose wealth, top(top) by(grp) detail save(`res')
foreach g in a b {
	use `data', clear
	keep if grp == "`g'"
	tsset id year
	tempfile r`g'
	topdecompose wealth, top(top) detail clear
	gen grp = "`g'"
	save `r`g''
}
use `ra', clear
append using `rb'
foreach v of varlist total-q1 {
	rename `v' sep_`v'
}
merge 1:1 grp year1 using `res', assert(match) nogen
foreach v of varlist total-q1 {
	assert reldif(`v', sep_`v') < 1e-10 | (missing(`v') & missing(sep_`v'))
}
di "Test 10 passed"

* -----------------------------------------------------------------------------
* Test 11: the data in memory is left untouched when the command stops with an error
* -----------------------------------------------------------------------------
di _newline "=== Test 11: data untouched on error ==="
clear
set seed 12345
set obs 100
gen id = _n
expand 3
bys id: gen year = 2000 + _n - 1
gen wealth = runiform()
bys year (wealth): gen top = _n >= 0.9 * _N
* the top is not the top in 2001
replace top = 1 - top if year == 2001
tsset id year
datasignature
local sig `r(datasignature)'
cap topdecompose wealth, top(top) clear
assert _rc == 198
datasignature
assert "`r(datasignature)'" == "`sig'"
di "Test 11 passed"

* -----------------------------------------------------------------------------
di _newline "=== All tests passed ==="
