* d_census.do

clear 

set more off
set scheme s1mono

if $LOCAL==1 {
	cd .. 
}



cd ../.. 


use "GHS/2007/Data/LFS 2007_1 Person_v1.1_STATA.dta", clear

ren UqNr uqnr
duplicates drop uqnr, force
drop PSU

/*
merge 1:1 uqnr using GHS/2006/ghs-2006-v1.3-stata/ghs-2006-house-v1.3-20150127.dta

/*
merge 1:1 UqNr using GHS/2007/ghs-2007-v1.3-stata/ghs-2007-house-v1.3-20150127.dta


/*

use GHS/2006/ghs-2006-v1.3-stata/ghs-2006-house-v1.3-20150127.dta, clear


use GHS/2004/ghs-2004-v1.3-stata/ghs-2004-house-v1.3-20150127.dta, clear




use GHS/2008/ghs-2008-v1.3-stata/ghs-2008-house-v1.3-20150127.dta, clear




ren * *_05

ren UqNr UqNr

merge 1:1 UqNr using GHS/2009/ghs-2009-v1.2-stata/ghs-2009-house-v1.2-20150127.dta





use GHS/2009/ghs-2009-v1.2-stata/ghs-2009-house-v1.2-20150127.dta, clear

ren * *_05

ren UqNr UqNr

merge 1:1 UqNr using GHS/2010/ghs-2010-v2.1-stata/ghs-2010-house-v2.1-20150127.dta



/*



use GHS/2005/ghs-2005-v1.3-stata/ghs-2005-house-v1.3-20150127.dta, clear




ren * *_05

ren UqNr uqnr

merge 1:1 uqnr using GHS/2006/ghs-2006-v1.3-stata/ghs-2006-house-v1.3-20150127.dta

tab head_sex_05 head_sex


tab head_popgrp_05 head_popgrp



destring PSU_05 psu, replace force

browse if PSU_05!=psu


*** 05 06 WORKS!! 



/*

*** 04 05 doesnt work unfort...

use GHS/2005/ghs-2005-v1.3-stata/ghs-2005-house-v1.3-20150127.dta, clear




ren * *_05

ren UqNr UqNr

merge 1:1 UqNr using GHS/2004/ghs-2004-v1.3-stata/ghs-2004-house-v1.3-20150127.dta





/*
save Generated/GAUTENG/temp/2005

/*

local qry = "  SELECT  * FROM ghs " 

odbc query "gauteng" 
odbc load, exec("`qry'") clear 

keep if year==2006

keep uqnr prov dwell owner rent_cat
foreach var of varlist prov dwell owner rent_cat {
	ren `var' `var'_05
} 
save "temp/ghs_tempfile.dta", replace


local qry = "  SELECT  * FROM ghs " 

odbc query "gauteng" 
odbc load, exec("`qry'") clear 

keep if year==2006

merge 1:1 uqnr using "temp/ghs_tempfile.dta"





/*

* ghs-2005-house-v1.3-20150127.dta

clear 

set more off
set scheme s1mono


if $LOCAL==1 {
	cd .. 
}




* load data;
cd ../.. 
cd Generated/Gauteng



use "DDcensus_hh_full_2011_admin${V}.dta", clear

* append using "DDcensus_hh_full_1996_admin${V}.dta"
append using "DDcensus_hh_full_2001_admin${V}.dta"

drop cbd_dist

fmerge m:1 area_code year using "DDcensus_hh_place_admin${V}.dta"


g con = area_int_rdp>.5 & area_int_rdp<.

reg con i.dwelling_typ if distance_rdp<1000




hist dwelling_typ if dwelling_typ<20, by(con year) discrete 

hist tenure  if dwelling_typ<20, by(con year) discrete 


hist tot_rooms  if  tot_rooms<=10 & (dwelling_typ==1 | dwelling_typ==7 | dwelling_typ==6 | dwelling_typ==8 | dwelling_typ==9), by(con year dwelling_typ) discrete 

