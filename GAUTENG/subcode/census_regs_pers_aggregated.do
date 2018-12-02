clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
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

******************;
*  CENSUS REGS   *;
******************;

* SET OUTPUT GLOBAL;
 global output = "Output/GAUTENG/censusregs" ;
* global output = "Code/GAUTENG/paper/figures" ;
*global output = "Code/GAUTENG/presentations/presentation_lunch";

* RUN LOCALLY?;
global LOCAL = 1;

* DOFILE SECTIONS;
global data_load = 0;
global data_prep = 0;
global data_stat = 0;
global data_regs = 1;
global data_regs_DDD = 0;

* PARAMETERS;
global drop_others= 1; /* everything relative to unconstructed */
global tresh_area = 0.3; /* Area ratio for "inside" vs spillover */
global tresh_dist = 1500; /* Area ratio inside vs spillover */

global tresh_area_DDD = 0.75;
global tresh_dist_DDD = 400;
global tresh_dist_max_DDD = 1200;

if $LOCAL==1 {;
	cd ..;
};

* load data;
cd ../..;
cd Generated/Gauteng;

*****************************************************************;
************************ LOAD DATA ******************************;
*****************************************************************;
if $data_load==1 {;

  local qry = " 

  	SELECT 

        AA.*, GP.con_mo_placebo, GR.con_mo_rdp,

        (RANDOM()/(2*9223372036854775808)+.5) as random 

    FROM (

      SELECT 

        A.P03_Sex AS sex, A.P02_Age AS age, A.P04_Rel AS relation, 
        A.P02_Yr AS birth_yr, A.P05_Mar AS marit_stat, A.P06_Race AS race, 
        A.P07_lng AS language, A.P09a_Prv AS birth_prov, A.P22_Incm AS income, 
        A.P17_Educ AS education, A.DER10_EMPL_ST1 AS employment, 
        A.P19b_Ind AS industry, A.P19c_Occ as occupation, 

        cast(B.input_id AS TEXT) as sal_code_rdp, 
        B.distance AS distance_rdp, B.target_id AS cluster_rdp, 

        cast(BP.input_id AS TEXT) as sal_code_placebo, 
        BP.distance AS distance_placebo, BP.target_id AS cluster_placebo, 

        IR.area_int_rdp, IP.area_int_placebo, QQ.area,

        'census2001pers' AS source, 2001 AS year, A.SAL AS area_code

      FROM census_pers_2001 AS A 

      LEFT JOIN (
        SELECT input_id, distance, target_id, COUNT(input_id) AS count 
        FROM distance_sal_2001_rdp 
        WHERE distance<=2000
        GROUP BY input_id 
        HAVING COUNT(input_id)<=50 
          AND distance == MIN(distance)
      ) AS B ON A.SAL=B.input_id

      LEFT JOIN (
        SELECT input_id, distance, target_id, COUNT(input_id) AS count 
        FROM distance_sal_2001_placebo 
        WHERE distance<=2000
        GROUP BY input_id 
        HAVING COUNT(input_id)<=50 
          AND distance == MIN(distance)
      ) AS BP ON A.SAL=BP.input_id

      LEFT JOIN (
        SELECT sal_code, area_int AS area_int_rdp 
        FROM int_rdp_sal_2001
        GROUP BY sal_code
        HAVING area_int_rdp = MAX(area_int_rdp)
      ) AS IR ON IR.sal_code = A.SAL

      LEFT JOIN (
        SELECT sal_code, area_int AS area_int_placebo 
        FROM int_placebo_sal_2001
        GROUP BY sal_code
        HAVING area_int_placebo = MAX(area_int_placebo)
      ) AS IP ON IP.sal_code = A.SAL

      LEFT JOIN area_sal_2001 AS QQ ON QQ.sal_code = A.SAL

      /* *** */
      UNION ALL 
      /* *** */ 

      SELECT 

        A.F03_SEX AS sex, A.F02_AGE AS age, A.P02_RELATION AS relation, 
        A.P01_YEAR AS birth_yr, A.P03_MARITAL_ST AS marit_stat, 
        A.P05_POP_GROUP AS race, A.P06A_LANGUAGE AS language, 
        A.P07_PROV_POB AS birth_prov, 
        A.P16_INCOME AS income, A.P20_EDULEVEL AS education,
        A.DERP_EMPLOY_STATUS_OFFICIAL AS employment, 
        A.DERP_INDUSTRY AS industry, A.DERP_OCCUPATION AS occupation,

        cast(B.input_id AS TEXT) as sal_code_rdp, 
        B.distance AS distance_rdp, B.target_id AS cluster_rdp, 

        cast(BP.input_id AS TEXT) as sal_code_placebo, 
        BP.distance AS distance_placebo, BP.target_id AS cluster_placebo, 

        IR.area_int_rdp, IP.area_int_placebo, QQ.area,

        'census2011pers' AS source, 2011 AS year, A.SAL_CODE AS area_code

      FROM census_pers_2011 AS A 

      LEFT JOIN (
        SELECT input_id, distance, target_id, COUNT(input_id) AS count 
        FROM distance_sal_2011_rdp 
        WHERE distance<=2000
        GROUP BY input_id 
        HAVING COUNT(input_id)<=50 
          AND distance == MIN(distance)
      ) AS B ON A.SAL_CODE=B.input_id

      LEFT JOIN (
        SELECT input_id, distance, target_id, COUNT(input_id) AS count 
        FROM distance_sal_2011_placebo 
        WHERE distance<=2000
        GROUP BY input_id HAVING COUNT(input_id)<=50 
        AND distance == MIN(distance)
      ) AS BP ON A.SAL_CODE=BP.input_id

      LEFT JOIN (
        SELECT sal_code, area_int AS area_int_rdp
        FROM int_rdp_sal_2011
        GROUP BY sal_code
        HAVING area_int_rdp = MAX(area_int_rdp)
      ) AS IR ON IR.sal_code = A.SAL_CODE

      LEFT JOIN (
        SELECT sal_code, area_int AS area_int_placebo 
        FROM int_placebo_sal_2011
        GROUP BY sal_code
        HAVING area_int_placebo = MAX(area_int_placebo)
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

    WHERE NOT (distance_rdp IS NULL AND distance_placebo IS NULL)
    AND random < .75

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

  *drop if distance_rdp==. & distance_placebo==.;	
  		
  save DDcensus_pers_admin, replace;

};
*****************************************************************;
*****************************************************************;
*****************************************************************;

*****************************************************************;
************************ PREPARE DATA ***************************;
*****************************************************************;
if $data_prep==1 {;

use DDcensus_pers_admin, clear;

* go to working dir;
cd ../..;
cd Output/GAUTENG/censusregs;

* employment;
gen unemployed = .;
replace unemployed = 1 if employment ==2;
replace unemployed = 0 if employment ==1;

lab var unemployed "Unemployed";

* schooling;
gen educ_yrs = education + 1  if education<=12 & !missing(education);
replace educ_yrs = 0 if ((education==99 & year ==2001)|(education==98 & year ==2011)) & !missing(education);
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
gen schooling_noeduc  = (education==99 & year ==2001)|(education==98 & year ==2011) if !missing(education);
gen schooling_postsec = (education>=12 & education<=30) if !missing(education) & age>=18;

* race;
gen black = (race==1) if !missing(race);

* born outside Gauteng;
gen outside_gp = (birth_prov!=7) if !missing(birth_prov);

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
  distance_joined cluster_joined distance_rdp distance_placebo cluster_rdp cluster_placebo
  , by(area_code year);

save temp_censuspers_agg.dta, replace;


};
*****************************************************************;
*****************************************************************;
*****************************************************************;

*****************************************************************;
********************* RUN REGRESSIONS ***************************;
*****************************************************************;
if $data_regs==1 {;

* go to working dir;
cd ../..;
cd $output;

use temp_censuspers_agg.dta, replace;

g project_rdp = (area_int_rdp > $tresh_area & distance_rdp<= $tresh_dist);
g project_placebo = (area_int_placebo > $tresh_area & distance_placebo<= $tresh_dist);
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


global regressors "
  project_post_rdp
  project_post
  project_rdp
  project
  spillover_post_rdp
  spillover_post
  spillover_rdp
  spillover
  others_post
  ";

if $drop_others == 1{;
drop if others==1;
omit regressors spillover others_post;
};

global outcomes "
  age 
  outside_gp
  unemployed
  educ_yrs
  inc_value_earners  
  ";

eststo clear;

foreach var of varlist $outcomes {;
  areg `var' $regressors , a(cluster_joined) cl(cluster_joined);
  test project_post_rdp = spillover_post_rdp;
  estadd scalar pval = `=r(p)';
  sum `var' if e(sample)==1 & year ==2001, detail;
  estadd scalar Mean2001 = `=r(mean)';
  sum `var' if e(sample)==1 & year ==2011, detail;
  estadd scalar Mean2011 = `=r(mean)';
  count if e(sample)==1 & spillover==1 & project!=1;
  estadd scalar hhspill = `=r(N)';
  count if e(sample)==1 & project==1;
  estadd scalar hhproj = `=r(N)';
  preserve;
    keep if e(sample)==1;
    quietly tab cluster_rdp;
    global projectcount = r(r);
    quietly tab cluster_placebo;
    global projectcount = $projectcount + r(r);
  restore;
  estadd scalar projcount = $projectcount;
  eststo `var';
};

global X "{\tim}";

estout $outcomes using census_pers_DDregs_AGG.tex, replace
  style(tex) 
  drop(_cons)
  rename(
    project_post_rdp "project${X}post${X}constr"
    project_post "project${X}post"
    project_rdp "project${X}constr"
    spillover_post_rdp "spillover${X}post${X}constr"
    spillover_post "spillover${X}post"
    spillover_rdp "spillover${X}constr"
  )
  noomitted
  mlabels(,none) 
  collabels(none)
  cells( b(fmt(3) star ) se(par fmt(3)) )
  varlabels(,el(
    "project${X}post${X}constr" [0.5em] 
    "project${X}post" [0.5em] 
    "project${X}constr" [0.5em] 
    project [0.5em] 
    "spillover${X}post${X}constr" [0.5em] 
    "spillover${X}post" [0.5em] 
    "spillover${X}constr" " \midrule"
  ))
  stats( pval Mean2001 Mean2011 r2 projcount hhproj hhspill N , 
    labels(
      "{\it p}-val, h\textsubscript{0}: project=spill. "
      "Mean Outcome 2001" 
      "Mean Outcome 2011" 
      "R$^2$" 
      "\# projects"
      `"N project areas"'
      `"N spillover areas"'  
      "N" 
    ) 
    fmt(
      %9.3fc
      %9.2fc
      %9.2fc 
      %12.3fc 
      %12.0fc 
      %12.0fc 
      %12.0fc  
      %12.0fc 
    )
  )
  starlevels( 
    "\textsuperscript{c}" 0.10 
    "\textsuperscript{b}" 0.05 
    "\textsuperscript{a}" 0.01) ;

};

*****************************************************************;
*****************************************************************;
*****************************************************************;













