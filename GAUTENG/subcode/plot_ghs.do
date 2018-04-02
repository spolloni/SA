clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;
******************;
*  PLOT DENSITY  *;
******************;

global bin  = 20;
global bw   = 900;


global LOCAL = 1;
global DATA_PREP = 1;
	local temp_file "Generated/Gauteng/temp/plot_ghs_temp.dta";

if $LOCAL==1 {;
	cd ..;
};
cd ../..;

if $DATA_PREP==1 {;
  local qry = "
  SELECT  A.*, B.cluster, B.distance
  FROM rdp_conhulls as D, ghs AS A  JOIN distance_EA_2001 AS B 
		ON A.ea_code = B.ea_code
  JOIN ea_2001 AS C
  		ON A.ea_code = C.ea_code

  ";
qui odbc query "gauteng";
odbc load, exec("`qry'") clear;

*foreach var of varlist dwell-rdp_yr3 {;
*	replace `var'=. if `var'==88888 | `var'==8888888 | `var'==99999 | `var'==9999999
*	egen `var'_mean=mean(`var'), by(ea_code year);
*	drop `var';
*	ren `var'_mean `var';
*};

save `temp_file', replace;
	};


use `temp_file', clear;

*** NEED TO DEAL WITH INTERSECTION!;


g YEAR = 2001;
replace YEAR=2011 if year>2009;

*replace rent_cat= ;
*drop rent;
*rename rent_cat rent;
*replace rent=. if rent==88888 | rent==99999;


egen dists = cut(distance),at(-20($bin)$bw)	;  
drop if dists==.							;
drop distance ;

*local outcome "formal_percent";
local outcome "rent"; 

g RDP=rdp==1;
local outcome "RDP";
*local outcome "avg_income"; 

egen o = mean(`outcome'), by(dists YEAR);

tw  
	scatter o dists if YEAR==2001, yaxis(1) ||
	lowess `outcome' dists if YEAR==2001, yaxis(1) ||	
	scatter o dists if YEAR==2011, yaxis(1) ||
	lowess `outcome' dists if YEAR==2011, yaxis(1) ||		
	, legend(order(1 "2001" 2 "2001" 3 "2011" 4 "2011")) ;






