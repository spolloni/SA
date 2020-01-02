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


global DATA_PREP = 1;
global temp_file="Generated/Gauteng/temp/plot_ghs_temp.dta";

if $LOCAL==1 {;
	cd ..;
};
cd ../..;

local qry =" SELECT * FROM ea_2001_grid ";
odbc query "gauteng";
odbc load, exec("`qry'") clear; 
save "Generated/Gauteng/temp/ea_2001_grid.dta", replace;



* if $DATA_PREP==1 {;

local qry = " 
  SELECT G.*, E.OGC_FID FROM ghs AS G
  JOIN ea_2001 AS E ON G.ea_code = E.ea_code
  ";


odbc query "gauteng";
odbc load, exec("`qry'") clear; 

foreach var of varlist poll_water poll_air poll_land poll_noise {;
  replace `var' = 0 if `var'!=1;
  };

g rdp_house = rdp==1;


g low_rent = rent_cat==1  ;

g rent_ghs = rent_cat if rent_cat<9 ;

g shack = dwell==7;
g bkyd_ghs = dwell==6;

g inf_ghs = dwell==8;

g bkydfor_ghs = dwell==9 ;

drop piped;
g piped_ghs = water_source==1;

g toi_shr = toilet_shr==1 ;

g har_id = 1 if harass==1 ; 
replace har_id = 0 if harass>1 & harass<9;


g hurt_id = 1 if hurt==1 ; 
replace hurt_id = 0 if hurt>1 & hurt<.;

g piped_dist = 0 if water_distance!=8 & water_distance!=. ;
replace piped_dist =1 if water_distance==8 ;


g toi_home_ghs = 0 if toilet_dist!=1 & toilet_dist!=. ;
replace toi_home_ghs =1 if toilet_dist==8 ;

g toi_dist = toilet_dist if toilet_dist<=3;

g elec_ghs = 0 if electricity!=1 & electricity!=. ;
replace elec_ghs =1 if electricity==1 ;


g post = year>=2010;

fcollapse 
(mean)
rdp_house low_rent shack bkyd_ghs inf_ghs bkydfor_ghs piped_ghs toi_shr 
har_id hurt_id piped_dist toi_home_ghs toi_dist elec_ghs 
poll_water poll_air poll_land poll_noise rent_ghs,
by(OGC_FID post) ;

save "Generated/Gauteng/temp/ghs_agg.dta", replace;




* merge m:1 OGC_FID using 





/*

merge m:1 ea_code using $temp_file ;
keep if _merge==3;
drop _merge;



g post = year>=mode_yr_rdp & mode_yr_rdp<.;


g pa = post*area_int_rdp  ;   


g rdp_house = rdp==1;

g house = dwell==1  ;  

g low_rent = rent_cat==1  ;

g shack = dwell==7;
g bkyd = dwell==6;

g inf = dwell==8;

g bkydfor = dwell==9 ;

g own = owner==1 ;

g piped = water_source==1;

g toi_shr = toilet_shr==1 ;

g har_id = 1 if harass==1 ; 
replace har_id = 0 if harass>1 & harass<9;


g hurt_id = 1 if hurt==1 ; 
replace hurt_id = 0 if hurt>1 & hurt<.;

g piped_dist = 0 if water_distance!=8 & water_distance!=. ;
replace piped_dist =1 if water_distance==8 ;


g toi_home = 0 if toilet_dist!=1 & toilet_dist!=. ;
replace toi_home =1 if toilet_dist==8 ;

g toi_dist = toilet_dist if toilet_dist<=3;


g elec = 0 if electricity!=1 & electricity!=. ;
replace elec =1 if electricity==1 ;




*** REPORT AS INFORMAL!~! PUSHED TO THE MARGINS.... ; 

duplicates drop uqnr year, force;


sort uqnr year
by uqnr: g cn=_n
egen fp = max(cn), by(uqnr)

tab cn year

egen min_yr_ea = min(year), by(ea_code)
egen max_yr_ea = max(year), by(ea_code)

g first_yr = year if cn==1

g fy_dev = first_yr-min_yr_ea


tab fy_dev
tab fp if cn==1

/*

tab fy_dev if fp==3


cap drop T 
g T = year-mode_yr_rdp
replace T = 99 if T>6

cap drop T1
g T1 = round(T,2)

egen mt= min(T), by(uqnr)
egen maxt=max(T), by(uqnr)

cap drop post1
g post1=T>=0 & T<99

g posty = year>=2010

* people surveyed before project ( minimum T <= 0 )

global temp_thresh = .5

sum rdp_house if area_int_rdp>.1 & area_int_rdp<. & year<mode_yr_rdp

sum rdp_house if area_int_rdp>.1 & area_int_rdp<. & year>mode_yr_rdp


cap drop proj
g proj = area_int_rdp>$temp_thresh & area_int_rdp<.

cap drop spill
g spill = proj==0 & distance_rdp<1000

* g control = proj==0 & spill==0


sum rdp_house if year<=2006 & proj==1
sum rdp_house if year>=2012 & proj==1


hist dwell_5 if proj==1 & dwell_5<10 & dwell==1, by(rdp_house)

tab dwell_5 if rdp_house==1





*** ONLY A 13% effect
areg house rdp_house i.year, a(uqnr) 
areg toi_shr  rdp_house i.year, a(uqnr)


* use GHS/2006/ghs-2006-v1.3-stata/ghs-2006-house-v1.3-20150127.dta, clear



tab dwell_5


hist dwell if dwell<10, by(rdp_house)



*** SPILL OVERS 
xi: areg piped i.year*i.proj i.year*i.spill if year<2014 & rdp_house==0,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg piped_dist i.year*i.proj i.year*i.spill if year<2014 & rdp_house==0,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))



xi: areg har_id i.year*i.proj i.year*i.spill if year<2014 & rdp_house==0,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))



xi: areg elec i.year*i.proj i.year*i.spill if year<2014 & rdp_house==0,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))


xi: areg roof_q i.year*i.proj i.year*i.spill if year<2014 & rdp_house==0 & roof_q<9,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg wall_q i.year*i.proj i.year*i.spill if year<2014 & rdp_house==0 & wall_q<9,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))




xi: areg toi_shr i.year*i.proj i.year*i.spill if year<2014 & rdp_house==0,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg toi_home i.year*i.proj i.year*i.spill if year<2014 & rdp_house==0 ,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg toi_dist i.year*i.proj i.year*i.spill if year<2014 & rdp_house==0 ,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))






xi: areg rdp_house i.year*i.proj i.year*i.spill ,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))




xi: areg house i.year*i.proj i.year*i.spill ,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg inf i.year*i.proj i.year*i.spill ,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg bkyd i.year*i.proj i.year*i.spill ,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg bkydfor i.year*i.proj i.year*i.spill ,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))

xi: areg shack i.year*i.proj i.year*i.spill ,  robust cluster(cluster_rdp) a(ea_code)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))



xi: reg rdp_house i.year*i.proj i.year*i.spill ,  robust cluster(cluster_rdp)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))



xi: reg rdp_house i.year*i.proj i.year*i.spill if mode_yr_rdp>2007 & mode_yr_rdp<.,  robust cluster(cluster_rdp)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))




xi: reg low_rent i.year*i.proj i.year*i.spill ,  robust cluster(cluster_rdp)
coefplot, vertical keep(_Iy*) xlabel(, angle(vertical))


xi: reg inf i.T1*i.proj i.T1*i.spill i.year ,  robust cluster(cluster_rdp)
coefplot, vertical keep(_IT1*) xlabel(, angle(vertical))


xi: reg inf i.post1*i.proj i.post1*i.spill i.year ,  robust cluster(cluster_rdp)


xi: reg low_rent i.post1*i.proj i.post1*i.spill i.year ,  robust cluster(cluster_rdp)



xi: reg rdp_house i.posty*i.proj i.posty*i.spill ,  robust cluster(cluster_rdp)




xi: areg rdp_house i.T*i.proj i.T*i.spill   i.year if fp==3 & (mt<=-1 & mt>=-2), a(uqnr) robust cluster(cluster_rdp)
coefplot, vertical keep(_IT*) xlabel(, angle(vertical))


xi: areg inf i.T*i.proj i.T*i.spill   i.year if (fp==3 & (mt<=-1 & mt>=-2)) | (fp==2 & mt==-1, a(uqnr) robust cluster(cluster_rdp)
coefplot, vertical keep(_IT*) xlabel(, angle(vertical))


tab T if fp==3 & mt>=-2 & mt<=-1 & proj==1

tab T if fp==3 & mt==-3 & proj==1



xi: reg shack i.T1*i.proj i.T1*i.spill i.year   ,  robust cluster(ea_code)

coefplot, vertical keep(_IT1*) xlabel(, angle(vertical))



xi: reg house i.T1*i.proj i.T1*i.spill i.year   ,  robust cluster(ea_code)

coefplot, vertical keep(_IT1*) xlabel(, angle(vertical))




xi: reg inf i.T1*i.proj i.T1*i.spill i.year  ,  robust cluster(ea_code)

coefplot, vertical keep(_IT1*) xlabel(, angle(vertical))





coefplot, vertical keep(_IT1Xp*) xlabel(, angle(vertical))


xi: areg rdp_house i.T1*i.proj i.T1*i.spill i.year  ,  robust cluster(ea_code) a(ea_code)

coefplot, vertical keep(_IT1*)




areg rdp_house i.T  i.year if area_int_rdp>.1 & area_int_rdp<. & cn==1, a(ea_code) robust cluster(ea_code)


sum rdp_house if area_int_rdp>.1 & area_int_rdp<.


sum rdp_house if area_int_rdp<.1 | area_int_rdp==.



xi: areg bkydfor i.T  i.year if area_int_rdp>.1 & area_int_rdp<. & fp==3 & (mt<=0 & mt>=-3), a(uqnr) robust


xi: areg house i.T  i.year if area_int_rdp>.1 & area_int_rdp<. & (fp==3 | fp==2) & (mt<=0 & mt>=-3), a(uqnr) robust


areg inf post1  i.year if area_int_rdp>.1 & area_int_rdp<. & fp==3 & (mt<=0 & mt>=-3), a(uqnr) robust cluster(ea_code)


xi: areg rdp_house i.T  i.year if area_int_rdp>.1 & area_int_rdp<. & cn==1, a(ea_code) robust cluster(ea_code)

coefplot, vertical keep(_IT_*) xlabel(, angle(vertical))





xi: areg inf i.T  i.year if area_int_rdp>.1 & area_int_rdp<. & fp==3 & (mt<=0 & mt>=-3), a(uqnr) robust cluster(ea_code)

coefplot, vertical keep(_IT_*) xlabel(, angle(vertical))


xi: areg inf i.T  i.year if fp==3 & (mt<=0 & mt>=-3), a(uqnr) robust cluster(ea_code)

coefplot, vertical keep(_IT_*) xlabel(, angle(vertical))




xi: areg house i.T  i.year if area_int_rdp>.1 & area_int_rdp<. & fp==3 & (mt<=3 & mt>=0), a(uqnr) robust

coefplot, vertical keep(_IT_*)


xi: areg inf i.T  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(uqnr) robust cluster(ea_code)


areg house post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(uqnr) robust cluster(ea_code)

areg inf post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(uqnr) robust cluster(ea_code)


areg house post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(uqnr) robust cluster(ea_code) 

areg inf post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(uqnr) robust cluster(ea_code)



xi: areg house i.T  i.year if area_int_rdp>.5 & area_int_rdp<. & mode_yr_rdp >2005  , a(uqnr) robust 

coefplot, vertical keep(_IT_*)



xi: areg shack i.T  i.year if area_int_rdp>.5 & area_int_rdp<. & mode_yr_rdp >2005  , a(uqnr) robust cluster(ea_code)

coefplot, vertical keep(_IT_*)




xi: areg inf i.T  i.year if area_int_rdp>.5 & area_int_rdp<. & mode_yr_rdp >2005  , a(uqnr) robust cluster(ea_code)

coefplot, vertical keep(_IT_*)


xi: areg house i.T  i.year if area_int_rdp>.5 & area_int_rdp<. & mode_yr_rdp >2005   , a(uqnr) robust cluster(ea_code)

coefplot, vertical keep(_IT_*)



xi: areg own i.T  i.year if area_int_rdp>.5 & area_int_rdp<. & mode_yr_rdp >2005   , a(uqnr) robust cluster(ea_code)

coefplot, vertical keep(_IT_*)


areg bkydfor post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(uqnr) robust

areg inf post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(uqnr) robust


areg shack post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(uqnr) robust

areg bkyd post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(uqnr) robust

areg house post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(uqnr) robust



areg rdp_house post  i.year if area_int_rdp>.8 & area_int_rdp<.  , a(uqnr) robust

areg house post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(uqnr) robust


areg house post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(uqnr) robust

areg inf post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(uqnr) robust


duplicates tag uqnr, g(D)


egen min_year = min(year), by(uqnr)



* areg house post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(ea_code) robust
* areg rdp_house post  i.year if area_int_rdp>.1 & area_int_rdp<.  , a(ea_code) robust



/*
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
        FROM distance_ea_2011_placebo WHERE distance<=4000
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


/*
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







