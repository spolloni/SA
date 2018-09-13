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
    SELECT  AA.*,  GP.con_mo_placebo, GR.con_mo_rdp, GPL.con_mo_placebo AS con_mo_placebo_2011, GRL.con_mo_rdp AS con_mo_rdp_2011 
    FROM 
    (
    SELECT A.*,  
        B.distance AS distance_rdp, B.target_id AS cluster_rdp,   
        B.distance AS distance_rdp_2011, BL.target_id AS cluster_rdp_2011, 

      		 BP.distance AS distance_placebo, BP.target_id AS cluster_placebo,  
           BPL.distance AS distance_placebo_2011,    BPL.target_id AS cluster_placebo_2011,

           IR.area_int AS area_int_rdp, 
           IRL.area_int AS area_int_rdp_2011, 
           IP.area_int AS area_int_placebo, 
           IPL.area_int AS area_int_placebo_2011

    FROM ghs AS A
    
    LEFT JOIN (SELECT input_id, distance, target_id, COUNT(input_id) AS count 
    		FROM distance_ea_2001_rdp WHERE distance<=4000
  GROUP BY input_id HAVING COUNT(input_id)<=50 AND distance == MIN(distance)) 
    AS B ON A.ea_code=B.input_id

    LEFT JOIN (SELECT input_id, distance, target_id, COUNT(input_id) AS count 
    		FROM distance_ea_2001_placebo WHERE distance<=4000
  GROUP BY input_id HAVING COUNT(input_id)<=50 AND distance == MIN(distance)) 
    AS BP ON A.ea_code=BP.input_id


    LEFT JOIN (SELECT input_id, distance, target_id, COUNT(input_id) AS count 
        FROM distance_ea_2011_rdp WHERE distance<=4000
  GROUP BY input_id HAVING COUNT(input_id)<=50 AND distance == MIN(distance)) 
    AS BL ON A.ea_code=BL.input_id

    LEFT JOIN (SELECT input_id, distance, target_id, COUNT(input_id) AS count 
        FROM distance_ea_2001_placebo WHERE distance<=4000
  GROUP BY input_id HAVING COUNT(input_id)<=50 AND distance == MIN(distance)) 
    AS BPL ON A.ea_code=BPL.input_id

    LEFT JOIN int_rdp_ea_2001 AS IR ON IR.ea_code = A.ea_CODE
    LEFT JOIN int_placebo_ea_2001 AS IP ON IP.ea_code = A.ea_CODE
    LEFT JOIN int_rdp_ea_2011   AS IRL ON IRL.ea_code = A.ea_CODE
    LEFT JOIN int_placebo_ea_2011   AS IPL ON IPL.ea_code = A.ea_CODE
     ) 
    AS AA


    LEFT JOIN cluster_placebo AS GP ON AA.cluster_placebo = GP.cluster_placebo
  	LEFT JOIN cluster_rdp AS GR ON AA.cluster_rdp = GR.cluster_rdp

    LEFT JOIN cluster_placebo AS GPL ON AA.cluster_placebo_2011 = GPL.cluster_placebo
    LEFT JOIN cluster_rdp AS GRL ON AA.cluster_rdp_2011 = GRL.cluster_rdp
        
  ";

qui odbc query "gauteng";
odbc load, exec("`qry'") clear;

foreach var of varlist distance_rdp cluster_rdp distance_placebo cluster_placebo area_int_rdp area_int_placebo con_mo_placebo con_mo_rdp {;
destring `var' `var'_2011, replace force;
replace `var' = `var'_2011 if `var'==. & `var'_2011!=.;
drop `var'_2011;
};

save `temp_file', replace;
	};


use `temp_file', clear;


*** NEED TO DEAL WITH INTERSECTION!;

ren distance_rdp distance;

g month = 6;
g date = ym(year,month);


*g post = 0;
*replace post = 1 if (con_mo_rdp<. & con_mo_rdp>date) | (con_mo_placebo<. & con_mo_placebo>date);
***replace post = 1 if mo_date_rdp;


g post = date>615 & date<.;

destring area*, replace force;
g TREAT = area_int_rdp>.3 & area_int_rdp<.;

g PLACEBO = area_int_placebo>.3 & area_int_placebo<.;

g TREAT_post = TREAT*post;

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

destring cluster*, replace force;

g cluster_reg = cluster_rdp;
replace cluster_reg = cluster_placebo if cluster_reg==. & cluster_placebo!=.;


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

g high_rent = 0 if rent_cat>=0 & rent_cat<=2 & RDP==0;
replace high_rent = 1 if rent_cat>=3 & rent_cat<=7 & RDP==0;

g high_rent_rdp = 0 if rent_cat>=0 & rent_cat<=2 & RDP==1;
replace high_rent_rdp = 1 if rent_cat>=3 & rent_cat<=7 & RDP==1;

g single_house = dwell==1;

g old_house = build_yr>=5 & build_yr<=8;

destring ea_code, replace force;


reg  RDP TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, cluster(cluster_reg) robust ;
reg  RDP_ORIG TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, cluster(cluster_reg) robust ;
reg  RDP_WAIT TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, cluster(cluster_reg) robust ;

*reg  ln_r TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, cluster(cluster_reg) robust ;
*reg  ln_r_not TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, cluster(cluster_reg) robust ;
reg  high_rent TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, cluster(cluster_reg) robust ;
*reg  high_rent_rdp TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, cluster(cluster_reg) robust ;

reg  ln_p_not TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, cluster(cluster_reg) robust ;
reg  ln_p TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, cluster(cluster_reg) robust ;

reg  single_house TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, cluster(cluster_reg) robust ;


reg  old_house TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, cluster(cluster_reg) robust ;



* areg  RDP TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, a(ea_code) cluster(cluster_reg) robust ;
* areg  ln_r TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, a(ea_code)cluster(cluster_reg) robust ;
* areg  ln_r_not TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, a(ea_code) cluster(cluster_reg) robust ;
* areg  low_rent TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, a(ea_code) cluster(cluster_reg) robust ;
* areg  single_house TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, a(ea_code) cluster(cluster_reg) robust ;
* areg  old_house TREAT post TREAT_post if TREAT==1 |  PLACEBO==1, a(ea_code) cluster(cluster_reg) robust ;



*reg  RDP_ORIG TREAT post TREAT_post  if TREAT==1 | PLACEBO==1 , cluster(cluster_reg) robust ;
*reg  RDP_WAIT TREAT post TREAT_post  if TREAT==1 | PLACEBO==1, cluster(cluster_reg) robust ;







