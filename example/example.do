
/***************************************************************************************************

***************************************************************************************************/
insheet using "$SavePath/aggregate.csv", clear
keep year pophouseholds hhnw_my
tempfile temp
save `temp'


use "$SavePath/phd-list-imputed.dta", clear

merge m:1 year using `temp', keepusing(hhnw_my pophouseholds) keep(master matched) nogen
sum pophouseholds if year == 2017
local m = r(mean)
gen N = floor(pophouseholds / (`m' / 399))
replace pophouseholds = N * (`m' / 399)
gen w = networth * 1000 / (hhnw_my / pophouseholds) 
gen top = (rank <= N)
tsset id year
gen death = L.death_f
replace death = 0 if missing(death)
gen top_l = L.top
tempfile temp
save `temp'

foreach year of numlist 1983/2016{
	use `temp', clear
	keep if inlist(year, `year', `year' + 1)
	keep name id familyid
	duplicates drop *, force
	gen year = `year'
	expand 2, gen(new)
	replace year = `year' + 1 if new == 1
	merge 1:1 id year using `temp', keep(master matched) nogen
	drop if  L.death_f == 1
	egen familydeath_f = max(death_f * (top == 1)), by(year familyid)
	drop if  missing(top) & (F.top == 1) & (familydeath_f == 1) 
	replace top = 0 if missing(top)
	tempfile temp`year'
	meanpercentile w using `temp`year'', top(top) 
}

clear all
foreach year of numlist 1983/2016{
	append using `temp`year''
}

gen logR_total = log(1 + total)
gen logR_within = log(1 + within)
gen logR_displacement = log(1 + inflow + outflow)
gen logR_demography = log(1 + birth + death + popgrowth)
sort year
collapse (mean) logR*

save "$SavePath/shares_400", replace
