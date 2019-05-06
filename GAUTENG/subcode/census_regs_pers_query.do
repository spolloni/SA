clear 

set more off
set scheme s1mono

set max_memory 8g, permanently
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


* RUN LOCALLY?;
global LOCAL = 1;

* DOFILE SECTIONS;
global data_load_1996 = 1;
global data_load      = 0;
global data_prep      = 1;


if $LOCAL==1 {;
	cd ..;
};

* load data;
cd ../..;
cd Generated/Gauteng;

* "DDcensus_1996_admin${V}.dta" ; 


if $data_load_1996 == 1 {;


  local qry = " 

      SELECT 

        A.SEX AS sex, A.AGE AS age,
        A.MARSTATU AS marit_stat, 
        A.RACE AS race, A.LANGUAG1 AS language, 
        A.INCOME AS income, A.DEDUCODE AS education,
        A.ECONACTT AS employment, 
        A.INDUSTR2 AS industry, A.OCCUPAT3 AS occupation, A.EACODE

      FROM census_pers_1996 AS A 

    ";


  odbc query "gauteng";
  odbc load, exec("`qry'") clear;


  set seed 1;
  sample 60 ; 

  merge m:1 EACODE using "DDcensus_1996_admin${V}.dta" ;
  keep if _merge==3;
  drop _merge;

  destring area_int_placebo area_int_rdp cbd_dist_rdp cbd_dist_placebo, replace force;   /* throw out clusters that were too early in the process */

  save "DDcensus_pers_1996_temp${V}.dta", replace;


};


*****************************************************************;
************************ LOAD DATA ******************************;
*****************************************************************;
if $data_load==1 {;

*         cast(BP.input_id AS TEXT) as sal_code_placebo,  ;
*         cast(B.input_id AS TEXT) as sal_code_rdp,       ;


  local qry = " 

  	SELECT 

        AA.*, 

        (RANDOM()/(2*9223372036854775808)+.5) as random, 

      CR.cbd_dist AS cbd_dist_rdp, CP.cbd_dist AS cbd_dist_placebo,

        GT.type AS type_rdp, GTP.type AS type_placebo

    FROM (

      SELECT 

        A.F03_SEX AS sex, A.F02_AGE AS age, A.P02_RELATION AS relation, 
        A.P01_YEAR AS birth_yr, A.P03_MARITAL_ST AS marit_stat, 
        A.P05_POP_GROUP AS race, A.P06A_LANGUAGE AS language, 
        A.P07_PROV_POB AS birth_prov, 
        A.P16_INCOME AS income, A.P20_EDULEVEL AS education,
        A.DERP_EMPLOY_STATUS_OFFICIAL AS employment, 
        A.DERP_INDUSTRY AS industry, A.DERP_OCCUPATION AS occupation,


        B.distance AS distance_rdp, B.target_id AS cluster_rdp, 
        BP.distance AS distance_placebo, BP.target_id AS cluster_placebo, 

        IR.area_int_rdp, IP.area_int_placebo, QQ.area,

         2011 AS year, A.SAL_CODE AS area_code,  XY.X, XY.Y,

        SP.sp_1

      FROM census_pers_2011 AS A 

      LEFT JOIN 
        (SELECT D.input_id, D.distance, D.target_id, COUNT(D.input_id) AS count
          FROM distance_sal_2011_gcro${flink} AS D
          JOIN rdp_cluster AS R ON R.cluster = D.target_id
          WHERE D.distance<=2000
          GROUP BY D.input_id HAVING COUNT(D.input_id)<=50 AND D.distance == MIN(D.distance)
        ) AS B ON A.SAL_CODE=B.input_id

      LEFT JOIN 
        (SELECT D.input_id, D.distance, D.target_id, COUNT(D.input_id) AS count
          FROM distance_sal_2011_gcro${flink} AS D
          JOIN placebo_cluster AS R ON R.cluster = D.target_id
          WHERE D.distance<=2000
          GROUP BY D.input_id HAVING COUNT(D.input_id)<=50 AND D.distance == MIN(D.distance)
        ) AS BP ON A.SAL_CODE=BP.input_id

    LEFT JOIN  
    (SELECT IT.sal_code, IT.area_int AS area_int_rdp, IT.cluster  
    FROM  int_gcro${flink}_sal_2011 
    AS IT JOIN rdp_cluster AS PC ON PC.cluster = IT.cluster
    GROUP BY IT.sal_code
        HAVING IT.area_int = MAX(IT.area_int)
      )  
    AS IR ON IR.sal_code = A.SAL_CODE

    LEFT JOIN     
    (SELECT IT.sal_code, IT.area_int AS area_int_placebo, IT.cluster  
    FROM  int_gcro${flink}_sal_2011 
    AS IT JOIN placebo_cluster AS PC ON PC.cluster = IT.cluster
    GROUP BY IT.sal_code
        HAVING IT.area_int = MAX(IT.area_int)
     )  
    AS IP ON IP.sal_code = A.SAL_CODE

      LEFT JOIN area_sal_2011 AS QQ ON QQ.sal_code = A.SAL_CODE

      LEFT JOIN sal_2011_xy AS XY ON A.SAL_CODE = XY.sal_code

    LEFT JOIN  (SELECT * FROM sal_2011_s2001 AS G GROUP BY G.sal_code HAVING G.area_int==max(G.area_int)) AS SP ON A.SAL_CODE = SP.sal_code


    ) AS AA

    LEFT JOIN (
      SELECT cluster_placebo, con_mo_placebo 
      FROM cluster_placebo
    ) AS GP ON AA.cluster_placebo = GP.cluster_placebo

    LEFT JOIN (
      SELECT cluster_rdp, con_mo_rdp 
      FROM cluster_rdp
    ) AS GR ON AA.cluster_rdp = GR.cluster_rdp

  LEFT JOIN cbd_dist${flink} AS CP ON CP.cluster = AA.cluster_placebo

  LEFT JOIN cbd_dist${flink} AS CR ON CR.cluster = AA.cluster_rdp

  LEFT JOIN gcro_type AS GTP ON GTP.OGC_FID = CP.cluster

  LEFT JOIN gcro_type AS GT ON GT.OGC_FID = CR.cluster
  
    WHERE NOT (distance_rdp IS NULL AND distance_placebo IS NULL) AND random < .6
    ";


  odbc query "gauteng";
  odbc load, exec("`qry'") clear;


  destring area_int_placebo area_int_rdp cbd_dist_rdp cbd_dist_placebo, replace force;   /* throw out clusters that were too early in the process */

  save "DDcensus_pers_admin_het_2011${V}.dta", replace;



  local qry = " 

    SELECT 

        AA.*, 

        (RANDOM()/(2*9223372036854775808)+.5) as random, 

      CR.cbd_dist AS cbd_dist_rdp, CP.cbd_dist AS cbd_dist_placebo, 
        
      GT.type AS type_rdp, GTP.type AS type_placebo


    FROM (

      SELECT 

        A.P03_Sex AS sex, A.P02_Age AS age, A.P04_Rel AS relation, 
        A.P02_Yr AS birth_yr, A.P05_Mar AS marit_stat, A.P06_Race AS race, 
        A.P07_lng AS language, A.P09a_Prv AS birth_prov, A.P22_Incm AS income, 
        A.P17_Educ AS education, A.DER10_EMPL_ST1 AS employment, 
        A.P19b_Ind AS industry, A.P19c_Occ as occupation, 

        B.distance AS distance_rdp, B.target_id AS cluster_rdp, 
        BP.distance AS distance_placebo, BP.target_id AS cluster_placebo, 

        IR.area_int_rdp, IP.area_int_placebo, QQ.area,

        2001 AS year, A.SAL AS area_code,  XY.X, XY.Y, 

          SP.sp_code AS sp_1

      FROM census_pers_2001 AS A 

    LEFT JOIN 
        (SELECT D.input_id, D.distance, D.target_id, COUNT(D.input_id) AS count
          FROM distance_sal_2001_gcro${flink} AS D
          JOIN rdp_cluster AS R ON R.cluster = D.target_id
          WHERE D.distance<=2000
          GROUP BY D.input_id HAVING COUNT(D.input_id)<=50 AND D.distance == MIN(D.distance)
        ) AS B ON A.SAL=B.input_id

    LEFT JOIN 
        (SELECT D.input_id, D.distance, D.target_id, COUNT(D.input_id) AS count
          FROM distance_sal_2001_gcro${flink} AS D
          JOIN placebo_cluster AS R ON R.cluster = D.target_id
          WHERE D.distance<=2000
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

      LEFT JOIN sal_2001_xy AS XY ON A.SAL = XY.sal_code

      LEFT JOIN area_sal_2001 AS QQ ON QQ.sal_code = A.SAL

          LEFT JOIN sal_2001 AS SP ON A.SAL = SP.sal_code

    ) AS AA

  LEFT JOIN cbd_dist${flink} AS CP ON CP.cluster = AA.cluster_placebo

  LEFT JOIN cbd_dist${flink} AS CR ON CR.cluster = AA.cluster_rdp

  LEFT JOIN gcro_type AS GTP ON GTP.OGC_FID = CP.cluster

  LEFT JOIN gcro_type AS GT ON GT.OGC_FID = CR.cluster

    WHERE NOT (distance_rdp IS NULL AND distance_placebo IS NULL)
    AND random < .6

    ";
    

  odbc query "gauteng";
  odbc load, exec("`qry'") clear;


  destring area_int_placebo area_int_rdp cbd_dist_rdp cbd_dist_placebo, replace force;   /* throw out clusters that were too early in the process */

  		
  save "DDcensus_pers_admin_het_2001${V}.dta", replace;


  use "DDcensus_pers_admin_het_2001${V}.dta", clear ;

    append using "DDcensus_pers_admin_het_2011${V}.dta" ;

  save "DDcensus_pers_admin_het${V}.dta", replace ;


  erase "DDcensus_pers_admin_het_2001${V}.dta" ;
  erase "DDcensus_pers_admin_het_2011${V}.dta" ;

};
*****************************************************************;
*****************************************************************;
*****************************************************************;

*****************************************************************;
************************ PREPARE DATA ***************************;
*****************************************************************;
if $data_prep==1 {;

use "DDcensus_pers_admin_het${V}.dta", clear;

append using "DDcensus_pers_1996_temp${V}.dta"; 

replace area_code = EACODE if year==1996;


* go to working dir;
cd ../..;
cd $output ;


destring cbd_dist_rdp, replace force;
g cbd_dist = cbd_dist_rdp;
replace cbd_dist = cbd_dist_placebo if cbd_dist_rdp==. & cbd_dist_placebo!=.;

g het = 0 if cbd_dist>${het} & cbd_dist<. ;
replace het = 1 if cbd_dist<=${het} ;

* employment;
gen unemployed = .;
replace unemployed = 1 if employment ==2;
replace unemployed = 0 if employment ==1;

lab var unemployed "Unemployed";

* schooling;
gen educ_yrs = education + 1  if education<=12 & !missing(education);
replace educ_yrs = 0 if ((education==99 & (year ==2001 | year==1996))|(education==98 & year ==2011)) & !missing(education);
replace educ_yrs = 10 if (education==13) & !missing(education);
replace educ_yrs = 11 if (education==14) & !missing(education);
replace educ_yrs = 12 if (education==15) & !missing(education);
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

* cluster for SEs;
replace area_int_rdp =0 if area_int_rdp ==.;
replace area_int_placebo =0 if area_int_placebo ==.;
gen placebo = (distance_placebo < distance_rdp);
gen placebo2 = (area_int_placebo> area_int_rdp);
replace placebo = 1 if placebo2==1;
drop placebo2;
gen distance_joined = cond(placebo==1, distance_placebo, distance_rdp);
gen cluster_joined  = cond(placebo==1, cluster_placebo, cluster_rdp);

collapse 
  (mean) unemployed educ_yrs black outside_gp age
  inc_value inc_value_earners schooling_noeduc schooling_postsec
  (firstnm) person_pop area_int_rdp area_int_placebo placebo
  distance_joined cluster_joined distance_rdp distance_placebo cluster_rdp cluster_placebo het type_rdp type_placebo X Y sp_1 area
  , by(area_code year);

save "temp_censuspers_agg_het${V}.dta", replace;


};








