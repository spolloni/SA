clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;
******************;
*  PLOT DENSITY  *;
******************;

global bin  = 100;
global bw   = 1000;


global LOCAL = 1;
global DATA_PREP = 1;
	local temp_file "Generated/Gauteng/temp/plot_ghs_temp.dta";

if $LOCAL==1 {;
	cd ..;
};
cd ../..;

if $DATA_PREP==1 {;
  local qry = "
    SELECT  A.*, B.cluster, B.distance, C.mode_yr, D.distance AS distance_2011, E.mode_yr AS mode_yr_2011
  FROM ghs AS A 
  	LEFT JOIN distance_EA_2001_rdp AS B 
		ON A.ea_code = B.ea_code
    LEFT JOIN distance_EA_2011_rdp AS D
    	ON A.ea_code = D.ea_code		
	LEFT JOIN (SELECT * FROM rdp_clusters GROUP BY cluster) AS C 
                     ON B.cluster = C.cluster
	LEFT JOIN (SELECT * FROM rdp_clusters GROUP BY cluster) AS E 
                     ON D.cluster = E.cluster
  ";

* P.distance as distance_placebo, PC.placebo_yr ;
*   LEFT JOIN distance_EA_2001_placebo AS P  ;
*		ON A.ea_code = P.ea_code ;
*	LEFT JOIN (SELECT * FROM placebo_conhulls GROUP BY cluster) AS PC ;
*                     ON P.cluster = PC.cluster ;

qui odbc query "gauteng";
odbc load, exec("`qry'") clear;

save `temp_file', replace;
	};


use `temp_file', clear;

*** NEED TO DEAL WITH INTERSECTION!;

replace distance = distance_2011 if distance==. & distance_2011!=. ;
replace mode_yr = mode_yr_2011 if mode_yr==. & mode_yr_2011!=. ;


drop if mode_yr<=2002;

g post = 0;
replace post = 1 if year>mode_yr;


egen dists = cut(distance),at(0($bin)$bw); 
replace dists = dists+$bin;
replace dists = 0 if distance <0;
replace dists = $bw+$bin if dists==. & distance!=.;

sum dists;
global max = round(ceil(`r(max)'),100);
drop distance ;

** VARIABLE DEFINE;
g RDP=1 if rdp==1;
replace RDP=0 if rdp==2;
g DWELL=dwell==1;

g RDP_ORIG = 1 if rdp_orig==1;
replace RDP_ORIG = 0 if rdp_orig==2;


g RDP_WAIT = 1 if rdp_wt==1;
replace RDP_WAIT  = 0 if rdp_wt==2;


** SINGLE GRAPH OUTCOME ;
local outcome "RDP";

* import plotreg program;
do Code/GAUTENG/subcode/import_plotreg.do;

*destring ea_code, replace force;

reg  RDP_WAIT  b$max.dists#b0.post i.year i.mode_yr , cluster(cluster) robust ;
plotreg distplot distplot;




/*


global manygph=2;

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





/*
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

g low_rent = 0 if rent_cat>=0 & rent_cat<=2 & RDP==0;
replace low_rent = 1 if rent_cat>=3 & rent_cat<=7 & RDP==0;





