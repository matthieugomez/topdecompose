program define meanpercentile
	syntax varlist(max=1 numeric) using/, [top(varname numeric) replace clear]

	if "`top'" == ""{
		tempvar top
		gen `top' = 1
	}

	***************************************************************************************************
	*Check Inputs
	***************************************************************************************************

	cap assert `top' == 0 | `top' == 1
	if _rc{
		di as error "The dummy variable `top', indicating whether an individual is in the top percentile, must only take values 0 and 1. If the individual is not in the economy at time t, drop the corresponding observation"
		exit 198
	}

	cap assert `varlist' != .  if ((`top' == 1) | (L.`top' == 1))
	if _rc{
		di as error "Missing values for `varlist' are not allowed if the individual is in the top today or last period."
		exit 198
	}

	qui tsset
	local id `r(panelvar)'
	local time  `r(timevar)'

	***************************************************************************************************
	*Do decomposition
	***************************************************************************************************
	preserve
	tempvar wbar wbar_l q q_f N N_f weight within sE rE sX rX rB sB sD rD rP sP

	* Create aggregate variables
	tempfile temp
	save `temp'
	keep if `top' == 1
	gen `N' = 1
	collapse (mean) `wbar' = `varlist' (min) `q' = `varlist' (sum) `N' , by(`time')
	tsset `time'
	gen `wbar_l' = L.`wbar'
	gen `q_f' = F.`q'
	gen `N_f' = F.`N'
	tempfile agg
	save `agg'

	use `temp'
	merge m:1 `time' using `agg', keep(master matched) nogen
	* check individuals outside the top have wealth lower than individuals inside the top
	cap assert (`top' == 1) | (`varlist' == .) | (`varlist' <= `q' + 1e-3)
	if _rc{
		di as error "Some individuals outside the top have a value for `varlist' higher than the minimum value in the top percentile"
		exit 198
	}
	tsset `id' `time'
	tempfile temp
	save `temp', replace

	* total between t and t+1
	use `agg'
	gen total = (F.`wbar'-`wbar') / `wbar'
	keep `time' total
	tempfile total
	save `total'

	* within between t and t+1
	use `temp', clear
	gen `weight' = `varlist' * (`top' == 1) * (F.`top' != .)
	gen `within' = F.`varlist' / `varlist' - 1
	collapse (mean) within = `within'  [w = `weight'], by(`time')
	tempfile within
	save `within'

	* inflow between t-1 and t
	use `temp', clear
	gen `sE' = (`top' == 1) * (L.`top' == 0)  / `N'
	gen `rE' = (`varlist' - `q') / `wbar_l' if `sE'
	collapse (sum) sE = `sE' (mean) rE =`rE', by(`time')
	gen inflow = rE * sE
	replace inflow = 0 if sE == 0
	order inflow
	replace `time' = `time' - 1
	tempfile inflow
	save `inflow'

	* outflow between t and t+1
	use `temp', clear
	gen `sX' = (`top' == 1) * (F.`top' == 0)  / `N_f'
	gen `rX' = (`q_f' - F.`varlist') / `wbar' if `sX'
	collapse (sum) sX = `sX' (mean) rX = `rX', by(`time')
	gen outflow = sX * rX
	order outflow
	tempfile outflow
	save `outflow'

	* birth between t-1 and t
	use `temp', clear
	gen `sB' = (`top' == 1) * (L.`top' == .)  / `N'
	gen `rB' = (`varlist' - `q') / `wbar_l' if `sB'
	collapse (sum) sB = `sB'  (mean) rB = `rB', by(`time')
	gen birth = rB * sB
	replace birth = 0 if sB == 0
	order birth
	replace `time' = `time' - 1
	tempfile birth
	save `birth'

	* death between t and t+1
	use `temp', clear
	merge m:1 `time' using `within', keep(master matched) nogen
	tsset `id' `time'
	gen `sD' = (`top' == 1) * (F.`top' == .) / `N_f'
	gen `rD' = (`q_f' - `varlist' * (1 + within)) / `wbar' if `sD'
	collapse (sum) sD = `sD' (mean) rD = `rD', by(`time')
	gen death = sD * rD
	replace death = 0 if sD == 0
	order death
	tempfile death
	save `death'

	* population growth between t and t + 1
	use `agg'
	merge m:1 `time' using `within', nogen
	gen sP = (`N_f'-`N') / `N_f'
	gen rP = (`q_f' - `wbar' * (1 + within)) / `wbar'
	gen popgrowth = sP * rP
	order `time' popgrowth sP rP
	keep `time' popgrowth sP rP
	tempfile popgrowth
	save `popgrowth'

	***************************************************************************************************
	*Put everything together
	***************************************************************************************************

	use `total'
	merge 1:1 `time' using `within', nogen
	merge 1:1 `time' using `inflow', nogen
	merge 1:1 `time' using `outflow', nogen
	merge 1:1 `time' using `birth', nogen
	merge 1:1 `time' using `death', nogen
	merge 1:1 `time' using `popgrowth', nogen
	
	* Remove first and last time
	sum `time'
	drop if inlist(`time', r(min), r(max))
	* Check terms sum to 1
	cap assert abs(total - (within + inflow + outflow + birth + death + popgrowth)) < 1e-6
	if _rc{
		di as error "Terms do not sum to the growth of the average wealth in the top percentile. Please file an issue at https://github.com/matthieugomez/Decomposing-the-growth-of-top-wealth-shares"
		exit 198
	}
	save `using', `replace' `clear'

	restore
end
