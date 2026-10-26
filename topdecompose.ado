* version 2.2.1, October 2026
* 4. New options top0() and top1(), an alternative to top() for when the top at t differs depending
*    on whether t is the start or the end of a period (e.g. individuals excluded from one specific period,
*    or a top whose size is set period by period). top(x) is the same as top0(x) top1(x).
* 5. New option by(): the decomposition is computed separately within each group.
* 6. The computation keeps only the variables it needs. The dataset in memory is restored at the end,
*    and when the command stops with an error.
* 1. Instead of returning only the time variable at period 1, return it at both period 0 (with
*    suffix 0) and period 1 (with suffix 1), to make the start and end times more obvious.
* 2. When using the details option, use uppercase for group sizes (e.g., N0) since n is used to denote
*.   relative mass in the paper.
* 3. Return an error if the dataset is not tsset. Note that multiple time periods are allowed,
*    although in the top-shares section I apply this repeatedly to datasets with only two periods
*    (pre and post), in order to exclude specific observations at different time periods.


program define topdecompose
	version 11.2
	syntax varlist(max=1 numeric) [fweight], [top(varname numeric) top0(varname numeric) top1(varname numeric) by(varlist) prefix(string) save(string) replace clear Detail]

	/* 0: Check Inputs */
	cap qui tsset
	if _rc{
		di as error "The dataset must be declared as a panel before applying the decomposition (e.g. tsset panelvariable timevariable)"
		exit 198
	}
	local id = r(panelvar)
	local time = r(timevar)
	local delta = r(tdelta)
	if "`id'" == "" | "`time'" == ""{
		di as error "The dataset must be declared as a panel before applying the decomposition (e.g. tsset panelvariable timevariable)"
		exit 198
	}

	if "`detail'"!="" & inlist("`time'", "N_P", "w0_P", "w1_P", "q"){
		di as error "The name of the time variable will conflict with variables created in the decomposition"
		exit 198
	}

	if "`save'`clear'" == ""{
		di as error "You need to specify either the option save(filename) or the option clear. The first saves the output in an external file while the second replaces the existing dataset."
		exit 198
	}
	* save() and clear are alternatives, so specifying both is a mistake. Versions before 2.2.0 silently
	* ignored clear: warn instead of stopping, so that scripts written for them still run
	if "`save'" != "" & "`clear'" != ""{
		di as text "warning: specify save() or clear, not both; clear is ignored"
		local clear
	}

	* top(x) is shorthand for top0(x) top1(x): the top at t is the same whether t is the start of the
	* period (t, t+1) or the end of the period (t-1, t)
	if "`top'" != ""{
		if "`top0'`top1'" != ""{
			di as error "Specify either top() or both top0() and top1(), not both"
			exit 198
		}
		local top0 `top'
		local top1 `top'
	}
	else if "`top0'" == "" | "`top1'" == ""{
		di as error "Specify either top() or both top0() and top1()"
		exit 198
	}

	local others `id' `time' `varlist' `top0' `top1'
	local overlap : list by & others
	if "`overlap'" != ""{
		di as error "by() must not contain the panel variable, the time variable, `varlist', or the top variables"
		exit 198
	}

	local topvars `top0' `top1'
	local topvars : list uniq topvars
	foreach t of local topvars{
		cap assert inlist(`t', 0 , 1, .)
		if _rc{
			di as error "`t' must only take values 1 (in the top), 0 (in the economy but not in the top), or missing (not in the economy)"
			exit 198
		}
		cap assert `varlist' != .  if `t' == 1
		if _rc{
			di as error `"`varlist' must not be missing when `t' == 1 (i.e. for individuals in the top)"'
			exit 198
		}
	}

	* Each individual counts for `wt' people (1 without weights)
	local wt 1
	if "`weight'" != ""{
		tempvar wgt
		qui gen double `wgt' `exp'
		local wt `wgt'
	}

	local varlabel : variable label `varlist'
	if "`varlabel'" == "" local varlabel `varlist'

	tempvar one Ltop Ftop N S Nf Sf w0 w1 q0 q1 lo0 hi0 hi1 first last
	tempfile full below

	* Keep only the variables used; the dataset in memory is restored at the end
	local keepvars `by' `id' `time' `varlist' `topvars'
	if "`weight'" != "" local keepvars `keepvars' `wgt'
	preserve
	qui keep `keepvars'
	local groups `by'
	if "`groups'" == ""{
		qui gen byte `one' = 1
		local groups `one'
	}
	if "`weight'" != ""{
		cap bys `groups' `id': assert `wt' == `wt'[1]
		if _rc{
			di as error "Weights must be constant over time within each `id'"
			exit 198
		}
	}
	* Top at t-1 (as the start of the period) and at t+1 (as the end of the period)
	sort `groups' `id' `time'
	qui by `groups' `id': gen `Ltop' = `top0'[_n-1] if `time'[_n-1] == `time' - `delta'
	qui by `groups' `id': gen `Ftop' = `top1'[_n+1] if `time'[_n+1] == `time' + `delta'

	/* 1: Highest value below the top in each period (only used to check that the top is the top) */
	qui save `full'
	qui keep if `top0' == 0 | `top1' == 0
	if _N > 0{
		qui gen double `hi0' = `varlist' if `top0' == 0
		qui gen double `hi1' = `varlist' if `top1' == 0
		qui collapse (max) `hi0' `hi1', by(`groups' `time') fast
	}
	else{
		qui keep `groups' `time'
		qui gen double `hi0' = .
		qui gen double `hi1' = .
	}
	qui save `below'
	qui use `full', clear

	/* 2: Collapse individual data into one row per period */
	* Each individual in the top at t-1 or t is classified by comparing top at t with top at t-1 and t+1.
	* top0 is the top at t as the start of the period (t, t+1), top1 the top at t as the end of
	* the period (t-1, t); they are the same variable unless top0() and top1() are specified.
	* Forward-looking groups (defined using F.top1), which partition the top at t:
	*   P0minusD (survivor): in top at t, still in the economy at t+1 (top0==1, F.top1!=.)
	*   D (death):           in top at t, not in the economy at t+1 (top0==1, F.top1==.)
	* Backward-looking groups (defined using L.top0):
	*   P1capP0 (stayer): in top at both t-1 and t (L.top0==1, top1==1)
	*   I (inflow):       not in top at t-1, in top at t (L.top0==0, top1==1)
	*   B (birth):        not in economy at t-1, in top at t (L.top0==., top1==1)
	*   O (outflow):      in top at t-1, not in top at t (L.top0==1, top1==0)
	* For each group and period, compute its size (N, or Nf for forward-looking groups) and the
	* sum of `varlist' over its members (S or Sf), as well as the lowest value in the top (q1).
	cap assert `varlist' != .  if `Ltop' == 1 & !missing(`top1')
	if _rc{
		di as error `"`varlist' must not be missing when L.`top0' == 1 & `top1' != . (i.e. for individuals still in the economy who were in the top in the previous period)"'
		exit 198
	}
	qui keep if `top0' == 1 | `top1' == 1 | `Ltop' == 1
	local forward P0minusD D
	local backward P1capP0 I B O
	local if_P0minusD `top0' == 1 & `Ftop' != .
	local if_D        `top0' == 1 & `Ftop' == .
	local if_P1capP0  `top1' == 1 & `Ltop' == 1
	local if_I        `top1' == 1 & `Ltop' == 0
	local if_B        `top1' == 1 & `Ltop' == .
	local if_O        `top1' == 0 & `Ltop' == 1
	foreach g of local forward{
		qui gen double `Nf'`g' = `wt' if `if_`g''
		qui gen double `Sf'`g' = `wt' * `varlist' if `if_`g''
	}
	foreach g of local backward{
		qui gen double `N'`g' = `wt' if `if_`g''
		qui gen double `S'`g' = `wt' * `varlist' if `if_`g''
	}
	qui gen double `lo0' = `varlist' if `top0' == 1
	qui gen double `q1' = `varlist' if `top1' == 1
	qui collapse (sum) `Nf'* `Sf'* `N'* `S'* (min) `lo0' `q1', by(`groups' `time') fast
	qui merge 1:1 `groups' `time' using `below', keep(master matched) nogen
	sort `groups' `time'
	qui by `groups': gen byte `first' = _n == 1
	qui by `groups': gen byte `last' = _n == _N

	local lo1 `q1'
	foreach r in 0 1{
		cap assert `lo`r'' >= `hi`r'' if !missing(`hi`r'')
		if _rc{
			di as error `"`varlist' must be weakly higher for individuals with `top`r'' == 1 than for individuals with `top`r'' == 0 within each value of `time'"'
			exit 198
		}
	}
	cap assert `Nf'P0minusD > 0 if !`last'
	if _rc{
		di as error `"In each period except the last, at least one individual with `top0' == 1 must survive to the next period (i.e. have a non-missing `top1' at t+1)"'
		exit 198
	}
	cap assert `N'P1capP0 + `N'I + `N'B > 0 if !`first'
	if _rc{
		di as error `"In each period except the first, at least one individual must be in the top group (i.e. with `top1' == 1)"'
		exit 198
	}

	/* 3: Group sizes and averages for the period from t-1 to t */
	* Forward-looking groups are measured at t-1 (w0), backward-looking groups at t (w1).
	* The average of an empty group is set to zero.
	foreach g of local forward{
		qui by `groups': gen double `N'`g' = `Nf'`g'[_n-1] if `time'[_n-1] == `time' - `delta'
		qui by `groups': gen double `w0'`g' = cond(`N'`g' == 0, 0, `Sf'`g'[_n-1] / `N'`g')
	}
	foreach g of local backward{
		qui gen double `w1'`g' = cond(`N'`g' == 0, 0, `S'`g' / `N'`g')
	}
	qui by `groups': gen double `q0' = `lo0'[_n-1] if `time'[_n-1] == `time' - `delta'
	qui drop if `first'

	/* 4: Decomposition */
	qui gen double `N'P0 = `N'P0minusD + `N'D
	qui gen double `w0'P0 = (`N'P0minusD * `w0'P0minusD + `N'D * `w0'D) / `N'P0
	qui gen double `N'P1 = `N'P1capP0 + `N'I + `N'B
	qui gen double `w1'P1 = (`N'P1capP0 * `w1'P1capP0 + `N'I * `w1'I + `N'B * `w1'B) / `N'P1
	qui gen double `w1'P0minusD = (`N'O * `w1'O  + `N'P1capP0 * `w1'P1capP0) / (`N'O + `N'P1capP0)
	cap assert `w0'P0 > 0
	if _rc{
		di as error "Average `varlist' in the top percentile is zero in some period; the decomposition requires a nonzero denominator"
		exit 198
	}
	cap assert `w0'P0minusD > 0
	if _rc{
		di as error "Average `varlist' for surviving top-percentile individuals is zero in some period; the decomposition requires a nonzero denominator"
		exit 198
	}
	qui gen double `prefix'total = `w1'P1 / `w0'P0 - 1
	qui gen double `prefix'within = `w1'P0minusD / `w0'P0minusD - 1
	qui gen double `prefix'inflow = `N'I / `N'P1 * (`w1'I - `q1') / `w0'P0
	qui gen double `prefix'outflow = `N'O / `N'P1 * (`q1' - `w1'O) / `w0'P0
	qui gen double `prefix'birth = `N'B / `N'P1 * (`w1'B - `q1') / `w0'P0
	qui gen double `prefix'death = `N'D / `N'P1 * (`q1' - (`w1'P0minusD / `w0'P0minusD) * `w0'D) / `w0'P0
	qui gen double `prefix'popgrowth = (`N'P1 - `N'P0) / `N'P1 * (`q1' - (`w1'P0minusD / `w0'P0minusD) * `w0'P0) / `w0'P0
	gen double `prefix'between = `prefix'inflow + `prefix'outflow
	gen double `prefix'demography = `prefix'birth + `prefix'death + `prefix'popgrowth

	/* 5: test terms sum to total */
	cap assert abs(`prefix'total - (`prefix'within + `prefix'between + `prefix'demography)) < 1e-9
	if _rc{
		di as error "Terms do not sum to the growth of the average wealth in the top percentile. This should never happen: please file an issue at https://github.com/matthieugomez/topdecompose"
		exit 198
	}

	* Start and end of period, with the same storage type and format as `time'
	local timetype : type `time'
	local timeformat : format `time'
	gen `timetype' `time'0 = `time' - `delta'
	gen `timetype' `time'1 = `time'
	format `time'0 `time'1 `timeformat'

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
	local output `by' `time'0 `time'1 `prefix'total `prefix'within `prefix'between `prefix'inflow `prefix'outflow `prefix'demography `prefix'birth `prefix'death `prefix'popgrowth

	if "`detail'" != ""{
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
		local output `output' N_P0 w0_P0 N_I w1_I N_O w1_O N_B w1_B N_D w0_D N_P1 w1_P1 q0 q1
	}
	qui keep `output'
	qui order `output'
	if "`save'" != ""{
		qui save `save', `replace'
		restore
	}
	else{
		restore, not
	}
end
