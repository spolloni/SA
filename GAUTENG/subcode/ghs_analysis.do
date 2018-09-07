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
global DATA_PREP = 0;
	local temp_file "Generated/Gauteng/temp/plot_ghs_temp.dta";

if $LOCAL==1 {;
	cd ..;
};
cd ../..;

if $DATA_PREP==1 {;
  
local qry = "
    SELECT  AA.*,  GP.mo_date_placebo, GR.mo_date_rdp
    FROM 
    (
    SELECT A.*,  B.distance AS distance_rdp, B.target_id AS cluster_rdp, 
      		 BP.distance AS distance_placebo, BP.target_id AS cluster_placebo, 
           area_int_rdp, area_int_placebo

    FROM ghs AS A
    
    LEFT JOIN (SELECT input_id, distance, target_id, COUNT(input_id) AS count 
    		FROM distance_ea_2011_rdp WHERE distance<=4000
  GROUP BY input_id HAVING COUNT(input_id)<=50 AND distance == MIN(distance)) 
    AS B ON A.ea_code=B.input_id

    LEFT JOIN (SELECT input_id, distance, target_id, COUNT(input_id) AS count 
    		FROM distance_ea_2011_placebo WHERE distance<=4000
  GROUP BY input_id HAVING COUNT(input_id)<=50 AND distance == MIN(distance)) 
    AS BP ON A.ea_code=BP.input_id

    LEFT JOIN (SELECT ea_code, area_int AS area_int_rdp     FROM int_rdp_ea_2011)     AS IR ON IR.ea_code = A.ea_CODE
    LEFT JOIN (SELECT ea_code, area_int AS area_int_placebo FROM int_placebo_ea_2011) AS IP ON IP.ea_code = A.ea_CODE
     ) 
    AS AA


    LEFT JOIN (SELECT cluster_placebo, mo_date_placebo FROM cluster_placebo) AS GP ON AA.cluster_placebo = GP.cluster_placebo
  	LEFT JOIN (SELECT cluster_rdp, mo_date_rdp FROM cluster_rdp) AS GR ON AA.cluster_rdp = GR.cluster_rdp    
  ";


  


qui odbc query "gauteng";
odbc load, exec("`qry'") clear;

save `temp_file', replace;
	};


use `temp_file', clear;

*** NEED TO DEAL WITH INTERSECTION!;

ren distance_rdp distance;

g month = 6;
g date = ym(year,month);

g post = 0;
replace post = 1 if mo_date_rdp>date;


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





