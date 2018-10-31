clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767


*odbc query "gauteng"
*odbc load, exec("SELECT * FROM ") clear

* /Users/williamviolette/southafrica/Raw/GHS/2015/stata/ghs_2015_person_v1.1_20160608.dta


use "/Users/williamviolette/southafrica/Raw/GHS/2015/stata/ghs_2015_house_v1.1_20160608.dta", clear


use "/Users/williamviolette/southafrica/Raw/GHS/2008/ghs-2008-v1.3-stata/ghs-2008-house-v1.3-20150127.dta", clear

ren Q416Rent rent

tab rent
drop if rent>6000 | rent<=0



