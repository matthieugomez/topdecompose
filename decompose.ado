program define decompose, sortpreserve
	syntax varlist(max=1 numeric), top(varname) 


	***************************************************************************************************
	*Check Inputs
	***************************************************************************************************

	cap assert `top' == 0 | `top' == 1
	if _rc{
		di as error "The dummy variable `top', indicating whether an individual is in the top percentile, must only take values 0 and 1. If the individual is not in the economy at time t, drop the corresponding observation"
		exit 198
	}

	cap assert (`varlist' != .) | ((L.`top' != 1) & (L.`top' != 1))
	if _rc{
		di as error "Missing values for `varlist' are only allowed if the individual is neither in the top percentile this period or in the previous period."
		exit 198
	}

	qui tsset
	local id `r(panelvar)'
	local time  `r(timevar)'

	***************************************************************************************************
	*Do decomposition
	***************************************************************************************************
	tempfile temp
	save `temp'


	tempvar wbar wbar_l q q_f N N_f weight within sE rE sX rX rB sB sD rD rP sP

	* Create aggregate variables
	keep if `top' == 1
	gen `N' = 1
	collapse (mean) `wbar' = `varlist' (min) `q' = `varlist' (sum) `N' , by(`time')
	tsset `time'
	gen `wbar_l' = L.`wbar'
	gen `q_f' = F.`q'
	gen `N_f' = F.`N'
	tempfile temp_agg
	save `temp_agg'

	use `temp', clear
	merge m:1 `time' using `temp_agg', keep(master matched) nogen
	* check individuals outside the top have wealth lower than individuals inside the top
	cap assert (`top' == 1) | (`varlist' == .) | (`varlist' <= `q')
	if _rc{
		di as error "Some individuals outside the top have a value for `varlist' higher than the minimum value in the top percentile"
		exit 198
	}
	tsset `id' `time'
	save `temp', replace

	* total between t and t+1
	use `temp_agg'
	gen total = (F.`wbar'-`wbar') / `wbar'
	keep `time' total
	tempfile temp_total
	save `temp_total'

	* within between t and t+1
	use `temp', clear
	gen `weight' = `varlist' * (`top' == 1) * (F.`top' != .)
	gen `within' = F.`varlist' / `varlist' - 1
	collapse (mean) withinb = `within'  [w = `weight'], by(`time')
	tempfile temp_within
	save `temp_within'

	* inflow between t-1 and t
	use `temp', clear
	gen `sE' = (`top' == 1) * (L.`top' == 0)  / `N'
	gen `rE' = (`varlist' - `q') / `wbar_l' if `sE'
	collapse (sum) sE = `sE' (mean) rE =`rE', by(`time')
	gen inflow = rE * sE
	replace inflow = 0 if sE == 0
	order inflow
	replace `time' = `time' - 1
	tempfile temp_inflow
	save `temp_inflow'

	* birth between t-1 and t
	use `temp', clear
	gen `sB' = (`top' == 1) * (L.`top' == .)  / `N'
	gen `rB' = (`varlist' - `q') / `wbar_l' if `sB'
	collapse (sum) sB = `sB'  (mean) rB = `rB', by(`time')
	gen birth = rB * sB
	replace birth = 0 if sB == 0
	order birth
	replace `time' = `time' - 1
	tempfile temp_birth
	save `temp_birth'

	* outflow between t and t+1
	use `temp', clear
	gen `sX' = (`top' == 1) * (F.`top' == 0)  / `N_f'
	gen `rX' = (`q_f' - F.`varlist') / `wbar' if `sX'
	collapse (sum) sX = `sX' (mean) rX = `rX', by(`time')
	gen outflow = sX * rX
	order outflow
	tempfile temp_outflow
	save `temp_outflow'

	* death between t and t+1
	use `temp', clear
	merge m:1 `time' using `temp_within', keep(master matched) nogen
	tsset `id' `time'
	gen `sD' = (`top' == 1) * (F.`top' == .) / `N_f'
	gen `rD' = (`q_f' - `varlist' * (1 + within)) / `wbar' if `sD'
	collapse (sum) sD = `sD' (mean) rD = `rD', by(`time')
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

	***************************************************************************************************
	*Put everything together
	***************************************************************************************************

	use `temp_total'
	merge 1:1 `time' using `temp_within', nogen
	merge 1:1 `time' using `temp_inflow', nogen
	merge 1:1 `time' using `temp_outflow', nogen
	merge 1:1 `time' using `temp_death', nogen
	merge 1:1 `time' using `temp_popgrowth', nogen
	merge 1:1 `time' using `temp_birth', nogen
	
	* Remove first and last time
	sum `time'
	drop if inlist(`time', r(min), r(max))

	* Check terms sum to 1
	cap assert abs(total - (within + inflow + outflow + birth + death + popgrowth)) < 1e-6
	if _rc{
		di as error "Terms do not sum to the growth of the average wealth in the top percentile. Please file an issue at https://github.com/matthieugomez/Decomposing-the-growth-of-top-wealth-shares"
		exit 198
	}
end
