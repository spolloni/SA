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
global bw   = 1200;


global LOCAL = 1;
global DATA_PREP = 1;
	local temp_file "Generated/Gauteng/temp/plot_ghs_temp.dta";

if $LOCAL==1 {;
	cd ..;
};
cd ../..;

if $DATA_PREP==1 {;
  local qry = "
    SELECT  A.*, B.cluster, B.distance, C.mode_yr
  FROM ghs AS A 
  	JOIN distance_EA_2001 AS B 
		ON A.ea_code = B.ea_code
	LEFT JOIN (SELECT * FROM rdp_clusters GROUP BY cluster) AS C 
                     ON B.cluster = C.cluster
  ";

*  	LEFT JOIN rdp_clusters as C ;
*  		ON B.cluster = C.cluster ; 

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


g POST = 0;
replace POST=1 if year>mode_yr;

*replace rent_cat= ;
*drop rent;
*rename rent_cat rent;
*replace rent=. if rent==88888 | rent==99999;

egen dists = cut(distance),at(-20($bin)$bw)	;  
drop if dists==.							;
drop distance ;


global manygph=1;
*global gphnum =4;

** VARIABLE DEFINE;
g RDP=rdp==1;
g DWELL=dwell==1;

g PRICE = price ;
replace PRICE = . if price==8888888 | price==9999999 ;
replace PRICE = 3000000 if price>3000000 & price<8888888;

replace PRICE = . if price_cat==9  | price_cat==99 ;
replace PRICE =  ( 50000 + 0 ) / 2 if price_cat==1 ;
replace PRICE =  ( 50001 + 250000 ) / 2 if price_cat==2 ;
replace PRICE =  ( 250001 + 500000 ) / 2 if price_cat==3 ;
replace PRICE =  ( 500001 + 1000000 ) / 2 if price_cat==4 ;
replace PRICE =  ( 1000001 + 1500000 ) / 2 if price_cat==5 ;
replace PRICE =  ( 1500001 + 2000000 ) / 2 if price_cat==6 ;
replace PRICE =  ( 2000001 + 3000000 ) / 2 if price_cat==7 ;
replace PRICE =  ( 3000000 )  if price_cat==8 ;
replace PRICE = . if PRICE==0;

replace PRICE=1000000 if PRICE>1000000 ; 
g ln_p = log(PRICE);

g ln_p_rdp=ln_p if RDP==1;
g ln_p_not=ln_p if RDP==0 & DWELL<=2;


g RENT = rent ; 
replace RENT = . if rent == 88888 | rent == 99999 ;
replace RENT = 7000 if RENT >=7000 & RENT<. ; 

replace RENT = (0 + 500)/2 if rent_cat==1 ;
replace RENT = (501 + 1000)/2 if rent_cat==2 ;
replace RENT = (1001 + 3000)/2 if rent_cat==3 ;
replace RENT = (3001 + 5000)/2 if rent_cat==4 ;
replace RENT = (5001 + 7000)/2 if rent_cat==5 ;
replace RENT = (7000) if rent_cat==6;

g ln_r=log(RENT);

g ln_r_not = ln_r if RDP==0 & DWELL<=2;


** SINGLE GRAPH OUTCOME ;
local outcome "RDP";

** MANY GRAPH OUTCOMES ;
*local outcome_many "RDP DWELL PRICE ln_p";
local outcome_many "ln_p_not ln_r_not";


if $manygph==0 {;
egen o = mean(`outcome'), by(dists POST);
tw  
	scatter o dists if POST==0, yaxis(1) ||
	lowess `outcome' dists if POST==0, yaxis(1) ||	
	scatter o dists if POST==1, yaxis(1) ||
	lowess `outcome' dists if POST==1, yaxis(1) ||		
	, legend(order(1 "pre" 2 "pre" 3 "post" 4 "post")) ;
};


if $manygph==1 {;

foreach v in `outcome_many' {;

egen o_`v' = mean(`v'), by(dists POST);
	tw  
		scatter o_`v' dists if POST==0, yaxis(1) ||
		lowess `v' dists if POST==0, yaxis(1) ||	
		scatter o_`v' dists if POST==1, yaxis(1) ||
		lowess `v' dists if POST==1, yaxis(1) ||		
		, legend(order(1 "pre" 2 "pre" 3 "post" 4 "post")) title("`v'") ;
		graph save "`v'.gph", replace ;
local graph_list " `graph_list' `v'.gph " ;
disp "`graph_list'";
};

gr combine `graph_list';

};








