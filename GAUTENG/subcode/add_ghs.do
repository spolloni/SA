
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


local years "02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17"
local years_append "09 02 03 04 05 06 07 08 10 11 12 13 14 15 16 17" // to get the labels right

local varlist "uqnr prov owner rdp rent rent_cat price_cat price true_rent rdp_orig rdp_subs rdp_wt rdp_wt_mem rdp_yr1 rdp_yr2 rdp_yr3 build_yr dwell_5 dwell_other_5 dwell dwell_other  electricity toilet_shr toilet_dist toilet_dwell toilet   tot_rooms water_source water_distance roof wall roof_q wall_q  stolen  harass  harass_hh hurt  hurt_hh water_source piped other_water pipe_breaks pipe_cause cook_elec rubbish poll_water poll_air poll_land poll_noise "


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



local yr "05"
	use `h`yr'', clear
	ren *, lower
	

local yr_list "04"
foreach yr in `yr_list' {
*	local yr "05"
	use `h`yr'', clear
	ren *, lower
	ren q41maind  dwell
	ren q41othrd  dwell_other
	ren q42maind  dwell_5
	ren q42othrd  dwell_other_5


	ren q43roof roof
	ren q43walls wall
	ren q44roofc roof_q
	ren q44wallc wall_q

	ren q45totrm tot_rooms

	ren q46owner  owner	
	ren q418hous  rdp
	ren q416*     rent
	ren q417mark  price

	var_gen "`varlist'"
	    g year = "`yr'"
		tempfile temp_h`yr'
		save "`temp_h`yr''" 
}


local yr_list "05 06 07 08"
foreach yr in `yr_list' {
*	local yr "05"
	use `h`yr'', clear
	ren *, lower
	ren q41maind  dwell
	ren q41othrd  dwell_other
	ren q42maind  dwell_5
	ren q42othrd  dwell_other_5

	ren q43roof roof
	ren q43walls wall
	ren q44roofc roof_q
	ren q44wallc wall_q

	ren q45totrm tot_rooms

	ren q46owner  owner	
	ren q418hous  rdp
	ren q416*     rent
	ren q417mark  price


	if "`yr'"=="05" {
	ren q439typt toilet
	ren q440toil toilet_shr
	ren q441dist toilet_dist
	}
	else {
		ren q430typt toilet
		ren q431dist toilet_dist
		ren q432toil toilet_shr
	}



	ren q419drin water_source
	* ren q423pipe piped 
	ren q419othr other_water
	ren q427inte pipe_breaks
	* ren q428causs pipe_cause

	* ren q437cook cook_elec
	* ren q439rubb rubbish 

	* ren q451bwat poll_water
	* ren q451cair poll_air
	* ren q451dlan poll_land
	* ren q451enoi poll_noise

	if "`yr'"=="05" {
		ren q443main electricity 
		ren q422pipe piped
		ren q446cook cook_elec
		ren q448rubb rubbish
		ren q460bwat poll_water
		ren q460cair poll_air
		ren q460dlan poll_land
		ren q460enoi poll_noise
		ren q47brent true_rent
	}
	else {
		ren q434main electricity
		ren q423pipe piped 
		ren q428causs pipe_cause
		ren q437cook cook_elec
		ren q439rubb rubbish
		ren q451bwat poll_water
		ren q451cair poll_air
		ren q451dlan poll_land
		ren q451enoi poll_noise
		ren q47a14to true_rent
	}

* 	water_source piped other_water pipe_breaks pipe_cause cook_elec rubbish poll_water poll_air poll_land poll_noise

	if "`yr'"=="05" {
		ren q420drin water_distance
	}
	else {
		ren q420dist water_distance
	}
	
	if "`yr'"=="05" {
		ren q481athe stolen
		ren q481binh harass_hh
		ren q481cnot harass
		ren q481fhit hurt_hh
		ren q481ghit hurt
	}
	else {
		ren q471athe stolen
		ren q471binh harass_hh
		ren q471cnot harass
		ren q471fhit hurt_hh
		ren q471ghit hurt
	}

	* ren q414repa rep
	* ren q415amai rep_v

	var_gen "`varlist'"
	    g year = "`yr'"
		tempfile temp_h`yr'
		save "`temp_h`yr''" 
}



	
local yr_list "09 10"
foreach yr in `yr_list' {
	local `yr' 
	* local yr "09"
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


	ren q31othrd  dwell_other
	ren q32maind  dwell_5
	ren q32othrd  dwell_other_5
	ren q33roof roof
	ren q33walls wall
	ren q34roofc roof_q
	ren q34wallc wall_q
	ren q35totrm tot_rooms

	ren q324toil toilet
	ren q326sha toilet_shr
	ren q328near toilet_dist

	* ren q47a14to true_rent

	* ren q313drin water_source
	* ren q423pipe piped 
	* ren q419othr other_water
	ren q321ainte pipe_breaks
	ren q321bcaus pipe_cause

	* ren q437cook cook_elec
	ren q335rubb rubbish 

	ren q339wat poll_water
	ren q339air poll_air
	ren q339lan poll_land
	ren q339noi poll_noise


	if "`yr'"=="09" {
		ren q330mains electricity
	}
	else {
		ren q330amains electricity
	}
	
	ren q313drin water_source
	ren q314dist water_distance

		* ren q471athe stolen
		* ren q471binh harass_hh
		* ren q471cnot harass
		* ren q471fhit hurt_hh
		* ren q471ghit hurt


	var_gen "`varlist'"
	    g year = "`yr'"
		tempfile temp_h`yr'
		save "`temp_h`yr''" 
}




local yr_list "11"
foreach yr in `yr_list' {
	
	* local yr "11"
	use `h`yr'', clear

	ren *, lower
	ren q31maind  dwell
	ren q35owner  owner	
	ren q36rent  rent_cat
	ren q37val   price_cat	
	ren q38built build_yr
	ren q39ardp  rdp	
	ren q39borig rdp_orig
	ren q310subs rdp_subs
	ren q311wl  rdp_wt


	ren q31othrd  dwell_other
	* ren q32maind  dwell_5
	* ren q32othrd  dwell_other_5
	ren q32roof roof
	ren q32walls wall
	ren q33roofc roof_q
	ren q33wallc wall_q
	ren q34totrm tot_rooms

	ren q322toil toilet
	ren q324sha toilet_shr
	ren q326near toilet_dist

	ren q327amains electricity

	ren q312drin water_source
	ren q313adist water_distance


	* ren q313drin water_source
	* ren q423pipe piped 
	* ren q419othr other_water
	ren q319ainte pipe_breaks
	ren q319bcaus pipe_cause

	ren q331cook cook_elec
	ren q332rub rubbish 

	ren q336wat poll_water
	ren q336air poll_air
	ren q336lan poll_land
	ren q336noi poll_noise


		* ren q471athe stolen
		* ren q471binh harass_hh
		* ren q471cnot harass
		* ren q471fhit hurt_hh
		* ren q471ghit hurt


	var_gen "`varlist'"
	    g year = "`yr'"
		tempfile temp_h`yr'
		save "`temp_h`yr''" 
}



local yr_list "12 13"
foreach yr in `yr_list' {
	* local yr "12"
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
		ren q`j'1aothrd	 dwell_other

		ren q`j'1bmaind  dwell_5
		ren q`j'1bothrd dwell_other_5
	}
	else {
		ren q`j'1maind  dwell
		ren q`j'1othrd	dwell_other	
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



	* ren q31othrd  dwell_other
	* ren q32maind  dwell_5
	* ren q32othrd  dwell_other_5
	ren q`j'2roof roof
	ren q`j'2walls wall
	ren q`j'3roofc roof_q
	ren q`j'3wallc wall_q
	ren q`j'4totrm tot_rooms

	ren q`j'22toil toilet
	ren q`j'24sha toilet_shr
	if "`yr'"=="12" {
	ren q`j'26near toilet_dist
	ren q`j'34acook cook_elec
	ren q`j'36rub rubbish 
	ren q`j'39wat poll_water
	ren q`j'39air poll_air
	ren q`j'39lan poll_land
	ren q`j'39noi poll_noise
	}
	else {
		ren q`j'25bnear toilet_dist
		ren q`j'31cook cook_elec
		ren q`j'32rub rubbish 
		ren q`j'35wat poll_water
		ren q`j'35air poll_air
		ren q`j'35lan poll_land
		ren q`j'35noi poll_noise
	}

	ren q`j'28amains electricity

	ren q`j'12drin water_source
	ren q`j'13adist water_distance

		* ren q471athe stolen
		* ren q471binh harass_hh
		* ren q471cnot harass
		* ren q471fhit hurt_hh
		* ren q471ghit hurt

	* ren q313drin water_source
	* ren q423pipe piped 
	* ren q419othr other_water
	ren q`j'19ainte pipe_breaks
	ren q`j'19bcaus pipe_cause

	* ren q`j'34acook cook_elec
	* ren q`j'36rub rubbish 

	* ren q`j'39wat poll_water
	* ren q`j'39air poll_air
	* ren q`j'39lan poll_land
	* ren q`j'39noi poll_noise

	var_gen "`varlist'"
	    g year = "`yr'"
		tempfile temp_h`yr'
		save "`temp_h`yr''" 
}



local yr_list "14 15 16 17"
foreach yr in `yr_list' {
	*local yr "14"
	if "`yr'"=="17" {
		use "Raw/GHS/2017/Stata11/GHS 2017 Household v1.0 Stata11.dta", clear
	}
	else {
		use `h`yr'', clear
	}
	

	ren *, lower
	
	local j "5"	
	ren q`j'1maind  dwell		
	ren q`j'6owner  owner	
	ren q`j'7rent  rent_cat
	ren q`j'8val price_cat
	ren q`j'9built	build_yr
	ren q`j'10ardp  rdp	
	ren q`j'10borig rdp_orig


	* ren q31othrd  dwell_other
	* ren q32maind  dwell_5
	* ren q32othrd  dwell_other_5
	ren q`j'2roof roof
	ren q`j'2walls wall
	ren q`j'4roofc roof_q
	ren q`j'4wallc wall_q
	ren q`j'5totrm tot_rooms

	ren q`j'22toil toilet
	ren q`j'24sha toilet_shr
	if "`yr'"=="16" | "`yr'"=="17" {
		ren q`j'25aoy toilet_dwell
	}
	else {
		ren q`j'25ayo toilet_dwell
	}

		ren q`j'25bnear toilet_dist

	ren q`j'28amains electricity

	ren q`j'12drin water_source
	ren q`j'13adist water_distance

		* ren q471athe stolen
		* ren q471binh harass_hh
		* ren q471cnot harass
		* ren q471fhit hurt_hh
		* ren q471ghit hurt

	* ren q313drin water_source
	* ren q423pipe piped 
	* ren q419othr other_water
	ren q`j'19ainte pipe_breaks
	ren q`j'19bcaus pipe_cause

	ren q`j'31cook cook_elec
	ren q`j'32rub rubbish 

	if "`yr'"=="16" | "`yr'"=="17" {
		ren q`j'36wat poll_water
		ren q`j'36air poll_air
		ren q`j'36lan poll_land
		ren q`j'36noi poll_noise
	}
	else {
		ren q`j'37wat poll_water
		ren q`j'37air poll_air
		ren q`j'37lan poll_land
		ren q`j'37noi poll_noise	
	}

	var_gen "`varlist'"
	    g year = "`yr'"
		tempfile temp_h`yr'
		save "`temp_h`yr''" 
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

* foreach var in $lab_list{                 /* loop over list "inc answer" */
* 	 levelsof `var', local(`var'_levels)       
* 	 foreach val of local `var'_levels{             /* loop over list "80 81 82" */
* 		 label variable `variable'`val' "`var'vl`val': `yearvl`value''"
* 	 }
* }

save "Generated/GAUTENG/temp/ghs_full.dta", replace
odbc exec("DROP TABLE IF EXISTS ghs;"), dsn("gauteng")
odbc insert, table("ghs") create
odbc exec("CREATE INDEX ea_code_index ON ghs (ea_code);"), dsn("gauteng")
* exit, STATA clear





