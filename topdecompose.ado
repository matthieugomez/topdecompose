* version 2.0, March 2028
* 1. Instead of returning only the time variable at period 1, return it at both period 0 (with
*    suffix 0) and period 1 (with suffix 1), to make the start and end times more obvious.
* 2. When using the details option, use uppercase for group sizes (e.g., N0) since n is used to denote 
*.   relative mass in the paper.
* 3. Return an error if the dataset is not tsset. Note that multiple time periods are allowed,
*    although in the top-shares section I apply this repeatedly to datasets with only two periods
*    (pre and post), in order to exclude specific observations at different time periods.


program define topdecompose
	syntax varlist(max=1 numeric), [top(varname numeric) prefix(string) save(string) replace clear Detail]

	/* 0: Check Inputs */
	qui tsset
	local id `r(panelvar)'
	local time  `r(timevar)'
	if "`id'" == "" | "`time'" == ""{
		di as error "The dataset must be declared as a panel before applying the decomposition (e.g. tsset panelvariable timevariable)"
		exit 198
	}
	local delta = r(tdelta)

	if "`detail'"!=""{
		if inlist("`time'", "N_P"){
			di as error "The name of the time variable will conflict with variables created in the decomposition"
			exit 198
		}
		if inlist("`time'", "w0_P", "w1_P", "q"){
			di as error "The name of the time variable will conflict with variables created in the decomposition"
			exit 198
		}
	}

	if "`save'`clear'" == ""{
		di as error "You need to specify either the option save(filename) or the option clear. The first saves the output in an external file while the second replaces the existing dataset."
		exit 198
	}

	cap assert inlist(`top', 0 , 1, .)
	if _rc{
		di as error "The variable `top' must only take values 1 (in the top percentile), 0 (below the top percentile), or missing (not in the economy)."
		exit 198
	}

	cap assert `varlist' != .  if `top' == 1
	if _rc{
		di as error `"The variable "`varlist'" must not be missing for an individual in the top"'
		exit 198
	}

	cap assert `varlist' != .  if  (L.`top' == 1) & !missing(`top')
	if _rc{
		di as error `"The variable "`varlist'" must not be missing for an individual in the economy (with non missing top variable) that was in the top in the previous period (with lagged top variable equal to one)"'
		exit 198
	}



	local varlabel : variable label `varlist'
	if "`varlabel'" == "" local varlabel `varlist'

	preserve
	tempfile temp
	qui save `temp'
	tempvar set N w0 w1 q0 q1

	/* 1: Decomposing average at P0 */
	qui gen `set' = "P0minusD" if `top' == 1 & F.`top' != .
	qui replace `set' = "D" if `top' == 1 & F.`top' == .
	qui drop if missing(`set')
	qui collapse (count) `N' = `varlist' (mean) `w0' = `varlist', by(`time' `set')
	qui reshape wide `N' `w0', i(`time') j(`set') string
	* Handle the fact that, when sets are empty, variables may not exist (always empty) or be missing
	foreach suffix in P0minusD D{
		cap confirm variable `N'`suffix'
		if _rc{
			qui gen `N'`suffix' = .
			qui gen `w0'`suffix' = .
		}
		qui replace `N'`suffix' = 0 if `N'`suffix' == .
		qui replace `w0'`suffix' = 0 if `N'`suffix' == 0
	}
	qui replace `time' = `time' + `delta'
	tempfile temp0
	qui save `temp0'

	/* 2: Decomposing average at P1 */
	qui use `temp', clear
	qui gen `set' = "P1capP0" if `top' == 1 & L.`top' == 1
	qui replace `set' = "I" if `top' == 1 & L.`top' == 0
	qui replace `set' = "B" if `top' == 1 & L.`top' == .
	qui replace `set' = "O" if `top' == 0 & L.`top' == 1
	qui drop if missing(`set')
	qui collapse (count) `N' = `varlist' (mean) `w1' = `varlist', by(`time' `set')
	qui reshape wide `N' `w1', i(`time') j(`set') string
	* Handle the fact that, when sets are empty, variables may not exist (always empty) or be missing
	foreach suffix in P1capP0 I B O{
		cap confirm variable `N'`suffix'
		if _rc{
			qui gen `N'`suffix' = .
			qui gen `w1'`suffix' = .
		}
		qui replace `N'`suffix' = 0 if `N'`suffix' == .
		qui replace `w1'`suffix' = 0 if `N'`suffix' == 0
	}
	tempfile temp1
	qui save `temp1'

	/* 3: Compute quantiles q0 and q1 */
	qui use `temp', clear
	qui gen `set' = "P1" if `top' == 1
	qui replace `set' = "notP1" if `top' == 0
	qui drop if missing(`set')
	qui collapse  (min) `w1'min = `varlist' (max) `w1'max = `varlist', by(`time' `set')
	qui reshape wide `w1'min `w1'max, i(`time') j(`set') string

	* case where top = 1 for everyone
	cap confirm variable `w1'maxnotP1
	if !_rc{
		cap assert `w1'minP1 >= `w1'maxnotP1 if !missing(`w1'maxnotP1)
		if _rc{
			di as error `"The variable "`varlist'" should have a lower value for individuals out of the top  (i.e. with "`top' == 0") than for individuals in the top (i.e. with "`top' == 1")"'
			exit 198
		}
	}
	qui rename `w1'minP1 `q1'
	qui keep `time' `q1'
	* Save copy to compute q0 (threshold at previous period)
	tempfile tempq
	qui save `tempq'
	qui rename `q1' `q0'
	qui replace `time' = `time' + `delta'
	tempfile tempq0
	qui save `tempq0'
	* Reload and keep q1 (threshold at current period)
	qui use `tempq', clear
	qui sum `time'
	qui drop if `time' == r(min)
	* Merge q0
	qui merge 1:1 `time' using `tempq0', keep(master matched) nogen

	/* 4: combine everything together */
	qui merge 1:1 `time' using `temp0', keep(master matched) nogen
	qui merge 1:1 `time' using `temp1', keep(master matched) nogen
	qui gen `N'P0 = `N'P0minusD + `N'D
	cap assert `N'P0 > 0
	if _rc{
		di as error `"There should always be at least one individual in the top (i.e. with "`top' == 1")"'
		exit 198
	}
	qui gen `w0'P0 = (`N'P0minusD * `w0'P0minusD + `N'D * `w0'D) / `N'P0
	qui gen `N'P1 = `N'P1capP0 + `N'I + `N'B
	qui gen `w1'P1 = (`N'P1capP0 * `w1'P1capP0 + `N'I * `w1'I + `N'B * `w1'B) / `N'P1
	qui gen `w1'P0minusD = (`N'O * `w1'O  + `N'P1capP0 * `w1'P1capP0) / (`N'O + `N'P1capP0)
	qui gen `prefix'total = `w1'P1 / `w0'P0 - 1
	qui gen `prefix'within = `w1'P0minusD / `w0'P0minusD - 1
	qui gen `prefix'inflow = `N'I / `N'P1 * (`w1'I - `q1') / `w0'P0
	qui gen `prefix'outflow = `N'O / `N'P1 * (`q1' - `w1'O) / `w0'P0
	qui gen `prefix'birth = `N'B / `N'P1 * (`w1'B - `q1') / `w0'P0
	qui gen `prefix'death = `N'D / `N'P1 * (`q1' - (`w1'P0minusD / `w0'P0minusD) * `w0'D) / `w0'P0
	qui gen `prefix'popgrowth = (`N'P1 - `N'P0) / `N'P1 * (`q1' - (`w1'P0minusD / `w0'P0minusD) * `w0'P0) / `w0'P0
	gen `prefix'between = `prefix'inflow + `prefix'outflow
	gen `prefix'demography = `prefix'birth + `prefix'death + `prefix'popgrowth

	/* 5: test terms sum to total */
	cap assert abs(`prefix'total - (`prefix'within + `prefix'between + `prefix'demography)) < 1e-6
	if _rc{
		di as error "Terms do not sum to the growth of the average wealth in the top percentile. This should never happen: please file an issue at https://github.com/matthieugomez/topdecompose"
		exit 198
	}

	gen `time'0 = `time' - `delta'
	gen `time'1 = `time'

	/* 6: label and return results */
	label variable `time'0 "Start of period"
	label variable `time'1 "End of period"
	label variable `prefix'total "Total growth"
	label variable `prefix'within "Within component"
	label variable `prefix'between "Between component (inflow + outflow)"
	label variable `prefix'inflow "Inflow component"
	label variable `prefix'outflow "Outflow component"
	label variable `prefix'demography "Demography component (birth + death + popgrowth)"
	label variable `prefix'birth "Birth component"
	label variable `prefix'death "Death component"
	label variable `prefix'popgrowth "Population growth component"

	if "`detail'" == ""{
		qui keep `time'0 `time'1 `prefix'total `prefix'within `prefix'between `prefix'inflow `prefix'outflow `prefix'demography  `prefix'birth `prefix'death `prefix'popgrowth
		qui order `time'0 `time'1 `prefix'total `prefix'within `prefix'between `prefix'inflow `prefix'outflow  `prefix'demography `prefix'birth `prefix'death `prefix'popgrowth
	}
	else{
		foreach suffix in P0 D{
			qui rename `w0'`suffix'  w0_`suffix'
			qui rename `N'`suffix'  N_`suffix'
		}
		foreach suffix in I O B P1{
			qui rename `w1'`suffix' w1_`suffix'
			qui rename `N'`suffix' N_`suffix'
		}
		qui rename `q0' q0
		qui rename `q1' q1
		label variable N_P0 "Number in top at t=0"
		label variable N_P1 "Number in top at t=1"
		label variable N_I "Number of inflows"
		label variable N_O "Number of outflows"
		label variable N_B "Number of births"
		label variable N_D "Number of deaths"
		label variable w0_P0 "Average `varlabel' in top at t=0"
		label variable w1_P1 "Average `varlabel' in top at t=1"
		label variable w1_I "Average `varlabel' at t=1 for inflows"
		label variable w1_O "Average `varlabel' at t=1 for outflows"
		label variable w1_B "Average `varlabel' at t=1 for births"
		label variable w0_D "Average `varlabel' at t=0 for deaths"
		label variable q0 "Percentile threshold at t=0"
		label variable q1 "Percentile threshold at t=1"
		qui keep `time'0 `time'1 `prefix'total `prefix'within `prefix'between `prefix'inflow `prefix'outflow `prefix'demography  `prefix'birth `prefix'death `prefix'popgrowth N_P0 w0_P0 N_I w1_I N_O w1_O N_B w1_B N_D w0_D N_P1 w1_P1 q0 q1
		qui order `time'0 `time'1 `prefix'total `prefix'within `prefix'between `prefix'inflow `prefix'outflow `prefix'demography  `prefix'birth `prefix'death `prefix'popgrowth N_P0 w0_P0 N_I w1_I N_O w1_O N_B w1_B N_D w0_D N_P1 w1_P1 q0 q1
	}
	if "`save'" != ""{
		qui save `save', `replace'
		restore
	}
	else{
		restore, not
	}
end
