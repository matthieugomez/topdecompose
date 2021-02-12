program define growthpercentile
	syntax varlist(max=1 numeric), [TOPindicator(varname numeric) save(string) replace clear Detail]

	***************************************************************************************************
	*Check Inputs
	***************************************************************************************************
	if "`save'`clear'" == ""{
		di as error "You need to specify either the option save(filename) or the option clear. The first saves the output in an external file while the second replaces the existing dataset."
		exit 198
	}

	if "`topindicator'" == ""{
		tempvar topindicator
		qui gen byte `topindicator' = 1
	}

	cap assert `topindicator' == 0 | `topindicator' == 1
	if _rc{
		di as error "The dummy variable `topindicator', indicating whether an individual is in the top percentile, must only take values 0 and 1. If the individual is not in the economy at time t, drop the corresponding observation"
		exit 198
	}

	cap assert `varlist' != .  if ((`topindicator' == 1) | (L.`topindicator' == 1))
	if _rc{
		di as error "Missing values for `varlist' are not allowed if the individual is in the top percentile this period or the previous period."
		exit 198
	}

	qui tsset
	local id `r(panelvar)'
	local time  `r(timevar)'

	if regexm("`time'", "^w0_") | regexm("`time'", "^w1_") | regexm("`time'", "n_") | ("`time'" == "q1"){
		di as error "The time variable "`time'" cannot start with w0_, w1_, or n_ or be equal to q1"
		exit 198
	}
	***************************************************************************************************
	*Do decomposition
	***************************************************************************************************
	preserve
	tempfile temp
	save `temp'
	tempvar set

	/* 1: Decomposing average at P0 */
	qui gen `set' = "P0minusD" if `topindicator' == 1 & F.`topindicator' != .
	qui replace `set' = "D" if `topindicator' == 1 & F.`topindicator' == .
	qui drop if missing(`set')
	qui collapse (count) n_ = `varlist' (mean) w0_ = `varlist', by(`time' `set')
	qui reshape wide n_ w0_, i(`time') j(`set') string
	* Handle the fact that, when sets are empty, variables may not exist (always empty) or be missing
	foreach suffix in P0minusD D{
		cap confirm variable n_`suffix'
		if _rc{
			qui gen n_`suffix' = .
			qui gen w0_`suffix' = .
		}
		qui replace w0_`suffix' = 0 if n_`suffix' == .
		qui replace n_`suffix' = 0 if n_`suffix' == .
	}
	tempfile temp0
	save `temp0'

	/* 2: Decomposing average at P1 */
	qui use `temp', clear
	qui gen `set' = "P1capP0" if `topindicator' == 1 & L.`topindicator' == 1
	qui replace `set' = "E" if `topindicator' == 1 & L.`topindicator' == 0
	qui replace `set' = "B" if `topindicator' == 1 & L.`topindicator' == .
	qui replace `set' = "X" if `topindicator' == 0 & L.`topindicator' == 1
	qui drop if missing(`set')
	qui collapse (count) n_ = `varlist' (mean) w1_ = `varlist', by(`time' `set')
	qui reshape wide n_ w1_, i(`time') j(`set') string
	qui replace `time' = `time' - 1
	* Handle the fact that, when sets are empty, variables may not exist (always empty) or be missing
	foreach suffix in P1capP0 E B X{
		cap confirm variable n_`suffix'
		if _rc{
			qui gen n_`suffix' = .
			qui gen w1_`suffix' = .
		}
		qui replace w1_`suffix' = 0 if n_`suffix' == .
		qui replace n_`suffix' = 0 if n_`suffix' == .
	}
	tempfile temp1
	save `temp1'

	/* 3: Compute quantile q1 */	
	qui use `temp', clear
	qui gen `set' = "P1" if `topindicator' == 1
	qui replace `set' = "notP1" if `topindicator' == 0
	qui collapse  (min) w1_min = `varlist' (max) w1_max = `varlist', by(`time' `set')
	qui reshape wide w1_min w1_max, i(`time') j(`set') string
	cap assert w1_minP1 >= w1_maxP1 - 1
	if _rc{
		di "Some individuals outside the top have a value for `varlist' higher than the minimum value in the top"
	}
	qui replace `time' = `time' - 1
	qui rename w1_minP1 q1
	qui keep `time' q1
	qui sum `time'
	qui drop if `time' == r(min)

	/* 4: combine everything together */
	qui merge 1:1 `time' using `temp0', keep(master matched) nogen
	qui merge 1:1 `time' using `temp1', keep(master matched) nogen
	qui gen n_P0 = n_P0minusD + n_D
	cap assert n_P0 > 0
	if _rc{
		di as error "There are periods without any individuals in the top"
		exit 198
	}
	qui gen w0_P0 = (n_P0minusD * w0_P0minusD + n_D * w0_D) / n_P0
	qui gen n_P1 = n_P1capP0 + n_E + n_B
	qui gen w1_P1 = (n_P1capP0 * w1_P1capP0 + n_E * w1_E + n_B * w1_B) / n_P1
	qui gen w1_P0minusD = (n_X * w1_X  + n_P1capP0 * w1_P1capP0) / (n_X + n_P1capP0)
	qui gen total = w1_P1 / w0_P0 - 1
	qui gen within = w1_P0minusD / w0_P0minusD - 1
	qui gen inflow = n_E / n_P1 * (w1_E - q1) / w0_P0
	qui gen outflow = n_X / n_P1 * (q1 - w1_X) / w0_P0
	qui gen birth = n_B / n_P1 * (w1_B - q1) / w0_P0
	qui gen death = n_D / n_P1 * (q1 - (w1_P0minusD / w0_P0minusD) * w0_D) / w0_P0
	qui gen popgrowth = (n_P1 - n_P0) / n_P1 * (q1 - (w1_P0minusD / w0_P0minusD) * w0_P0) / w0_P0

	* test sum to total
	cap assert abs(total - (within + inflow + outflow + birth + death + popgrowth)) < 1e-6
	if _rc{
		di as error "Terms do not sum to the growth of the average wealth in the top percentile. Please file an issue at https://github.com/matthieugomez/Decomposing-the-growth-of-top-wealth-shares"
		exit 198
	}

	* output
	if "`detail'" == ""{
		qui keep `time' total within inflow outflow birth death popgrowth
		qui order `time' total within inflow outflow birth death popgrowth
	}
	else{
		foreach suffix in P0minusD D{
			qui replace w0_`suffix' = . if n_`suffix' == 0
		}
		foreach suffix in P1capP0 E B X{
			qui replace w1_`suffix' = . if n_`suffix' == 0
		}
		qui keep `time' total within inflow outflow birth death popgrowth n_P0 w0_P0 n_E w1_E n_X w1_X n_B w1_B n_D w0_D n_P1 w1_P1
		qui order `time' total within inflow outflow birth death popgrowth n_P0 w0_P0 n_E w1_E n_X w1_X n_B w1_B n_D w0_D n_P1 w1_P1
	}
	if "`save'" != ""{
		qui save `save', `replace'
		restore
	}
	else{
		restore, not
	}
end
