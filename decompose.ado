cap program drop decompose

program define decompose
	syntax varlist(max=1 numeric), top(varname) 

	local w `varlist'
	di "`w'"
	tempvar wbar wbar_l q q_f N N_f



	cap assert `top' != .
	if _rc{
		di as error "The dummy variable `top', indicating whether an individual is in the top percentile, has missing values. If the individual is not in the economy at time t, simply drop it from the dataset."
		exit 198
	}

	cap assert `top' == 0 | `top' == 1
	if _rc{
		di as error "The dummy variable `top', indicating whether an individual is in the top percentile, takes values beyond 0 and 1."
		exit 198
	}

	* w is allowed to be missing only for individuals that enter the top
	cap assert (`w' != .) | ((L.`top' != 1) & (L.`top' != 1))
	if _rc{
		di as error "Missing values for `w' are only allowed if the individual is neither in the top percentile this period or in the previous period."
		exit 198
	}


	qui tsset
	local id `r(panelvar)'
	local time  `r(timevar)'
	sum `time'
	local timemin = r(min)
	local timemax = r(max)
	tempfile temp
	save `temp'

	keep if `top' == 1
	gen `N' = 1
	collapse (mean) `wbar' = `w' (min) `q' = `w' (sum) `N' , by(`time')
	tsset `time'
	gen `wbar_l' = L.`wbar'
	gen `q_f' = F.`q'
	gen `N_f' = F.`N'
	tempfile temp_agg
	save `temp_agg'

	use `temp', clear
	merge m:1 `time' using `temp_agg', keep(master matched) nogen
	cap assert (`top' == 1) | (`w' == .) | (`w' <= `q')
	if _rc{
		br if !((`top' == 1) | (`w' == .) | (`w' <= `q'))
		gen q = `q'
		br if !((top == 1) | (w == .) | (w <= q))

		x
		di as error "Some individuals outside the top have a value for `w' higher than the minimum value in the top percentile"
		exit 198
	}
	tsset `id' `time'
	save `temp', replace

	* total between t and t+1
	use `temp_agg'
	gen total = (F.`wbar'-`wbar') / `wbar'
	keep `time' total
	drop if `time' == `timemax'
	tempfile temp_total
	save `temp_total'

	* within between t and t+1
	use `temp', clear
	gen weight = `w' * (`top' == 1) * (F.`top' != .)
	gen within = F.`w' / `w' - 1
	collapse (mean) within  [w = weight], by(`time')
	drop if `time' == `timemax'
	tempfile temp_within
	save `temp_within'

	* entry between t-1 and t
	use `temp', clear
	gen sE = (`top' == 1) * (L.`top' == 0)  / `N'
	gen rE = (`w' - `q') / `wbar_l' if sE
	collapse (sum) sE (mean) rE, by(`time')
	gen inflow = rE * sE
	replace inflow = 0 if sE == 0
	order inflow
	replace `time' = `time' - 1
	tempfile temp_inflow
	save `temp_inflow'

	* birth between t-1 and t
	use `temp', clear
	gen sB = (`top' == 1) * (L.`top' == .)  / `N'
	gen rB = (`w' - `q') / `wbar_l' if sB
	collapse (sum) sB  (mean) rB, by(`time')
	gen birth = rB * sB
	replace birth = 0 if sB == 0
	order birth
	replace `time' = `time' - 1
	tempfile temp_birth
	save `temp_birth'

	* exit between t and t+1
	use `temp', clear
	gen sX = (`top' == 1) * (F.`top' == 0)  / `N_f'
	gen rX = (`q_f' - F.`w') / `wbar' if sX
	collapse (sum) sX (mean) rX, by(`time')
	gen outflow = sX * rX
	order outflow
	tempfile temp_outflow
	save `temp_outflow'

	* death between t and t+1
	use `temp', clear
	merge m:1 `time' using `temp_within', keep(master matched) nogen
	tsset `id' `time'
	gen sD = (`top' == 1) * (F.`top' == .) / `N_f'
	gen rD = (`q_f' - `w' * (1 + within)) / `wbar' if sD
	collapse (sum) sD (mean) rD, by(`time')
	gen death = sD * rD
	replace death = 0 if sD == 0
	order death
	tempfile temp_death
	save `temp_death'

	* population growth between t and t + 1
	use `temp_agg'
	merge m:1 `time' using `temp_within', nogen
	gen sP = (`N_f'-`N') / `N_f'
	gen rP = (`q_f' - `wbar' * (1 + within)) / `wbar'
	gen popgrowth = sP * rP
	order popgrowth
	tempfile temp_popgrowth
	save `temp_popgrowth'


	* total between
	use `temp_total'
	merge 1:1 `time' using `temp_within', nogen
	merge 1:1 `time' using `temp_inflow', nogen
	merge 1:1 `time' using `temp_outflow', nogen
	merge 1:1 `time' using `temp_death', nogen
	merge 1:1 `time' using `temp_popgrowth', nogen
	merge 1:1 `time' using `temp_birth', nogen
	drop if `time' == `timemin' - 1
	drop if `time' == `timemax'

	di "Check sum to 1"
	gen temp = abs(total - (within + inflow + outflow + birth + death + popgrowth))
	sum temp
	assert r(max) < 1e-6
	drop temp
end
