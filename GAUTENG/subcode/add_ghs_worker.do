
clear all
set more off

if $LOCAL == 1 {
	cd ..
}

cd ../../


local w05 "Raw/GHS/2005/ghs-2005-v1.3-stata/ghs-2005-worker-v1.3-20150127.dta"
local w06 "Raw/GHS/2006/ghs-2006-v1.3-stata/ghs-2006-worker-v1.3-20150127.dta"
local w07 "Raw/GHS/2007/ghs-2007-v1.3-stata/ghs-2007-worker-v1.3-20150127.dta"
local w08 "Raw/GHS/2008/ghs-2008-v1.3-stata/ghs-2008-worker-v1.3-20150127.dta"
* local w09 "Raw/GHS/2009/ghs-2009-v1.2-stata/ghs-2009-worker-v1.2-20150127.dta"


local years "05 06 07 08  "
local years_append "05 06 07 08 " // to get the labels right

local varlist "uqnr personnr emp sal_period sal "
  

program define var_gen
	foreach v in `1' {
		capture confirm var `v'
		if _rc!=0 {
			g `v'=.
		}
	}
	keep `1'
end


local yr_list "05 06 07 08"
foreach yr in `yr_list' {
	* local yr "05"
	use "`w`yr''", clear
	ren *, lower
	destring personnr, replace force

	ren q21wrkls emp 
	ren q29salto sal
	ren q210salp sal_period

	tab emp

	var_gen "`varlist'"
	    g year = "`yr'"
		tempfile temp_w`yr'
		save "`temp_w`yr''", replace
}


* local yr_list "09"
* foreach yr in `yr_list' {
* 	* local yr "09"
* 	use `w`yr'', clear
* 	ren *, lower

* 	ren q21wrkls emp 
* 	ren q29salto sal
* 	ren q210salp sal_period


* 	var_gen "`varlist'"
* 	    g year = "`yr'"
* 		tempfile temp_w`yr'
* 		save "`temp_w`yr''" 
* }



clear
foreach r in `years_append' {
	if _N<10 {
		use `temp_w`r'', clear
	}
	else {
		append using `temp_w`r'', force
	}
	sort year
}


g ea_code = substr(uqnr,1,8)
replace year="20"+year
destring uqnr personnr year, replace force

duplicates drop uqnr personnr year, force

* foreach var in $lab_list{                 /* loop over list "inc answer" */
* 	 levelsof `var', local(`var'_levels)       
* 	 foreach val of local `var'_levels{             /* loop over list "80 81 82" */
* 		 label variable `variable'`val' "`var'vl`val': `yearvl`value''"
* 	 }
* }

save "Generated/GAUTENG/temp/ghs_full_worker.dta", replace
odbc exec("DROP TABLE IF EXISTS ghs_worker;"), dsn("gauteng")
odbc insert, table("ghs_worker") create
odbc exec("CREATE INDEX ea_code_index_worker ON ghs_worker (ea_code);"), dsn("gauteng")
* exit, STATA clear





