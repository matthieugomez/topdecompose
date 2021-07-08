program define meanpercentile
	syntax varlist(max=1 numeric), [Percentile(numlist >0 <=100) TOPindicator(varname numeric) save(string) log replace clear Detail]


	/* 0: Check Inputs */
	qui tsset
	local id `r(panelvar)'
	local time  `r(timevar)'
	if inlist("`time'", "total", "within", "displacement", "demography"){
		di as error "The time variable cannot be named as: total, within, displacement, or demography"
		exit 198
	}
	if "`detail"!="" & inlist("`time'", "inflow", "outflow", "birth", "death", "popgrowth") {
		di as error "The time variable cannot be named as: inflow outflow birth death popgrowth"
	}
	if "`detail"!="" & inlist("`time'", "n_P0", "n_E", "n_X", "n_B", "n_D", "n_P1") {
		di as error "The time variable cannot be named as: n_P0 n_E n_X n_B n_D n_P1 q1"
	}

	if "`detail"!="" & inlist("`time'", "w0_P0", "w1_E", "w1_E", "w1_X", "w1_B", "w0_D", "w1_P1", "q1") {
		di as error "The time variable cannot be named as: w0_P0 w1_E w1_X w1_X w0_D w1_P1 q1"
	}


if "`save'`clear'" == ""{
	di as error "You need to specify either the option save(filename) or the option clear. The first saves the output in an external file while the second replaces the existing dataset."
	exit 198
}

if "`log'" != "" & "`detail'" != ""{
	di as error "The options log and details cannot be specified at the same time."
}

if "`percentile'" != ""{
	cap assert "`topindicator'" == ""
	if _rc{
		di as error "You cannot specify both percentile and topindicator"
	}
	marksample touse
	tempvar topindicator
	bys `touse' `time'  (`varlist'): gen byte `topindicator' = _n >= `percentile' / 100 * _N if `touse' == 1
	tsset `id' `time'
}

cap assert inlist(`topindicator', 0 , 1, .)
if _rc{
	di as error "The dummy variable `topindicator', indicating whether an individual is in the top percentile, must only take values missing, 0 and 1."
	exit 198
}

cap assert `varlist' != .  if ((`topindicator' == 1) | (L.`topindicator' == 1))
if _rc{
	di as error "Missing values for `varlist' are not allowed if the individual is in the top percentile this period or the previous period."
	exit 198
}



preserve
tempfile temp
qui save `temp'
tempvar set n w0 w1 inflow outflow birth death popgrowth q1

/* 1: Decomposing average at P0 */
qui gen `set' = "P0minusD" if `topindicator' == 1 & F.`topindicator' != .
qui replace `set' = "D" if `topindicator' == 1 & F.`topindicator' == .
qui drop if missing(`set')
tempvar 
qui collapse (count) `n' = `varlist' (mean) `w0' = `varlist', by(`time' `set')
qui reshape wide `n' `w0', i(`time') j(`set') string
	* Handle the fact that, when sets are empty, variables may not exist (always empty) or be missing
	foreach suffix in P0minusD D{
		cap confirm variable `n'`suffix'
		if _rc{
			qui gen `n'`suffix' = .
			qui gen `w0'`suffix' = .
		}
		qui replace `w0'`suffix' = 0 if `n'`suffix' == .
		qui replace `n'`suffix' = 0 if `n'`suffix' == .
	}
	tempfile temp0
	qui save `temp0'

	/* 2: Decomposing average at P1 */
	qui use `temp', clear
	qui gen `set' = "P1capP0" if `topindicator' == 1 & L.`topindicator' == 1
	qui replace `set' = "E" if `topindicator' == 1 & L.`topindicator' == 0
	qui replace `set' = "B" if `topindicator' == 1 & L.`topindicator' == .
	qui replace `set' = "X" if `topindicator' == 0 & L.`topindicator' == 1
	qui drop if missing(`set')
	qui collapse (count) `n' = `varlist' (mean) `w1' = `varlist', by(`time' `set')
	qui reshape wide `n' `w1', i(`time') j(`set') string
	qui replace `time' = `time' - 1
	* Handle the fact that, when sets are empty, variables may not exist (always empty) or be missing
	foreach suffix in P1capP0 E B X{
		cap confirm variable `n'`suffix'
		if _rc{
			qui gen `n'`suffix' = .
			qui gen `w1'`suffix' = .
		}
		qui replace `w1'`suffix' = 0 if `n'`suffix' == .
		qui replace `n'`suffix' = 0 if `n'`suffix' == .
	}
	tempfile temp1
	qui save `temp1'

	/* 3: Compute quantile q1 */	
	qui use `temp', clear
	qui gen `set' = "P1" if `topindicator' == 1
	qui replace `set' = "notP1" if `topindicator' == 0
	qui drop if missing(`set')
	qui collapse  (min) `w1'min = `varlist' (max) `w1'max = `varlist', by(`time' `set')
	qui reshape wide `w1'min `w1'max, i(`time') j(`set') string
	cap assert `w1'minP1 >= `w1'maxnotP1 - 1
	if _rc{
		di as error "Some individuals outside the top have a value for `varlist' higher than the minimum value in the top"
		exit 198
	}
	qui replace `time' = `time' - 1
	qui rename `w1'minP1 `q1'
	qui keep `time' `q1'
	qui sum `time'
	qui drop if `time' == r(min)

	/* 4: combine everything together */
	qui merge 1:1 `time' using `temp0', keep(master matched) nogen
	qui merge 1:1 `time' using `temp1', keep(master matched) nogen
	qui gen `n'P0 = `n'P0minusD + `n'D
	cap assert `n'P0 > 0
	if _rc{
		di as error "There are periods without any individuals in the top"
		exit 198
	}
	qui gen `w0'P0 = (`n'P0minusD * `w0'P0minusD + `n'D * `w0'D) / `n'P0
	qui gen `n'P1 = `n'P1capP0 + `n'E + `n'B
	qui gen `w1'P1 = (`n'P1capP0 * `w1'P1capP0 + `n'E * `w1'E + `n'B * `w1'B) / `n'P1
	qui gen `w1'P0minusD = (`n'X * `w1'X  + `n'P1capP0 * `w1'P1capP0) / (`n'X + `n'P1capP0)
	qui gen total = `w1'P1 / `w0'P0 - 1
	qui gen within = `w1'P0minusD / `w0'P0minusD - 1
	qui gen `inflow' = `n'E / `n'P1 * (`w1'E - `q1') / `w0'P0
	qui gen `outflow' = `n'X / `n'P1 * (`q1' - `w1'X) / `w0'P0
	qui gen `birth' = `n'B / `n'P1 * (`w1'B - `q1') / `w0'P0
	qui gen `death' = `n'D / `n'P1 * (`q1' - (`w1'P0minusD / `w0'P0minusD) * `w0'D) / `w0'P0
	qui gen `popgrowth' = (`n'P1 - `n'P0) / `n'P1 * (`q1' - (`w1'P0minusD / `w0'P0minusD) * `w0'P0) / `w0'P0


	/* 5: test terms sum to total */
	cap assert abs(total - (within + `inflow' + `outflow' + `birth' + `death' + `popgrowth')) < 1e-6
	if _rc{
		di as error "Terms do not sum to the growth of the average wealth in the top percentile. Please file an issue at https://github.com/matthieugomez/Decomposing-the-growth-of-top-wealth-shares"
		exit 198
	}

	/* 6: return results */
	if "`detail'" == ""{
		if "`log'" == ""{
			gen displacement = `inflow' + `outflow'
			gen demography = `birth' + `death' + `popgrowth'
		}
		else{
			gen displacement = log(1 + (`inflow' + `outflow') / (1 + `within' + `birth' + `death' + `popgrowth'))
			gen demography = log(1 + (`birth' + `death' + `popgrowth') / (1 + `within'))
		}
		qui keep `time' total within displacement demography
		qui order `time' total within displacement demography
	}
	else{
		foreach suffix in P0 D{
			qui replace `w0'`suffix' = . if `n'`suffix' == 0
		}
		foreach suffix in P1capP0 E B X{
			qui replace `w1'`suffix' = . if `n'`suffix' == 0
		}
		foreach suffix in P0 D{
			qui rename `w0'`suffix'  w0_`suffix'
			qui rename `n'`suffix'  n_`suffix'
		}
		foreach suffix in E X B P1{
			qui rename `w1'`suffix' w1_`suffix'
			qui rename `n'`suffix' n_`suffix'
		}
		qui rename `inflow' inflow
		qui rename `outflow' outflow
		qui rename `birth' birth
		qui rename `death' death
		qui rename `popgrowth' popgrowth
		qui rename `q1' q1
		qui keep `time' total within inflow outflow birth death popgrowth n_P0 w0_P0 n_E w1_E n_X w1_X n_B w1_B n_D w0_D n_P1 w1_P1 q1
		qui order `time' total within inflow outflow birth death popgrowth n_P0 w0_P0 n_E w1_E n_X w1_X n_B w1_B n_D w0_D n_P1 w1_P1 q1
	}
	if "`save'" != ""{
		qui save `save', `replace'
		restore
	}
	else{
		restore, not
	}
end
