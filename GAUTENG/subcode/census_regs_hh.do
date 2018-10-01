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

******************;
*  CENSUS REGS   *;
******************;

* SET OUTPUT GLOBAL;
global output = "Output/GAUTENG/censusregs" ;
* global output = "Code/GAUTENG/paper/figures";
* global output = "Code/GAUTENG/presentations/presentation_lunch";

* RUN LOCALLY?;
global LOCAL = 1;

* DOFILE SECTIONS;
global data_load = 1;
global data_prep = 1;
global data_regs = 1;

* PARAMETERS;
global tresh_area = 0.3;  /* Area ratio for "inside" vs spillover */
global tresh_dist = 1500; /* Area ratio inside vs spillover */

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

  AA.*, GP.con_mo_placebo, GR.con_mo_rdp

  FROM (

    SELECT 

      A.H23_Quarters AS quarters_typ, A.H23a_HU AS dwelling_typ,
      A.H24_Room AS tot_rooms, A.H25_Tenure AS tenure, A.H26_Piped_Water AS water_piped,
      A.H26a_Sourc_Water AS water_source, A.H27_Toilet_Facil AS toilet_typ, 
      A.H28a_Cooking AS enrgy_cooking, A.H28b_Heating AS enrgy_heating,
      A.H28c_Lghting AS enrgy_lighting, A.H30_Refuse AS refuse_typ, A.DER2_HHSIZE AS hh_size,

      cast(B.input_id AS TEXT) as sal_code_rdp, B.distance AS distance_rdp, B.target_id AS cluster_rdp, 
      cast(BP.input_id AS TEXT) as sal_code_placebo, BP.distance AS distance_placebo, BP.target_id AS cluster_placebo, 
      
      IR.area_int_rdp, IP.area_int_placebo, QQ.area,

      'census2001hh' AS source, 2001 AS year, A.SAL AS area_code

    FROM census_hh_2001 AS A  

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

      A.H01_QUARTERS AS quarters_typ, A.H02_MAINDWELLING AS dwelling_typ,
      A.H03_TOTROOMS AS tot_rooms, A.H04_TENURE AS tenure, A.H07_WATERPIPED AS water_piped,
      A.H08_WATERSOURCE AS water_source, A.H10_TOILET AS toilet_typ, 
      A.H11_ENERGY_COOKING AS enrgy_cooking, A.H11_ENERGY_HEATING AS enrgy_heating,
      A.H11_ENERGY_LIGHTING AS enrgy_lighting, A.H12_REFUSE AS refuse_typ, A.DERH_HSIZE AS hh_size,

      cast(B.input_id AS TEXT) as sal_code_rdp, B.distance AS distance_rdp, B.target_id AS cluster_rdp, 
      cast(BP.input_id AS TEXT) as sal_code_placebo, BP.distance AS distance_placebo, BP.target_id AS cluster_placebo, 
      
      IR.area_int_rdp, IP.area_int_placebo, QQ.area,

      'census2011hh' AS source, 2011 AS year, A.SAL_CODE AS area_code

    FROM census_hh_2011 AS A  

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
  
save DDcensus_hh_admin, replace;

};
*****************************************************************;
*****************************************************************;
*****************************************************************;

*****************************************************************;
************************ PREPARE DATA ***************************;
*****************************************************************;
if $data_prep==1 {;

use DDcensus_hh_admin, clear;

* go to working dir;
cd ../..;
cd $output;

* flush toilet?;
gen toilet_flush = (toilet_typ==1|toilet_typ==2) if !missing(toilet_typ);
lab var toilet_flush "Flush Toilet";

* piped water?;
gen water_inside = (water_piped==1 & year==2011)|(water_piped==5 & year==2001) if !missing(water_piped);
lab var water_inside "Piped Water Inside";
gen water_yard = (water_piped==1 | water_piped==2 & year==2011)|(water_piped==5 | water_piped==4 & year==2001) if !missing(water_piped);
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
gen owner = ((tenure==2 | tenure==4) & year==2011)|((tenure==1 | tenure==2) & year==2001) if !missing(tenure);
lab var owner "Owns House";

* house?;
gen house = dwelling_typ==1 if !missing(dwelling_typ);
lab var house "Single House";

* total rooms;
replace tot_rooms=. if tot_rooms>9;
lab var tot_rooms "No. Rooms";

* household size rooms;
replace hh_size=. if hh_size>10;
lab var hh_size "Household Size";

* household density;
g o = 1;
bys area_code: g a_n=_n;
egen pop = sum(o), by(area_code year);
g hh_density = (pop/area)*1000000;
lab var hh_density "Households per km2";
drop o pop;

* pop density;
egen pop = sum(hh_size), by(area_code year);
g pop_density = (pop/area)*1000000;
lab var pop_density "People per km2";
drop pop;

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

global outcomes1 "
  toilet_flush 
  water_inside 
  water_utility 
  owner 
  house 
  ";

global outcomes2 "
  electric_cooking 
  electric_heating 
  electric_lighting 
  ";

eststo clear;

foreach var of varlist $outcomes1 {;
  areg `var' $regressors , a(cluster_joined) cl(cluster_joined);

  sum `var' if e(sample)==1 & year ==2001, detail;
  estadd scalar Mean2001 = `=r(mean)';
  sum `var' if e(sample)==1 & year ==2011, detail;
  estadd scalar Mean2011 = `=r(mean)';

  eststo `var';
};

esttab $outcomes1 using census_hh_DDregs_admin_1,
  replace nomti b(%12.3fc) se(%12.3fc) r2(%12.3fc) r2 tex 

  star(* 0.10 ** 0.05 *** 0.01) stats(Mean2001 Mean2011)

  compress drop(_cons);


eststo clear;

foreach var of varlist $outcomes2 {;
  areg `var' $regressors , a(cluster_joined) cl(cluster_joined);

  sum `var' if e(sample)==1 & year ==2001, detail;
  estadd scalar Mean2001 = `=r(mean)';
  sum `var' if e(sample)==1 & year ==2011, detail;
  estadd scalar Mean2011 = `=r(mean)';

  eststo `var';
};

areg pop_density ${regressors} if a_n==1, a(cluster_joined) cl(cluster_joined);

sum pop_density if e(sample)==1 & year ==2001, detail;
estadd scalar Mean2001 = `=r(mean)';
sum pop_density if e(sample)==1 & year ==2011, detail;
estadd scalar Mean2011 = `=r(mean)';
eststo pop_density;

areg hh_density ${regressors} if a_n==1, a(cluster_joined) cl(cluster_joined);
sum hh_density if e(sample)==1 & year ==2001, detail;
estadd scalar Mean2001 = `=r(mean)';
sum hh_density if e(sample)==1 & year ==2011, detail;
estadd scalar Mean2011 = `=r(mean)';

eststo hh_density;

esttab $outcomes2 hh_density pop_density using census_hh_DDregs_admin_2,
  replace nomti b(%12.3fc) se(%12.3fc) r2(%12.3fc) r2 tex 

  star(* 0.10 ** 0.05 *** 0.01)  stats(Mean2001 Mean2011)

  compress;


};
*****************************************************************;
*****************************************************************;
*****************************************************************;

* exit, STATA clear;

