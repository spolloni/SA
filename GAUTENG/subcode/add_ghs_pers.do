
clear all
set more off

if $LOCAL == 1 {
	cd ..
}

cd ../../

local p02 "Raw/GHS/2002/ghs-2002-v1.2-stata/ghs-2002-person-v1.2-20150127.dta"
local h02 "Raw/GHS/2002/ghs-2002-v1.2-stata/ghs-2002-house-v1.2-20150127.dta"

local p03 "Raw/GHS/2003/ghs-2003-v1.3-stata/ghs-2003-person-v1.3-20150127.dta"
local h03 "Raw/GHS/2003/ghs-2003-v1.3-stata/ghs-2003-house-v1.3-20150127.dta"

local p04 "Raw/GHS/2004/ghs-2004-v1.3-stata/ghs-2004-person-v1.3-20150127.dta"
local h04 "Raw/GHS/2004/ghs-2004-v1.3-stata/ghs-2004-house-v1.3-20150127.dta"

local p05 "Raw/GHS/2005/ghs-2005-v1.3-stata/ghs-2005-person-v1.3-20150127.dta"
local h05 "Raw/GHS/2005/ghs-2005-v1.3-stata/ghs-2005-house-v1.3-20150127.dta"

local p06 "Raw/GHS/2006/ghs-2006-v1.3-stata/ghs-2006-person-v1.3-20150127.dta"
local h06 "Raw/GHS/2006/ghs-2006-v1.3-stata/ghs-2006-house-v1.3-20150127.dta"

local p07 "Raw/GHS/2007/ghs-2007-v1.3-stata/ghs-2007-person-v1.3-20150127.dta"
local h07 "Raw/GHS/2007/ghs-2007-v1.3-stata/ghs-2007-house-v1.3-20150127.dta"

local p08 "Raw/GHS/2008/ghs-2008-v1.3-stata/ghs-2008-person-v1.3-20150127.dta"
local h08 "Raw/GHS/2008/ghs-2008-v1.3-stata/ghs-2008-house-v1.3-20150127.dta"

local p09 "Raw/GHS/2009/ghs-2009-v1.2-stata/ghs-2009-person-v1.2-20150127.dta"
local h09 "Raw/GHS/2009/ghs-2009-v1.2-stata/ghs-2009-house-v1.2-20150127.dta"

local p10 "Raw/GHS/2010/ghs-2010-v2.1-stata/ghs-2010-person-v2.1-20150127.dta"
local h10 "Raw/GHS/2010/ghs-2010-v2.1-stata/ghs-2010-house-v2.1-20150127.dta"

local p11 "Raw/GHS/2011/ghs-2011-v1.1-stata/ghs-2011-person-v1.1-20150127.dta"
local h11 "Raw/GHS/2011/ghs-2011-v1.1-stata/ghs-2011-house-v1.1-20150127.dta"

local p12 "Raw/GHS/2012/ghs-2012-v2-stata13/GHS-2012-Person-v2-20131015.dta"
local h12 "Raw/GHS/2012/ghs-2012-v2-stata13/GHS-2012-House-v2-20131015.dta"

local p13 "Raw/GHS/2013/stata/ghs-2013-person-v1-20140620.dta"
local h13 "Raw/GHS/2013/stata/ghs-2013-house-v1-20140620.dta"

local p14 "Raw/GHS/2014/ghs-2014-v1-stata/ghs_2014_person_v1_20150630.dta"
local h14 "Raw/GHS/2014/ghs-2014-v1-stata/ghs_2014_house_v1_20150630.dta"

local p15 "Raw/GHS/2015/stata/ghs_2015_person_v1.1_20160608.dta"
local h15 "Raw/GHS/2015/stata/ghs_2015_house_v1.1_20160608.dta"

local p16 "Raw/GHS/2016/ghs-2016-v1-stata/ghs-2016-person-stata11.dta"
local h16 "Raw/GHS/2016/ghs-2016-v1-stata/ghs-2016-house-stata11.dta"

local p17 "Raw/GHS/2017/Stata11/GHS 2017 Person v1.0 Stata11.dta"
local h17 "Raw/GHS/2017/Stata11/GHS 2017 Household v1.0 Stata11.dta"



local years "05 06 07 08 09 10 11 12 13 14 15 16 17"
local years_append "09 05 06 07 08 10 11 12 13 14 15 16 17" // to get the labels right

local varlist "uqnr personnr prov gender age race fetch fetch_hrs med injury flu diar edu_time edu rel_hh  emp sal_period sal  "
  

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
	use `p`yr'', clear
	ren *, lower

	ren q15afetw fetch
	ren q15bhrsw fetch_hrs

	ren q118medi med
	ren q119inju injury
	ren q120flu flu
	ren q120diar diar

	ren q11relshh rel_hh
	ren q19hiedu edu
	ren q113time edu_time

	var_gen "`varlist'"
	    g year = "`yr'"
		tempfile temp_p`yr'
		save "`temp_p`yr''" 
}


local yr_list "09 10"
foreach yr in `yr_list' {
	* local yr "09"
	use `p`yr'', clear
	ren *, lower

	ren q130ainju injury
	ren q130bflu  flu
	ren q130bdiar diar

	ren q11relsh rel_hh
	ren q16hiedu edu
	ren q117btim edu_time

	if "`yr'"=="09" {
		ren q140awge emp
		ren q141asto sal
		ren q141bsp sal_period
	}
	else {	
		ren q21awge emp
		ren q22asto sal
		ren q22bsp sal_period
	}

	var_gen "`varlist'"
	    g year = "`yr'"
		tempfile temp_p`yr'
		save "`temp_p`yr''" 
}


local yr_list "11"
foreach yr in `yr_list' {
	
	*local yr "11"
	use `p`yr'', clear

	ren *, lower
	
	ren q125medi med
	ren q126ainju injury
	ren q126bflu  flu
	ren q126bdia diar

	ren q16hiedu edu
	ren q115btim edu_time
		
	ren q21awge emp
	ren q22asto sal
	ren q22bsp sal_period


	var_gen "`varlist'"
	    g year = "`yr'"
		tempfile temp_p`yr'
		save "`temp_p`yr''" 
}




local yr_list "12"
foreach yr in `yr_list' {
	* local yr "12"
	use `p`yr'', clear
	ren *, lower

	ren q125medi med
	ren q126ainju injury
	ren q126bflu  flu
	ren q126bdia diar

	ren q16hiedu edu
	ren q115btim edu_time
		
	ren q21awge emp
	ren q22asto sal
	ren q22bsp sal_period

	var_gen "`varlist'"
	    g year = "`yr'"
		tempfile temp_p`yr'
		save "`temp_p`yr''" 
}


* local yr_list "14 15 16"

local yr_list "13 14"

foreach yr in `yr_list' {
	use `p`yr'', clear
	ren *, lower
	destring personnr, replace force
	if "`yr'"=="13" {
	ren q16hiedu edu
	ren q21medi med
	* ren q126ainju injury
	ren q23bflu flu
	ren q23bdia diar	
	}
	else {
	ren q15hiedu edu
	ren q21medi med
	* ren q126ainju injury
	ren q23flu flu
	ren q23dia diar		
	}
	
	ren q115btim edu_time

	ren q41awge emp
	ren q42asto sal
	ren q42bsp sal_period

	var_gen "`varlist'"
	    g year = "`yr'"
		tempfile temp_p`yr'
		save "`temp_p`yr''" 
}


local yr_list "15 16 17"

foreach yr in `yr_list' {
	use "`p`yr''", clear
	ren *, lower
	destring personnr, replace force

	ren q21medi med
	* ren q126ainju injury
	ren q23flu flu
	ren q23dia diar		
	
	ren q15hiedu edu
	ren q115btim edu_time

	ren q41awge emp
	ren q42asto sal
	ren q42bsp sal_period

	var_gen "`varlist'"
	    g year = "`yr'"
		tempfile temp_p`yr'
		save "`temp_p`yr''" 
}



*** PUT TEMPORARY FILES TOGETHER ***

* use `temp_h05', clear


* global lab_list = "dwell owner rent_cat price_cat build_yr rdp rdp_orig rdp_subs rdp_wt rdp_wt_mem rdp_yr1 rdp_yr2 rdp_yr3 dwell_5 dwell_other_5 electricity toilet_shr toilet_dist toilet tot_rooms water_source water_distance roof wall roof_q wall_q stole harass harass_hh hurt hurt_hh year"
*  foreach var in $lab_list {
* 	 levelsof `var', local(`var'_levels)       
* 	 foreach val of local `var'_levels  {       
*       	 local `var'vl`val' : label `var' `val'    
*        }
*  }


clear
foreach r in `years_append' {
	if _N<10 {
		use `temp_p`r'', clear
	}
	else {
		append using `temp_p`r'', force
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

save "Generated/GAUTENG/temp/ghs_full_pers.dta", replace
odbc exec("DROP TABLE IF EXISTS ghs_pers;"), dsn("gauteng")
odbc insert, table("ghs_pers") create
odbc exec("CREATE INDEX ea_code_index_pers ON ghs_pers (ea_code);"), dsn("gauteng")
* exit, STATA clear





