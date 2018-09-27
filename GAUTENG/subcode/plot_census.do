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
global DATA_PREP = 0;
	local temp_file "Generated/Gauteng/temp/plot_census_temp.dta";

if $LOCAL==1 {;
	cd ..;
};
cd ../..;

if $DATA_PREP==1 {;
  local qry = "
  SELECT  A.*, B.cluster, B.distance, 2001 as YEAR
  FROM census_2001_sp AS A  JOIN distance_SP_2001 AS B 
		ON A.Subplace_Code = B.sp_code 
	UNION
  SELECT  C.*, D.cluster, D.distance, 2011 as YEAR
  FROM census_2011_sp AS C  JOIN distance_SP_2011 AS D
		ON C.SP_CODE = D.sp_code 
  ";
qui odbc query "gauteng";
odbc load, exec("`qry'") clear;
save `temp_file', replace;
	};




use `temp_file', clear;

egen dists = cut(distance),at(0($bin)$bw)	;  
drop if dists==.							;
drop distance ;

*local outcome "formal_percent";
local outcome "backyard_percent"; 

*local outcome "avg_income"; 

egen o = mean(`outcome'), by(dists YEAR);

tw  
	scatter o dists if YEAR==2001, yaxis(1) ||
	lowess `outcome' dists if YEAR==2001, yaxis(1) ||	
	scatter o dists if YEAR==2011, yaxis(1) ||
	lowess `outcome' dists if YEAR==2011, yaxis(1) ||		
	, legend(order(1 "2001" 2 "2001" 3 "2011" 4 "2011")) ;






