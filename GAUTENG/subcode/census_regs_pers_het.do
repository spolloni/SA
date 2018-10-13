clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
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

******************;
*  CENSUS REGS   *;
******************;

* SET OUTPUT GLOBAL;
*global output = "Output/GAUTENG/censusregs" ;
 global output = "Code/GAUTENG/paper/figures";
* global output = "Code/GAUTENG/presentations/presentation_lunch";

* RUN LOCALLY?;
global LOCAL = 1;

* DOFILE SECTIONS;
global data_load = 0;
global data_prep = 1;
global data_regs = 1;

* PARAMETERS;
global drop_others= 1   ; /* everything relative to unconstructed */
global tresh_area = 0.3 ; /* Area ratio for "inside" vs spillover */
global tresh_dist = 1500; /* Area ratio inside vs spillover */

if $LOCAL==1 {;
	cd .. ;
};

* load data;
cd ../.. ;
cd Generated/Gauteng;

*****************************************************************;
************************ LOAD DATA ******************************;
*****************************************************************;
if $data_load==1 {;

local qry = " 

  SELECT 

  AA.*, (RANDOM()/(2*9223372036854775808)+.5) as random, 

  GP.con_mo_placebo, GR.con_mo_rdp, 

  CR.cbd_dist AS cbd_dist_rdp, CP.cbd_dist AS cbd_dist_placebo

  FROM (

    SELECT 

          A.P03_Sex AS sex, A.P02_Age AS age, A.P04_Rel AS relation, A.P02_Yr AS birth_yr,
           A.P05_Mar AS marit_stat, A.P06_Race AS race, A.P07_lng AS language, P09a_Prv AS birth_prov,
           A.P22_Incm AS income, P17_Educ AS education, A.DER10_EMPL_ST1 AS employment, 
           A.P19b_Ind AS industry, A.P19c_Occ as occupation, 

      cast(B.input_id AS TEXT) as sal_code_rdp, B.distance AS distance_rdp, B.target_id AS cluster_rdp, 
      cast(BP.input_id AS TEXT) as sal_code_placebo, BP.distance AS distance_placebo, BP.target_id AS cluster_placebo, 
      
      IR.area_int_rdp, IP.area_int_placebo, QQ.area,

      'census2001pers' AS source, 2001 AS year, A.SAL AS area_code

    FROM census_pers_2001 AS A  

    LEFT JOIN (
      SELECT input_id, distance, target_id, COUNT(input_id) AS count 
      FROM distance_sal_2001_rdp WHERE distance<=4000
      GROUP BY input_id 
      HAVING COUNT(input_id)<=50 
        AND distance == MIN(distance)
    ) AS B ON A.SAL=B.input_id

    LEFT JOIN (
      SELECT input_id, distance, target_id, COUNT(input_id) AS count 
      FROM distance_sal_2001_placebo 
      WHERE distance<=4000
      GROUP BY input_id 
      HAVING COUNT(input_id)<=50 
        AND distance == MIN(distance)
    ) AS BP ON A.SAL=BP.input_id

    LEFT JOIN (
      SELECT sal_code, area_int AS area_int_rdp 
      FROM int_rdp_sal_2001
    ) AS IR ON IR.sal_code = A.SAL

    LEFT JOIN (
      SELECT sal_code, area_int AS area_int_placebo 
      FROM int_placebo_sal_2001
    ) AS IP ON IP.sal_code = A.SAL

    LEFT JOIN area_sal_2001 AS QQ ON QQ.sal_code = A.SAL

    /* *** */
    UNION ALL 
    /* *** */

    SELECT 

           A.F03_SEX AS sex, A.F02_AGE AS age, A.P02_RELATION AS relation, A.P01_YEAR AS birth_yr,
           A.P03_MARITAL_ST AS marit_stat, A.P05_POP_GROUP AS race, A.P06A_LANGUAGE AS language,
           A.P07_PROV_POB AS birth_prov, A.P16_INCOME AS income, A.P20_EDULEVEL AS education,
           A.DERP_EMPLOY_STATUS_OFFICIAL AS employment, A.DERP_INDUSTRY AS industry, A.DERP_OCCUPATION AS occupation,

      cast(B.input_id AS TEXT) as sal_code_rdp, B.distance AS distance_rdp, B.target_id AS cluster_rdp, 
      cast(BP.input_id AS TEXT) as sal_code_placebo, BP.distance AS distance_placebo, BP.target_id AS cluster_placebo, 
      
      IR.area_int_rdp, IP.area_int_placebo, QQ.area,

      'census2011pers' AS source, 2011 AS year, A.SAL_CODE AS area_code

    FROM census_pers_2011 AS A  

    LEFT JOIN (
      SELECT input_id, distance, target_id, COUNT(input_id) AS count 
      FROM distance_sal_2011_rdp 
      WHERE distance<=4000
      GROUP BY input_id 
      HAVING COUNT(input_id)<=50 
        AND distance == MIN(distance)
    ) AS B ON A.SAL_CODE=B.input_id

    LEFT JOIN (
      SELECT input_id, distance, target_id, COUNT(input_id) AS count 
      FROM distance_sal_2011_placebo 
      WHERE distance<=4000
      GROUP BY input_id HAVING COUNT(input_id)<=50 
      AND distance == MIN(distance)
    ) AS BP ON A.SAL_CODE=BP.input_id

    LEFT JOIN (
      SELECT sal_code, area_int AS area_int_rdp
      FROM int_rdp_sal_2011
    ) AS IR ON IR.sal_code = A.SAL_CODE

    LEFT JOIN (
      SELECT sal_code, area_int AS area_int_placebo 
      FROM int_placebo_sal_2011
    ) AS IP ON IP.sal_code = A.SAL_CODE

    LEFT JOIN area_sal_2011 AS QQ ON QQ.sal_code = A.SAL_CODE

  ) AS AA

  LEFT JOIN (
    SELECT cluster_placebo, con_mo_placebo 
    FROM cluster_placebo
  ) AS GP ON AA.cluster_placebo = GP.cluster_placebo

  LEFT JOIN (
    SELECT cluster_rdp, con_mo_rdp 
    FROM cluster_rdp
  ) AS GR ON AA.cluster_rdp = GR.cluster_rdp

  LEFT JOIN cbd_dist AS CP ON CP.cluster = AA.cluster_placebo

  LEFT JOIN cbd_dist AS CR ON CR.cluster = AA.cluster_rdp

    WHERE random < .25

  ";

odbc query "gauteng";
odbc load, exec("`qry'") clear;	

destring area_int_placebo area_int_rdp, replace force;  

/* throw out clusters that were too early in the process */
replace distance_placebo =.  if con_mo_placebo<515 | con_mo_placebo==.;
replace area_int_placebo =.  if con_mo_placebo<515 | con_mo_placebo==.;
replace sal_code_placebo ="" if con_mo_placebo<515 | con_mo_placebo==.;
replace cluster_placebo  =.  if con_mo_placebo<515 | con_mo_placebo==.;

replace distance_rdp =.  if con_mo_rdp<515 | con_mo_rdp==.;
replace area_int_rdp =.  if con_mo_rdp<515 | con_mo_rdp==.;
replace sal_code_rdp ="" if con_mo_rdp<515 | con_mo_rdp==.;
replace cluster_rdp  =.  if con_mo_rdp<515 | con_mo_rdp==.;

drop if distance_rdp==. & distance_placebo==.;

destring cbd_dist_rdp cbd_dist_placebo, replace force;
g cbd_dist = cbd_dist_rdp ;
replace cbd_dist = cbd_dist_placebo if cbd_dist==. & cbd_dist_placebo!=. ;
drop cbd_dist_rdp cbd_dist_placebo ; 

save DDcensus_pers_het, replace;

};
*****************************************************************;
*****************************************************************;
*****************************************************************;

*****************************************************************;
************************ PREPARE DATA ***************************;
*****************************************************************;
if $data_prep==1 {;

use DDcensus_pers_het, clear;

* go to working dir;
cd ../..;
cd $output;


* employment;
gen unemployed = .;
replace unemployed = 1 if employment ==2;
replace unemployed = 0 if employment ==1;

lab var unemployed "Unemployed";

* schooling;
gen schooling_noeduc  = (education==99 & year ==2001)|(education==98 & year ==2011) if !missing(education);
gen schooling_hschool = (education>=0 & education<=12) if !missing(education);
lab var schooling_hschool "Over HS Educ." ;
replace schooling_hschool=. if unemployed==.;

* race;
gen black = (race==1) if !missing(race);

* income;
gen inc_value = . ;
replace inc_value = 0      if income ==1;
replace inc_value = 200    if income ==2;
replace inc_value = 600    if income ==3;
replace inc_value = 1200   if income ==4;
replace inc_value = 2400   if income ==5;
replace inc_value = 4800   if income ==6;
replace inc_value = 9600   if income ==7;
replace inc_value = 19200  if income ==8;
replace inc_value = 38400  if income ==9;
replace inc_value = 76800  if income ==10;
replace inc_value = 153600 if income ==11;
replace inc_value = 307200 if income ==12;
gen inc_value_earners = inc_value ;
replace inc_value_earners = . if inc_value==0;
lab var inc_value_earners "HH Income";


* cluster for SEs;
replace area_int_rdp =0 if area_int_rdp ==.;
replace area_int_placebo =0 if area_int_placebo ==.;
gen placebo = (distance_placebo < distance_rdp);
gen placebo2 = (area_int_placebo> area_int_rdp);
replace placebo = 1 if placebo2==1;
drop placebo2;
gen distance_joined = cond(placebo==1, distance_placebo, distance_rdp);

gen cluster_joined  = cond(placebo==1, cluster_placebo, cluster_rdp);

};
*****************************************************************;
*****************************************************************;
*****************************************************************;

*****************************************************************;
********************* RUN REGRESSIONS ***************************;
*****************************************************************;
if $data_regs==1 {;

gen_het;

g project_rdp = (area_int_rdp > $tresh_area);
g project_placebo = (area_int_placebo > $tresh_area);
g project = (project_rdp==1 | project_placebo==1);
g project_post = project ==1 & year==2011;
g project_post_rdp = project_rdp ==1 & year==2011;
g spillover_rdp = project_rdp!=1 & distance_rdp<= $tresh_dist;
g spillover_placebo = project_placebo!=1 & distance_placebo<= $tresh_dist;
g spillover = (spillover_rdp==1 | spillover_placebo==1);
g spillover_post = spillover == 1 & year==2011;
g spillover_post_rdp = spillover_rdp==1 & year==2011;
g others = project !=1 & spillover !=1;
g others_post = others==1 & year==2011;

drop if others==1;

global regressors "
  project_post_rdp
  project_post
  project_rdp
  project
  spillover_post_rdp
  spillover_post
  spillover_rdp
  ";

foreach v in $regressors {;
g `v'_het = `v'*het;
replace `v' = 0 if het==1;
};
foreach v in spillover {;
g `v'_het = `v'*het;
replace `v' = 0 if het==1;
};

global regressors "
  project_post_rdp
  project_post
  project_rdp
  project
  spillover_post_rdp
  spillover_post
  spillover_rdp

  project_post_rdp_het
  project_post_het
  project_rdp_het
  project_het
  spillover_post_rdp_het
  spillover_post_het
  spillover_rdp_het
  spillover_het
  ";

global outcomes1 "
unemployed schooling_noeduc schooling_hschool inc_value inc_value_earners black
  ";

lab var project_rdp "Close Proj X Const.";
lab var project_placebo "Close Proj X Unconst.";
lab var project "Close Proj";
lab var project_post "Close Proj X Post";
lab var project_post_rdp "Close Proj X Post X Const.";

lab var spillover_rdp "Close Spill X Const.";
lab var spillover_placebo "Close Spill X Unconst.";
lab var spillover "Close Spill";
lab var spillover_post "Close Spill X Post";
lab var spillover_post_rdp "Close Spill X Post X Const.";
lab var others "Outside";
lab var others_post "Outside Post";

lab var project_het "Far Proj";
lab var project_rdp_het "Far Proj X Const.";
lab var project_post_het "Far Proj X Post";
lab var project_post_rdp_het "Far Proj X Post X Const.";

lab var spillover_het "Far Spill";
lab var spillover_rdp_het "Far Spill X Const.";
lab var spillover_post_het "Far Spill X Post";
lab var spillover_post_rdp_het "Far Spill X Post X Const.";


eststo clear;


local mtitles " ";
foreach var of varlist $outcomes1 {;
  local mtitles " `mtitles' "`var'" ";
  areg `var' $regressors , a(cluster_joined) cl(cluster_joined);

  sum `var' if e(sample)==1 & year ==2001, detail;
  estadd scalar Mean2001 = `=r(mean)';
  sum `var' if e(sample)==1 & year ==2011, detail;
  estadd scalar Mean2011 = `=r(mean)';

  eststo `var';
};

esttab $outcomes1  using census_pers_DDregs_het,
  replace  b(%12.3fc) se(%12.3fc) r2(%12.3fc) r2 tex label
  mtitles(`mtitles')
  star(* 0.10 ** 0.05 *** 0.01)  stats(N Mean2001 Mean2011)
  compress;


};
*****************************************************************;
*****************************************************************;
*****************************************************************;

* exit, STATA clear;

