* =============================================================================
* Example: Decomposing the growth of average wealth in the Forbes 400
* =============================================================================
*
* The Forbes 400 lists the 400 wealthiest Americans each year.
* This example decomposes the year-over-year growth of average wealth
* in the Forbes 400 into within, between, and demography components.
*
* The data (forbes400_2011_2017.csv) is an unbalanced panel with columns:
*   year, rank, networth, top, name
* where top = 1 if on the Forbes 400, top = 0 if not on the list but still
* in the economy (with networth if known), and the individual is absent from
* the panel if they have exited the economy (e.g., death).
*
* =============================================================================

import delimited "forbes400_2011_2017.csv", clear

* Create numeric person ID
egen id = group(name)

* -----------------------------------------------------------------------------
* List individuals in each group for the 2011 → 2012 transition
* -----------------------------------------------------------------------------
tsset id year

* Stayers: top=1 in both 2011 and 2012
di _newline "=== STAYERS (top=1 in 2011 and top=1 in 2012) ==="
list name networth if year == 2012 & top == 1 & L.top == 1 in 1/10, noobs

* Inflow: top=0 in 2011, top=1 in 2012
di _newline "=== INFLOW (top=0 in 2011, top=1 in 2012) ==="
list name networth if year == 2012 & top == 1 & L.top == 0, noobs

* Outflow: top=1 in 2011, top=0 in 2012
di _newline "=== OUTFLOW (top=1 in 2011, top=0 in 2012) ==="
list name networth if year == 2012 & top == 0 & L.top == 1, noobs

* Death: top=1 in 2011, top=. in 2012 (or no observation in 2012)
di _newline "=== DEATH (top=1 in 2011, no observation in 2012) ==="
list name networth if year == 2011 & top == 1 & F.top == ., noobs

* Birth: top=. in 2011  (or no observation in 2011), top=1 in 2012
di _newline "=== BIRTH (no observation in 2011, top=1 in 2012) ==="
list name networth if year == 2012 & top == 1 & L.top == ., noobs

* -----------------------------------------------------------------------------
* Run the decomposition for the average welath in Forbes 400
* Note that, since the Forbes 400 always contains exactly 400 individuals,
* the population growth term is always zero.
* -----------------------------------------------------------------------------
topdecompose networth, top(top) prefix(g_) clear
format g_* %9.3f

desc

twoway (scatter g_total year1, connec(l) msize(small) color(black) msymbol(circle) lwidth(medthick)) (scatter g_within year1, connec(l) msize(small) color("68 118 170") msymbol(triangle)) (scatter g_between year1, connec(l) msize(small) color("204 102 119") msymbol(diamond)) (scatter g_demography year1, connec(l) msize(small) color("221 170 51") msymbol(plus)), ytitle("Growth") ylabel(-0.2 "-20%" -0.1 "-10%" 0 "0%" 0.1 "10%" 0.2 "20%" 0.3 "30%") xtitle("Year") legend(pos(6) rows(1))