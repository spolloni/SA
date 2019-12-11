
clear 

set more off
set scheme s1mono

#delimit;

***************************************;
*  PROGRAMS TO OMIT VARS FROM GLOBAL  *;
***************************************;
cap program drop omit;
program define omit;

  local original ${`1'};
  local temp1 `0';
  local temp2 `1';
  local except: list temp1 - temp2;
  local modified;
  foreach e of local except{;
   local modified = " `modified' o.`e'"; 
  };
  local new: list original - except;
  local new " `modified' `new'";
  global `1' `new';

end;

cap program drop gen_het;
prog gen_het;
  sum cbd_dist, detail;
  g het = cbd_dist>= `=r(p50)' & cbd_dist<.;
end;

global data_load_place = 0;

global full_data_1996 = 0;
global full_data_2001 = 0;
global full_data_2011 = 0;
global aggregate      = 0;



global full_data_pers_1996 = 0;
global full_data_pers_2001 = 0;
global full_data_pers_2011 = 0;
global aggregate_pers      = 0;

global add_grids = 0;

global merge_place    = 0;





if $LOCAL==1 {;
	cd .. ;
};




* load data;
cd ../.. ;
cd Generated/Gauteng;

*****************************************************************;
************************ LOAD DATA ******************************;
*****************************************************************;




* cast(B.input_id AS TEXT) as sal_code_rdp, ; 
* cast(BP.input_id AS TEXT) as sal_code_placebo,;
* A.H23_Quarters AS quarters_typ,  A.H26a_Sourc_Water AS water_source, ;



if $data_load_place == 1 {;


local qry = " 

  SELECT 

  AA.*,

  CR.cbd_dist AS cbd_dist_rdp, CP.cbd_dist AS cbd_dist_placebo,

  GT.type AS type_rdp, GTP.type AS type_placebo

  FROM (

    SELECT 

      B.distance AS distance_rdp, B.target_id AS cluster_rdp, 
       BP.distance AS distance_placebo, BP.target_id AS cluster_placebo, 
      
      IR.area_int_rdp, IP.area_int_placebo, QQ.area,

      1996 AS year, EA.OGC_FID AS area_code,  XY.X, XY.Y, 

      SP.sp_1, SP.sal_1, SP.area_int

    FROM ea_1996 AS EA

    LEFT JOIN 
        (SELECT D.input_id, D.distance, D.target_id
          FROM distance_ea_1996_gcro${flink} AS D
          JOIN rdp_cluster AS R ON R.cluster = D.target_id
          WHERE D.distance<=4000
          GROUP BY D.input_id HAVING D.distance == MIN(D.distance)
        ) AS B ON EA.OGC_FID=B.input_id

    LEFT JOIN 
        (SELECT D.input_id, D.distance, D.target_id
          FROM distance_ea_1996_gcro${flink} AS D
          JOIN placebo_cluster AS R ON R.cluster = D.target_id
          WHERE D.distance<=4000
          GROUP BY D.input_id HAVING D.distance == MIN(D.distance)
        ) AS BP ON EA.OGC_FID=BP.input_id

    LEFT JOIN  
    (SELECT IT.OGC_FID, IT.area_int AS area_int_rdp
    FROM  int_gcro${flink}_ea_1996
    AS IT JOIN rdp_cluster AS PC ON PC.cluster = IT.cluster
    GROUP BY IT.OGC_FID
        HAVING IT.area_int = MAX(IT.area_int)
      )  
    AS IR ON IR.OGC_FID = EA.OGC_FID

    LEFT JOIN     
    (SELECT IT.OGC_FID, IT.area_int AS area_int_placebo 
    FROM  int_gcro${flink}_ea_1996 
    AS IT JOIN placebo_cluster AS PC ON PC.cluster = IT.cluster
    GROUP BY IT.OGC_FID
        HAVING IT.area_int = MAX(IT.area_int)
     )  
    AS IP ON IP.OGC_FID = EA.OGC_FID

    LEFT JOIN ea_1996_area AS QQ ON QQ.OGC_FID = EA.OGC_FID

    LEFT JOIN ea_1996_xy AS XY ON EA.OGC_FID = XY.OGC_FID

    LEFT JOIN  (SELECT * FROM ea_1996_s2001 AS G GROUP BY G.OGC_FID HAVING G.area_int==max(G.area_int)) AS SP ON EA.OGC_FID = SP.OGC_FID
 
  /* *** */
    UNION ALL
  /* *** */

  SELECT
      B.distance AS distance_rdp, B.target_id AS cluster_rdp, 
      BP.distance AS distance_placebo, BP.target_id AS cluster_placebo, 
      
      IR.area_int_rdp, IP.area_int_placebo, QQ.area,

      2001 AS year, SP.OGC_FID AS area_code,  XY.X, XY.Y, 

      SP.sp_code AS sp_1, SP.sal_code AS sal_1, 1 AS area_int

    FROM (SELECT sal_code AS SAL FROM sal_2001) AS A  

    LEFT JOIN 
        (SELECT D.input_id, D.distance, D.target_id, COUNT(D.input_id) AS count
          FROM distance_sal_2001_gcro${flink} AS D
          JOIN rdp_cluster AS R ON R.cluster = D.target_id
          WHERE D.distance<=4000
          GROUP BY D.input_id HAVING COUNT(D.input_id)<=50 AND D.distance == MIN(D.distance)
        ) AS B ON A.SAL=B.input_id

    LEFT JOIN 
        (SELECT D.input_id, D.distance, D.target_id, COUNT(D.input_id) AS count
          FROM distance_sal_2001_gcro${flink} AS D
          JOIN placebo_cluster AS R ON R.cluster = D.target_id
          WHERE D.distance<=4000
          GROUP BY D.input_id HAVING COUNT(D.input_id)<=50 AND D.distance == MIN(D.distance)
        ) AS BP ON A.SAL=BP.input_id

    LEFT JOIN  
    (SELECT IT.sal_code, IT.area_int AS area_int_rdp, IT.cluster  
    FROM  int_gcro${flink}_sal_2001 
    AS IT JOIN rdp_cluster AS PC ON PC.cluster = IT.cluster
    GROUP BY IT.sal_code
        HAVING IT.area_int = MAX(IT.area_int)
      )  
    AS IR ON IR.sal_code = A.SAL

    LEFT JOIN     
    (SELECT IT.sal_code, IT.area_int AS area_int_placebo, IT.cluster  
    FROM  int_gcro${flink}_sal_2001 
    AS IT JOIN placebo_cluster AS PC ON PC.cluster = IT.cluster
    GROUP BY IT.sal_code
        HAVING IT.area_int = MAX(IT.area_int)
     )  
    AS IP ON IP.sal_code = A.SAL

    LEFT JOIN area_sal_2001 AS QQ ON QQ.sal_code = A.SAL

    LEFT JOIN sal_2001_xy AS XY ON A.SAL = XY.sal_code

    LEFT JOIN sal_2001 AS SP ON A.SAL = SP.sal_code

    /* *** */
    UNION ALL 
    /* *** */

   SELECT 

      B.distance AS distance_rdp, B.target_id AS cluster_rdp, 
      BP.distance AS distance_placebo, BP.target_id AS cluster_placebo, 
      
      IR.area_int_rdp, IP.area_int_placebo, QQ.area,

      2011 AS year, A.OGC_FID AS area_code,  XY.X, XY.Y, 

      SP.sp_1, SP.sal_1, SP.area_int

    FROM (SELECT OGC_FID FROM sal_ea_2011) AS A  

      LEFT JOIN 
        (SELECT D.input_id, D.distance, D.target_id, COUNT(D.input_id) AS count
          FROM distance_sal_ea_2011_gcro${flink} AS D
          JOIN rdp_cluster AS R ON R.cluster = D.target_id
          WHERE D.distance<=4000
          GROUP BY D.input_id HAVING COUNT(D.input_id)<=50 AND D.distance == MIN(D.distance)
        ) AS B ON A.OGC_FID=B.input_id

      LEFT JOIN 
        (SELECT D.input_id, D.distance, D.target_id, COUNT(D.input_id) AS count
          FROM distance_sal_ea_2011_gcro${flink} AS D
          JOIN placebo_cluster AS R ON R.cluster = D.target_id
          WHERE D.distance<=4000
          GROUP BY D.input_id HAVING COUNT(D.input_id)<=50 AND D.distance == MIN(D.distance)
        ) AS BP ON A.OGC_FID=BP.input_id

    LEFT JOIN  
    (SELECT IT.OGC_FID, IT.area_int AS area_int_rdp, IT.cluster  
    FROM  int_gcro${flink}_sal_ea_2011 
    AS IT JOIN rdp_cluster AS PC ON PC.cluster = IT.cluster
    GROUP BY IT.OGC_FID
        HAVING IT.area_int = MAX(IT.area_int)
      )  
    AS IR ON IR.OGC_FID = A.OGC_FID

    LEFT JOIN     
    (SELECT IT.OGC_FID, IT.area_int AS area_int_placebo, IT.cluster  
    FROM  int_gcro${flink}_sal_ea_2011 
    AS IT JOIN placebo_cluster AS PC ON PC.cluster = IT.cluster
    GROUP BY IT.OGC_FID
        HAVING IT.area_int = MAX(IT.area_int)
     )  
    AS IP ON IP.OGC_FID = A.OGC_FID

    LEFT JOIN  (SELECT * FROM sal_ea_2011_s2001 AS G GROUP BY G.OGC_FID HAVING G.area_int==max(G.area_int)) AS SP ON A.OGC_FID = SP.OGC_FID

    LEFT JOIN sal_ea_2011_area AS QQ ON QQ.OGC_FID = A.OGC_FID

    LEFT JOIN sal_ea_2011_xy AS XY ON A.OGC_FID = XY.OGC_FID ) 

     AS AA

    LEFT JOIN cbd_dist${flink} AS CP ON CP.cluster = AA.cluster_placebo

    LEFT JOIN cbd_dist${flink} AS CR ON CR.cluster = AA.cluster_rdp

    LEFT JOIN gcro_type AS GTP ON GTP.OGC_FID = CP.cluster

    LEFT JOIN gcro_type AS GT ON GT.OGC_FID = CR.cluster

  ";


odbc query "gauteng";
odbc load, exec("`qry'") clear; 

destring *, replace force;  

drop if distance_rdp==. & distance_placebo==.;

destring cbd_dist_rdp cbd_dist_placebo, replace force;
g cbd_dist = cbd_dist_rdp ;
replace cbd_dist = cbd_dist_placebo if cbd_dist==. & cbd_dist_placebo!=. ;
drop cbd_dist_rdp cbd_dist_placebo ; 

save "DDcensus_hh_place_admin${V}.dta", replace;


};


if $full_data_1996 == 1 {;

local qry = " 

    SELECT   B.OGC_FID AS area_code, A.EACODE, 
      A.DWELLING AS dwelling_typ,
      A.ROOMS AS tot_rooms, A.OWNED AS tenure, A.WATER AS water_piped,
       A.TOILET AS toilet_typ, 
      A.FUELCOOK AS enrgy_cooking, A.FUELHEAT AS enrgy_heating,
      A.FUELLIGH AS enrgy_lighting, A.REFUSE AS refuse_typ, A.HHSIZE AS hh_size, 

      A.HOHSEX AS sex, A.HOHAGE AS age, A.HOHRACE as race, A.HOHECONA as emp, A.HHINCCAT as inc
    FROM census_hh_1996 AS A  

        JOIN ea_1996 AS B ON A.EACODE = B.polygonid " ;

odbc query "gauteng" ;
odbc load, exec("`qry'") clear ; 

destring area_code, replace force;
g year = 1996;

merge m:1 year area_code using "DDcensus_hh_place_admin${V}.dta"; 
keep if _merge==3; 
drop _merge; 

drop distance_rdp-type_placebo;



save "DDcensus_hh_full_1996_admin${V}.dta", replace ; 

};



if $full_data_2001 == 1 {;

local qry = " 

SELECT   B.OGC_FID AS area_code,   A.SAL,    A.H23_Quarters AS quarters_typ, A.H23a_HU AS dwelling_typ,
      A.H24_Room AS tot_rooms, A.H25_Tenure AS tenure, A.H26_Piped_Water AS water_piped,
      A.H26a_Sourc_Water AS water_source, A.H27_Toilet_Facil AS toilet_typ, 
      A.H28a_Cooking AS enrgy_cooking, A.H28b_Heating AS enrgy_heating,
      A.H28c_Lghting AS enrgy_lighting, A.H30_Refuse AS refuse_typ, A.DER2_HHSIZE AS hh_size, 

      P.sex, P.age, P.race, P.emp, P.inc 

      FROM census_hh_2001 AS A
        LEFT JOIN (SELECT SN, P02_Age AS age, P03_Sex AS sex, P22_Incm AS inc, DER10_EMPL_ST1 AS emp, P06_Race AS race FROM census_pers_2001 WHERE P04_Rel==1)  AS P  ON P.SN = A.SN
        JOIN sal_2001 AS B ON A.SAL = B.sal_code " ;

odbc query "gauteng" ;
odbc load, exec("`qry'") clear ; 

destring area_code, replace force;
g year = 2001;

merge m:1 year area_code using "DDcensus_hh_place_admin${V}.dta"; 
keep if _merge==3; 
drop _merge; 

drop distance_rdp-type_placebo;

save "DDcensus_hh_full_2001_admin${V}.dta", replace ; 

};

if $full_data_2011 == 1 {;

local qry = " 

    SELECT   B.OGC_FID AS area_code,   A.SAL_CODE,
      A.H01_QUARTERS AS quarters_typ, A.H02_MAINDWELLING AS dwelling_typ, 
      A.H03_TOTROOMS AS tot_rooms, A.H04_TENURE AS tenure, A.H07_WATERPIPED AS water_piped,
      A.H08_WATERSOURCE AS water_source, A.H10_TOILET AS toilet_typ, 
      A.H11_ENERGY_COOKING AS enrgy_cooking, A.H11_ENERGY_HEATING AS enrgy_heating,
      A.H11_ENERGY_LIGHTING AS enrgy_lighting, A.H12_REFUSE AS refuse_typ, A.DERH_HSIZE AS hh_size, 

      A.DERH_HHSEX AS sex, A.DERH_HHAGE AS age, A.DERH_HHPOP as race, A.DERH_HH_EMPLOY_STATUS as emp, A.DERH_INCOME_CLASS as inc

      FROM census_hh_2011 AS A

        JOIN sal_2011 AS B ON A.SAL_CODE = B.sal_code " ;

odbc query "gauteng" ;
odbc load, exec("`qry'") clear ; 

destring area_code, replace force;
g year = 2011;

merge m:1 year area_code using "DDcensus_hh_place_admin${V}.dta"; 
keep if _merge==3; 
drop _merge; 

drop distance_rdp-type_placebo;


save "DDcensus_hh_full_2011_admin${V}.dta", replace ; 

};



if $aggregate == 1 {;

use "DDcensus_hh_full_1996_admin${V}.dta", clear ;

append  using  "DDcensus_hh_full_2001_admin${V}.dta" ;
append  using  "DDcensus_hh_full_2011_admin${V}.dta" ;


replace age=. if age<10 | age>80; 
replace sex = 0 if sex == 1 | sex>=8 ;

ren emp emp_id ;
g emp = .;
replace emp = 1 if emp_id ==1 ;
replace emp = 0 if emp_id ==2 ;
drop emp_id;

g african = race==1;
drop race;

gen inc_value = . ;
replace inc_value = 0      if inc ==1 & year!=1996;
replace inc_value = 200    if inc ==2 & year!=1996;
replace inc_value = 600    if inc ==3 & year!=1996;
replace inc_value = 1200   if inc ==4 & year!=1996;
replace inc_value = 2400   if inc ==5 & year!=1996;
replace inc_value = 4800   if inc ==6 & year!=1996;
replace inc_value = 9600   if inc ==7 & year!=1996;
replace inc_value = 19200  if inc ==8 & year!=1996;
replace inc_value = 38400  if inc ==9 & year!=1996;
replace inc_value = 76800  if inc ==10 & year!=1996;
replace inc_value = 153600 if inc ==11 & year!=1996;
replace inc_value = 307200 if inc ==12 & year!=1996;

replace inc_value = 0      if inc ==1 & year==1996;
replace inc_value = 100    if inc ==2 & year==1996;
replace inc_value = 350    if inc ==3 & year==1996;
replace inc_value = 750    if inc ==4 & year==1996;
replace inc_value = 1250   if inc ==5 & year==1996;
replace inc_value = 2000   if inc ==6 & year==1996;
replace inc_value = 3000   if inc ==7 & year==1996;
replace inc_value = 4000   if inc ==8 & year==1996;
replace inc_value = 5250   if inc ==9 & year==1996;
replace inc_value = 7000   if inc ==10 & year==1996;
replace inc_value = 9500   if inc ==11 & year==1996;
replace inc_value = 13500  if inc ==12 & year==1996;
replace inc_value = 23000  if inc ==13 & year==1996;
replace inc_value = 50000  if inc ==14 & year==1996;
drop inc;
ren inc_value inc;

g ln_inc = log(inc);

replace inc = . if inc>100000; 

* flush toilet?;
gen toilet_flush = ((toilet_typ==1|toilet_typ==2) & year>=2001) | (toilet_typ==1 & year==1996) if !missing(toilet_typ);
lab var toilet_flush "Flush Toilet";

* piped water?;
gen water_inside = (water_piped==1 & year==1996)|(water_piped==1 & year==2011)|(water_piped==5 & year==2001) if !missing(water_piped);
lab var water_inside "Piped Water Inside";
gen water_yard = ((water_piped==1 | water_piped==2) & year==1996)|((water_piped==1 | water_piped==2) & year==2011)|((water_piped==5 | water_piped==4) & year==2001) if !missing(water_piped);
lab var water_yard "Piped Water Inside or Yard";

* water source?;
gen water_utility = (water_source==1) if !missing(water_source);
lab var water_utility "Water from utility";

* electricity?;
gen electricity = (enrgy_cooking==1 | enrgy_heating==1 | enrgy_lighting==1) if (enrgy_lighting!=. & enrgy_heating!=. & enrgy_cooking!=.);
lab var electricity "Access to electricity";
gen electric_cooking  = enrgy_cooking==1 if !missing(enrgy_cooking);
lab var electric_cooking "Electric Cooking";
gen electric_heating  = enrgy_heating==1 if !missing(enrgy_heating);
lab var electric_heating "Electric Heating";
gen electric_lighting = enrgy_lighting==1 if !missing(enrgy_lighting);
lab var electric_lighting "Electric Lighting";

* tenure?;
gen owner = ((tenure==1) & year==1996)|((tenure==2 | tenure==4) & year==2011)|((tenure==1 | tenure==2) & year==2001) if !missing(tenure);
lab var owner "Owns House";
 
g ten_owned = 0 if year>=2001;
replace ten_owned = 1 if (tenure==1 & year==2001) | (tenure==4 & year==2011) ;

g ten_debt = 0 if year>=2001;
replace ten_debt = 1 if (tenure==2 & year==2001) | (tenure==2 & year==2011) ;

g ten_rented = 0 if year>=2001;
replace ten_rented = 1 if (tenure==3 & year==2001) | (tenure==1 & year==2011) ;

g ten_free = 0 if year>=2001;
replace ten_free = 1 if (tenure==4 & year==2001) | (tenure==3 & year==2011) ;

* house?;
ren dwelling_typ dwelling_type;

gen house = dwelling_type==1 if !missing(dwelling_type);
gen traditional =dwelling_type==2 if !missing(dwelling_type);
gen flat = dwelling_type==3 if !missing(dwelling_type);
gen duplex = (dwelling_type==4 & (year==1996 | year==2001))|((dwelling_type==4 | dwelling_type==5 | dwelling_type==6) & year==2011) if !missing(dwelling_type);
gen house_bkyd =  (dwelling_type == 6 & year==1996)|(dwelling_type == 5 & year==2001)|(dwelling_type == 7 & year==2011)  if !missing(dwelling_type);
gen shack_bkyd =  (dwelling_type == 7 & year==1996)|(dwelling_type == 6 & year==2001)|(dwelling_type == 8 & year==2011)  if !missing(dwelling_type);
gen shack_non_bkyd =  (dwelling_type == 8 & year==1996)|(dwelling_type == 7 & year==2001)|(dwelling_type == 9 & year==2011)  if !missing(dwelling_type);
gen room_on_shared_prop = (dwelling_type == 9 & year==1996)|(dwelling_type == 8 & year==2001)|(dwelling_type == 10 & year==2011)  if !missing(dwelling_type);


* gen house_bkyd = (dwelling_type == 6 & year==1996)|(dwelling_type == 5 & year==2001)|(dwelling_type == 7 & year==2011)  if !missing(dwelling_type);
* lab var house_bkyd "House Backyard";

* gen shack_bkyd = (dwelling_type == 7 & year==1996)|(dwelling_type == 6 & year==2001)|(dwelling_type == 8 & year==2011)  if !missing(dwelling_type);
* lab var shack_bkyd "Shack Backyard";

* gen shack_non_bkyd = (dwelling_type == 8  & year==1996)|(dwelling_type == 7  & year==2001)|(dwelling_type == 9 & year==2011)  if !missing(dwelling_type);
* lab var shack_non_bkyd "Shack Non-Backyard";

foreach var of varlist house traditional flat duplex house_bkyd shack_bkyd shack_non_bkyd room_on_shared_prop {;
gegen `var'_dens = sum(`var'), by(area_code year) ;
g `var'_hh = `var'*hh_size ;
gegen `var'_dens_pers = sum(`var'_hh), by(area_code year) ;
drop `var'_hh;
};

* egen house_dens = sum(house), by(area_code year) ;
* * replace house_dens = (house_dens/area)*1000000 ;

* egen house_bkyd_dens = sum(house_bkyd), by(area_code year) ;
* * replace house_bkyd_dens = (house_bkyd_dens/area)*1000000 ;

* egen shack_bkyd_dens = sum(shack_bkyd), by(area_code year) ;
* * replace shack_bkyd_dens = (shack_bkyd_dens/area)*1000000 ;

* egen shack_non_bkyd_dens = sum(shack_non_bkyd), by(area_code year) ;
* * replace shack_non_bkyd_dens = (shack_non_bkyd_dens/area)*1000000 ;


* total rooms;
replace tot_rooms=. if tot_rooms>10 | tot_rooms==0;
lab var tot_rooms "No. Rooms";

* household size rooms;
replace hh_size=. if hh_size>14;
lab var hh_size "Household Size";

* household density;
g o = 1;
gegen  hh_pop = sum(o), by(area_code year);
*g hh_density = (hh_pop/area)*1000000;
*lab var hh_density "Households per km2";
drop o;

* pop density;
gegen  person_pop = sum(hh_size), by(area_code year);
*g pop_density = (person_pop/area)*1000000;
*lab var pop_density "People per km2";

g formal = house==1 | house_bkyd==1;
g informal = shack_bkyd==1 | shack_non_bkyd==1;

g for_id = house==1 | flat==1 | duplex==1 | room_on_shared_prop==1;
g inf_id = house==1 | shack_bkyd==1 | shack_non_bkyd==1 ;
g bkyd_id = house_bkyd==1 | shack_bkyd==1 ;
g n_bkyd_id = shack_non_bkyd==1;


foreach v in toilet_flush water_inside water_yard water_utility
  electricity electric_cooking electric_heating electric_lighting
  owner tot_rooms hh_size age sex emp african inc ln_inc   ten_rented ten_owned ten_free ten_debt { ;
  foreach ht in for_id inf_id bkyd_id n_bkyd_id {;
  g `v'_`ht' = `v' if `ht'==1 ;
  };
  }; 

fcollapse 
  (mean) 
      toilet_flush* water_inside* water_yard* water_utility*
      electricity* electric_cooking* electric_heating* electric_lighting*
      owner*  tot_rooms* hh_size*  age* sex*  emp* african*  inc* ln_inc*    ten_rented* ten_owned* ten_free* ten_debt*
      formal informal   house traditional flat duplex house_bkyd shack_bkyd shack_non_bkyd room_on_shared_prop  
  (firstnm) 
      hh_pop person_pop  house_dens traditional_dens flat_dens duplex_dens house_bkyd_dens shack_bkyd_dens shack_non_bkyd_dens room_on_shared_prop_dens
      house_dens_pers traditional_dens_pers flat_dens_pers duplex_dens_pers house_bkyd_dens_pers shack_bkyd_dens_pers shack_non_bkyd_dens_pers room_on_shared_prop_dens_pers
  , 
    by(area_code year);


save "temp_censushh_agg_no_place${V}.dta", replace;

* erase "DDcensus_hh_full_1996_admin${V}.dta";
* erase "DDcensus_hh_full_2001_admin${V}.dta";
* erase "DDcensus_hh_full_2011_admin${V}.dta";


};
*****************************************************************;
*****************************************************************;
*****************************************************************;

* exit, STATA clear;







if $full_data_pers_1996 == 1 {;

local qry = " 

    SELECT   B.OGC_FID AS area_code, A.EACODE, 
          A.SEX AS sex, A.AGE AS age,
        A.MARSTATU AS marit_stat, 
        A.RACE AS race, A.LANGUAG1 AS language, 
        A.INCOME AS income, A.DEDUCODE AS education,
        A.ECONACTT AS employment, 
        A.INDUSTR2 AS industry, A.OCCUPAT3 AS occupation

          FROM census_pers_1996 AS A 

        JOIN ea_1996 AS B ON A.EACODE = B.polygonid " ;

odbc query "gauteng" ;
odbc load, exec("`qry'") clear ; 

destring area_code, replace force;
g year = 1996;

fmerge m:1 year area_code using "DDcensus_hh_place_admin${V}.dta"; 
keep if _merge==3; 
drop _merge; 

drop distance_rdp-type_placebo;

save "DDcensus_pers_full_1996_admin${V}.dta", replace ; 

};



if $full_data_pers_2001 == 1 {;

local qry = " 

    SELECT   B.OGC_FID AS area_code,   A.SAL,     A.P03_Sex AS sex, A.P02_Age AS age, A.P04_Rel AS relation, 
        A.P02_Yr AS birth_yr, A.P05_Mar AS marit_stat, A.P06_Race AS race, 
        A.P07_lng AS language, A.P09a_Prv AS birth_prov, A.P22_Incm AS income, 
        A.P17_Educ AS education, A.DER10_EMPL_ST1 AS employment, 
        A.P19b_Ind AS industry, A.P19c_Occ as occupation

      FROM census_pers_2001 AS A

        JOIN sal_2001 AS B ON A.SAL = B.sal_code " ;

odbc query "gauteng" ;
odbc load, exec("`qry'") clear ; 

destring area_code, replace force;
g year = 2001;

fmerge m:1 year area_code using "DDcensus_hh_place_admin${V}.dta"; 
keep if _merge==3; 
drop _merge; 

drop distance_rdp-type_placebo;

save "DDcensus_pers_full_2001_admin${V}.dta", replace ; 

};

if $full_data_pers_2011 == 1 {;

local qry = " 

    SELECT   B.OGC_FID AS area_code,   A.SAL_CODE,
      A.F03_SEX AS sex, A.F02_AGE AS age, A.P02_RELATION AS relation, 
        A.P01_YEAR AS birth_yr, A.P03_MARITAL_ST AS marit_stat, 
        A.P05_POP_GROUP AS race, A.P06A_LANGUAGE AS language, 
        A.P07_PROV_POB AS birth_prov, 
        A.P16_INCOME AS income, A.P20_EDULEVEL AS education,
        A.DERP_EMPLOY_STATUS_OFFICIAL AS employment, 
        A.DERP_INDUSTRY AS industry, A.DERP_OCCUPATION AS occupation

      FROM census_pers_2011 AS A

        JOIN sal_2011 AS B ON A.SAL_CODE = B.sal_code " ;

odbc query "gauteng" ;
odbc load, exec("`qry'") clear ; 

destring area_code, replace force;
g year = 2011;

fmerge m:1 year area_code using "DDcensus_hh_place_admin${V}.dta"; 
* keep if _merge==3;
g merge_place = _merge; 
drop _merge; 

drop distance_rdp-type_placebo;


save "DDcensus_pers_full_2011_admin${V}.dta", replace ; 

};



if $aggregate_pers == 1 {;

use "DDcensus_pers_full_1996_admin${V}.dta", clear ;

append  using  "DDcensus_pers_full_2001_admin${V}.dta"  ;
append  using  "DDcensus_pers_full_2011_admin${V}.dta"  ;


* employment;
gen unemployed = .;
replace unemployed = 1 if employment ==2;
replace unemployed = 0 if employment ==1;

lab var unemployed "Unemployed";

* schooling;
gen educ_yrs = education + 1  if education<=12 & !missing(education);
replace educ_yrs = 0 if ((education==99 & (year ==2001 | year==1996))|(education==98 & year ==2011)) & !missing(education);
replace educ_yrs = 10 if (education==13) & !missing(education);
replace educ_yrs = 11 if (education== 14) & !missing(education);
replace educ_yrs = 12 if (education== 15) & !missing(education);
replace educ_yrs = 12.5 if (education==16) & !missing(education);
replace educ_yrs = 13 if (education==17) & !missing(education);
replace educ_yrs = 13.5 if (education==18) & !missing(education);
replace educ_yrs = 14 if (education==19) & !missing(education);
replace educ_yrs = 14 if (education==20) & !missing(education);
replace educ_yrs = 14 if (education==21) & !missing(education);
replace educ_yrs = 14 if (education==22) & !missing(education);
replace educ_yrs = 15 if (education==23) & !missing(education);
replace educ_yrs = 16 if (education==24) & !missing(education);
replace educ_yrs = 16 if (education==25) & !missing(education);
replace educ_yrs = 17 if (education==26) & !missing(education);
replace educ_yrs = 17 if (education==27) & !missing(education);
replace educ_yrs = 18 if (education==28) & !missing(education);
gen schooling_noeduc  = (education==99 & (year ==2001 | year==1996))|((education==98 | education==0) & year ==2011) if !missing(education);
gen schooling_postsec = (education>=12 & education<=30) if !missing(education) & age>=18;

* race;
gen black = (race==1) if !missing(race);

* born outside Gauteng;
gen outside_gp = (birth_prov!=7) if !missing(birth_prov);

* income;
gen inc_value = . ;
replace inc_value = 0      if income ==1 & year!=1996;
replace inc_value = 200    if income ==2 & year!=1996;
replace inc_value = 600    if income ==3 & year!=1996;
replace inc_value = 1200   if income ==4 & year!=1996;
replace inc_value = 2400   if income ==5 & year!=1996;
replace inc_value = 4800   if income ==6 & year!=1996;
replace inc_value = 9600   if income ==7 & year!=1996;
replace inc_value = 19200  if income ==8 & year!=1996;
replace inc_value = 38400  if income ==9 & year!=1996;
replace inc_value = 76800  if income ==10 & year!=1996;
replace inc_value = 153600 if income ==11 & year!=1996;
replace inc_value = 307200 if income ==12 & year!=1996;

replace inc_value = 0      if income ==1 & year==1996;
replace inc_value = 100    if income ==2 & year==1996;
replace inc_value = 350    if income ==3 & year==1996;
replace inc_value = 750    if income ==4 & year==1996;
replace inc_value = 1250   if income ==5 & year==1996;
replace inc_value = 2000   if income ==6 & year==1996;
replace inc_value = 3000   if income ==7 & year==1996;
replace inc_value = 4000   if income ==8 & year==1996;
replace inc_value = 5250   if income ==9 & year==1996;
replace inc_value = 7000   if income ==10 & year==1996;
replace inc_value = 9500   if income ==11 & year==1996;
replace inc_value = 13500  if income ==12 & year==1996;
replace inc_value = 23000  if income ==13 & year==1996;
replace inc_value = 50000  if income ==14 & year==1996;

gen inc_value_earners = inc_value ;
replace inc_value_earners = . if inc_value==0;
lab var inc_value_earners "HH Income";

* population;
g o = 1;
egen person_pop = sum(o), by(area_code year);
drop o;

fcollapse 
  (mean) unemployed educ_yrs black outside_gp age
  inc_value inc_value_earners schooling_noeduc schooling_postsec
  (firstnm) person_pop
  , by(area_code year);

save "temp_censuspers_agg_no_place${V}.dta", replace;

erase "DDcensus_pers_full_1996_admin${V}.dta";
erase "DDcensus_pers_full_2001_admin${V}.dta";
erase "DDcensus_pers_full_2011_admin${V}.dta";

};



if $add_grids == 1 {;

local qry = " 

    SELECT  *, 1996 as year FROM ea_1996_grid 
    UNION
    SELECT  *, 2001 as year FROM sal_2001_grid 
    UNION
    SELECT  *, 2011 as year FROM sal_2011_grid 
     ;
";


odbc query "gauteng" ;
odbc load, exec("`qry'") clear ; 

save "census_grid_link_simple.dta", replace;


merge m:1 grid_id using "buffer_grid_${dist_break_reg1}_${dist_break_reg2}_overlap.dta" ;
keep if _merge==3;
drop _merge;

save "census_grid_link.dta", replace;

};




if $merge_place == 1 {;

use "temp_censuspers_agg_no_place${V}.dta", clear;

fmerge 1:1 area_code year using "DDcensus_hh_place_admin${V}.dta";
* keep if _merge==3;
g merge_place = _merge;
drop _merge;

cd ../..;
cd $output;
save "temp_censuspers_agg${V}.dta", replace;


cd ../../../..;
cd Generated/GAUTENG;

use "temp_censushh_agg_no_place${V}.dta", clear;

fmerge 1:1 area_code year using "DDcensus_hh_place_admin${V}.dta";
* drop if _merge==1;
g merge_place = _merge;
drop _merge;

replace hh_pop=0 if hh_pop==.;
replace person_pop=0 if person_pop==.;
save "temp_censushh_agg${V}.dta", replace;

cd ../..;
cd $output;
save "temp_censushh_agg${V}.dta", replace;

};









/*

**** 1996 ****
* 1.4 Which type of dwelling does this household occupy? (If this household lives in MORE THAN ONE dwelling, circle the main type of dwelling.)
* House or brick structure on a separate stand or yard 1
* Traditional dwelling/hut/structure made of traditional materials 2
* Flat in block of flats 3
* Town/cluster/semi-detached house (simplex, duplex or triplex) 4
* Unit in retirement village 5
* House/flat/room, in backyard 6
* Informal dwelling/shack, in backyard 7
* Informal dwelling/shack, NOT in backyard, e.g. in an informal/squatter settlement 8
* Room/flatlet not in backyard but on a shared property 9
* Caravan/tent 10
* None/homeless 11
* Other, specify .....................................................................................................................................................................................................................................

**** 2001 ****
* Which type of dwelling or housing unit does this household occupy?
* If this household lives in MORE THAN ONE DWELLING, write the code of the MAIN
* dwelling that the household occupies in the boxes.
* 01 = House or brick structure on a separate stand or yard
* 02 = Traditional dwelling/hut/structure made of traditional
* materials
* 03 = Flat in block of flats
* 04 = Town/cluster/semi-detached house (simplex, duplex, triplex)
* 05 = House/flat/room in back yard
* 06 = Informal dwelling/shack in back yard
* 07 = Informal dwelling/shack NOT in back yard, e.g. in an
* informal/squatter settlement
* 08 = Room/flatlet not in back yard but on a shared property
* 09 = Caravan or tent
* 10 = Private ship/boat
* 11 = Other (specify

**** 2011 ****
* 1.4 Which type of dwelling does this household occupy? (If this household lives in MORE THAN ONE dwelling, circle the main type of dwelling.)
* House or brick structure on a separate stand or yard 1
* Traditional dwelling/hut/structure made of traditional materials 2
* Flat in block of flats 3
* CLUSTER HOUSE IN COMPLEX 4
* Townhouse/cluster/ (simplex, duplex or triplex) 5
* Semi-detached house 6
* House/flat/room, in backyard 7
* Informal dwelling/shack, in backyard 8
* Informal dwelling/shack, NOT in backyard, e.g. in an informal/squatter settlement 9
* Room/flatlet not in backyard but on a shared property 10
* Caravan/tent 11
* Other, specify .....................................................................................................................................................................................................................................




* 1996
* 1 Employed
* 2 Unemployed, looking for work
* 3 Not working - not looking for work
* 4 Not working - housewife/home-maker
* 6 Not working - scholar/full-time student
* 7 Not working - pensioner/retired person
* 8 Not working - disabled person
* 9 Not working - not wishing to work
* 10  Not working - none of the above
* 99  Unspecified/Dummy

* 2001 
* 00 Not applicable, aged less than 15 or older than 65 years
* 01 Employed
* 02 Unemployed
* 03 Not economically active

* 2011
* 1 = Employed
* 2 = Unemployed
* 3 = Discouraged work-seeker
* 4 = Other not economically active
*5=Household head out of working age scope i.e. 15-64

;




