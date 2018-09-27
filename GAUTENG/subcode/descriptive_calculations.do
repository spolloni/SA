
clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;
******************;
*  PLOT DENSITY  *;
******************;

global LOCAL = 1;
if $LOCAL==1{;
	cd ..;
};
cd ../..;

global ghs_info = 0;
global trans_info = 1;

if $ghs_info == 1 {;
local qry = "SELECT  *  FROM ghs";
qui odbc query "gauteng";
odbc load, exec("`qry'") clear;

tab year rdp_wt;
tab rdp_wt_mem if rdp_wt_mem<10;
tab rdp_orig if build_yr<=1 & rdp==1 & rdp_orig<=2;
tab rdp_orig own if build_yr<=1 & rdp==1;
};


if $trans_info == 1 {;
local qry = "SELECT  *  FROM transactions";
qui odbc query "gauteng";
odbc load, exec("`qry'") clear;
destring purch_yr, replace force;
drop if purch_yr<2003 | purch_yr>2011;

*cd Generated/GAUTENG;
*use gradplot.dta, clear;
*drop if purch_yr<2003 | purch_yr>2011;
};







