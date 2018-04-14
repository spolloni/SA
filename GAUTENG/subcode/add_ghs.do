
clear all
set more off

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


local years "02 03 04 05 06 07 08 09 10 11 12 13 14 15 16"
local years_append "09 02 03 04 05 06 07 08 10 11 12 13 14 15 16" // to get the labels right

local varlist "uqnr prov dwell owner rdp rent rent_cat price price_cat rdp_orig rdp_subs rdp_wt rdp_wt_mem rdp_yr1 rdp_yr2 rdp_yr3 build_yr"

program define var_gen
	foreach v in `1' {
		capture confirm var `v'
		if _rc!=0 {
			g `v'=.
		}
	}
	keep `1'
end



local yr "02"
	use `h`yr'', clear
	ren *, lower
	ren q41maind  dwell
	ren q45owner  owner	
	ren q47house  rdp
	var_gen "`varlist'"
	    g year = "`yr'"
		tempfile temp_h`yr'
		save "`temp_h`yr''"  


local yr "03"
	use `h`yr'', clear
	ren *, lower
	ren q41maind  dwell
	ren q45owner  owner	
	ren q411hous  rdp
	g   rent = q4611pai if q47rentp==3 & q4611pai<88888
	var_gen "`varlist'"
	    g year = "`yr'"
		tempfile temp_h`yr'
		save "`temp_h`yr''"  


local yr_list "04 05 06 07 08"
foreach yr in `yr_list' {
*	local yr "05"
	use `h`yr'', clear
	ren *, lower
	ren q41maind  dwell
	ren q46owner  owner	
	ren q418hous  rdp
	ren q416*     rent
	ren q417mark  price
	var_gen "`varlist'"
	    g year = "`yr'"
		tempfile temp_h`yr'
		save "`temp_h`yr''" 
}



local yr_list "09 10"
foreach yr in `yr_list' {
	use `h`yr'', clear
	ren *, lower
	ren q31maind  dwell
	ren q36owner  owner	
	ren q310ardp  rdp
	ren q37rent  rent_cat
	ren q38val price_cat
	ren q39built build_yr
	ren q310borig rdp_orig
	ren q311subs rdp_subs
	ren q312awl  rdp_wt
	ren q312bwt  rdp_wt_mem
	ren q312cpersa rdp_yr1
	ren q312cpersb rdp_yr2
	ren q312cpersc rdp_yr3	
	var_gen "`varlist'"
	    g year = "`yr'"
		tempfile temp_h`yr'
		save "`temp_h`yr''" 
}



local yr_list "11"
foreach yr in `yr_list' {
	use `h`yr'', clear
	ren *, lower
	ren q31maind  dwell
	ren q35owner  owner	
	ren q36rent  rent_cat
	ren q37val price_cat	
	ren q38built build_yr
	ren q39ardp  rdp	
	ren q39borig rdp_orig
	ren q310subs rdp_subs
	ren q311wl  rdp_wt
	*ren q312bwt  rdp_wt_mem
	*ren q312cpersa rdp_yr1
	*ren q312cpersb rdp_yr2
	*ren q312cpersc rdp_yr3	
	var_gen "`varlist'"
	    g year = "`yr'"
		tempfile temp_h`yr'
		save "`temp_h`yr''" 
}



local yr_list "12 13"
foreach yr in `yr_list' {
	use `h`yr'', clear
	ren *, lower
	if "`yr'"=="12" {
		local j "3"
	}
	else {
		local j "5"	
	}
	if "`yr'"=="13" {
		ren q`j'1amaind  dwell	
	}
	else {
		ren q`j'1maind  dwell		
	}
	ren q`j'5owner  owner	
	ren q`j'6rent  rent_cat
	ren q`j'7val price_cat
	ren q`j'8built	build_yr
	ren q`j'9ardp  rdp	
	ren q`j'9borig rdp_orig
	ren q`j'10subs rdp_subs
	ren q`j'11awl  rdp_wt
	ren q`j'11bwt  rdp_wt_mem
	ren q`j'11cpers1 rdp_yr1
	ren q`j'11cpers2 rdp_yr2
	ren q`j'11cpers3 rdp_yr3	
	var_gen "`varlist'"
	    g year = "`yr'"
		tempfile temp_h`yr'
		save "`temp_h`yr''" 
}


local yr_list "14 15 16"
foreach yr in `yr_list' {
	use `h`yr'', clear
	ren *, lower
	local j "5"	
	ren q`j'1maind  dwell		
	ren q`j'6owner  owner	
	ren q`j'7rent  rent_cat
	ren q`j'8val price_cat
	ren q`j'9built	build_yr
	ren q`j'10ardp  rdp	
	ren q`j'10borig rdp_orig
	var_gen "`varlist'"
	    g year = "`yr'"
		tempfile temp_h`yr'
		save "`temp_h`yr''" 
}


*** PUT TEMPORARY FILES TOGETHER ***

clear
foreach r in `years_append' {
	if _N<10 {
		use `temp_h`r'', clear
	}
	else {
		append using `temp_h`r'', force
	}
	sort year
}


g ea_code = substr(uqnr,1,8)
replace year="20"+year
destring uqnr year, replace force


save "Generated/GAUTENG/temp/ghs_full.dta", replace
odbc exec("DROP TABLE IF EXISTS ghs;"), dsn("gauteng")
odbc insert, table("ghs") create
odbc exec("CREATE INDEX ea_code_index ON ghs (ea_code);"), dsn("gauteng")
exit, STATA clear





