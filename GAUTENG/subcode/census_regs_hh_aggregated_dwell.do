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
global data_load = 0;
global data_prep = 0;
global data_stat = 0;
global data_regs = 1;
global data_regs_DDD = 0;

* PARAMETERS;
global drop_others= 1   ; /* everything relative to unconstructed */
global tresh_area = 0.3 ; /* Area ratio for "inside" vs spillover */
global tresh_dist = 1500; /* Area ratio inside vs spillover */

global tresh_area_DDD = 0.75     ;
global tresh_dist_DDD = 400      ;
global tresh_dist_max_DDD = 1200 ;

* WEIGHTS??;
global ww = ""; /// alternatively [aweight=hh_pop]; 

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

      cast(B.input_id AS TEXT) as sal_code_rdp,
      B.distance AS distance_rdp, B.target_id AS cluster_rdp, 

      cast(BP.input_id AS TEXT) as sal_code_placebo, 
      BP.distance AS distance_placebo, BP.target_id AS cluster_placebo, 
      
      IR.area_int_rdp, IP.area_int_placebo, QQ.area,

      'census2001hh' AS source, 2001 AS year, A.SAL AS area_code

    FROM census_hh_2001 AS A  

    LEFT JOIN (
      SELECT input_id, distance, target_id, COUNT(input_id) AS count 
      FROM distance_sal_2001_rdp 
      WHERE distance<=4000
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

      A.H01_QUARTERS AS quarters_typ, A.H02_MAINDWELLING AS dwelling_typ,
      A.H03_TOTROOMS AS tot_rooms, A.H04_TENURE AS tenure, A.H07_WATERPIPED AS water_piped,
      A.H08_WATERSOURCE AS water_source, A.H10_TOILET AS toilet_typ, 
      A.H11_ENERGY_COOKING AS enrgy_cooking, A.H11_ENERGY_HEATING AS enrgy_heating,
      A.H11_ENERGY_LIGHTING AS enrgy_lighting, A.H12_REFUSE AS refuse_typ, A.DERH_HSIZE AS hh_size,

      cast(B.input_id AS TEXT) as sal_code_rdp,
      B.distance AS distance_rdp, B.target_id AS cluster_rdp,

      cast(BP.input_id AS TEXT) as sal_code_placebo, 
      BP.distance AS distance_placebo, BP.target_id AS cluster_placebo, 
      
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
egen hh_pop = sum(o), by(area_code year);
g hh_density = (hh_pop/area)*1000000;
lab var hh_density "Households per km2";
drop o;

* pop density;
egen person_pop = sum(hh_size), by(area_code year);
g pop_density = (person_pop/area)*1000000;
lab var pop_density "People per km2";

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
  (mean) toilet_flush water_inside water_yard water_utility
  electricity electric_cooking electric_heating electric_lighting
  owner house tot_rooms hh_size
  (firstnm) hh_pop person_pop hh_density pop_density area_int_rdp area_int_placebo placebo
  distance_joined cluster_joined distance_rdp distance_placebo cluster_rdp cluster_placebo
  , by(area_code year);

save temp_censushh_agg.dta, replace;

};
*****************************************************************;
*****************************************************************;
*****************************************************************;

*****************************************************************;
********************* SUMMARY STATISTICS ************************;
*****************************************************************;
if $data_stat==1 {;

* go to working dir;
cd ../..;
cd $output;

use temp_censushh_agg.dta, replace;



mat SUM = J(8, 3,.);
keep if year ==2001;
g project_rdp = (area_int_rdp > $tresh_area & distance_rdp<= $tresh_dist);
g project_placebo = (area_int_placebo > $tresh_area & distance_placebo<= $tresh_dist);
*replace project_placebo = 0 if (project_placebo==1 & project_rdp==1) & area_int_placebo < area_int_rdp;
*replace project_rdp = 0 if (project_placebo==1 & project_rdp==1) & area_int_placebo > area_int_rdp;

* toilet_flush means;
sum toilet_flush if project_rdp ==1 $ww;
matrix SUM[1,1] = round(r(mean),.01);
sum toilet_flush if project_placebo ==1 $ww;
matrix SUM[1,2] = round(r(mean),.01);
sum toilet_flush $ww; 
matrix SUM[1,3] = round(r(mean),.01);

* water_inside means;
sum water_inside if project_rdp ==1 $ww;
matrix SUM[2,1] = round(r(mean),.01);
sum water_inside if project_placebo ==1 $ww;
matrix SUM[2,2] = round(r(mean),.01);
sum water_inside $ww;
matrix SUM[2,3] = round(r(mean),.01);

* electric_cooking means;
sum electric_cooking if project_rdp ==1 $ww;
matrix SUM[3,1] = round(r(mean),.01);
sum electric_cooking if project_placebo ==1 $ww;
matrix SUM[3,2] = round(r(mean),.01);
sum electric_cooking $ww;
matrix SUM[3,3] = round(r(mean),.01);

* electric_heating means;
sum electric_heating if project_rdp ==1 $ww;
matrix SUM[4,1] = round(r(mean),.01);
sum electric_heating if project_placebo ==1 $ww;
matrix SUM[4,2] = round(r(mean),.01);
sum electric_heating $ww;
matrix SUM[4,3] = round(r(mean),.01);

* electric_lighting means;
sum electric_lighting if project_rdp ==1 $ww;
matrix SUM[5,1] = round(r(mean),.01);
sum electric_lighting if project_placebo ==1 $ww;
matrix SUM[5,2] = round(r(mean),.01);
sum electric_lighting $ww; 
matrix SUM[5,3] = round(r(mean),.01);

* tot_rooms means;
sum tot_rooms if project_rdp ==1 $ww;
matrix SUM[6,1] = round(r(mean),.01);
sum tot_rooms if project_placebo ==1 $ww;
matrix SUM[6,2] = round(r(mean),.01);
sum tot_rooms $ww;
matrix SUM[6,3] = round(r(mean),.01);

* hh_size means;
sum hh_size if project_rdp ==1 $ww;
matrix SUM[7,1] = round(r(mean),.01);
sum hh_size if project_placebo ==1 $ww;
matrix SUM[7,2] = round(r(mean),.01);
sum hh_size $ww;
matrix SUM[7,3] = round(r(mean),.01);

* Counts;
count if project_rdp ==1;
global cons: di %15.0fc r(N);
count if project_placebo ==1;
global uncons: di %15.0fc r(N);
count;
global all: di %15.0fc r(N);

preserve;
clear;
svmat SUM; 
tostring * , replace force format(%9.2f);
gen names = "";
order names, first;
replace names = "Flush Toilet" in 1;
replace names = "Piped Water in Home" in 2;
replace names = "Electricity for Cooking" in 3;
replace names = "Electricity for Heating" in 4;
replace names = "Electricity for Lighting" in 5;
replace names = "Number of Rooms" in 6;
replace names = "Household Size" in 7;

replace names = "N" in 8;
replace SUM1 = "$cons" in 8;
replace SUM2 = "$uncons" in 8;
replace SUM3 = "$all" in 8;

replace SUM3 = SUM3 + " \\";

export delimited using "census_at_baseline_AGG.tex", novar delimiter("&") replace;

restore;
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

use temp_censushh_agg.dta, replace;

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
  toilet_flush 
  water_inside 
  electric_cooking 
  electric_heating 
  electric_lighting 
  tot_rooms
  hh_size
  ";

* preserve ; 
*   g an1 = a_n==1;
*   egen AN=sum(an1);
*   sum AN, detail;
*   file open myfile using "total_blocks.tex", write replace;
*   local h : di %10.0fc `=r(mean)';
*   file write myfile "`h'";
*   file close myfile ;
* restore ;

eststo clear;

foreach var of varlist $outcomes {;
  areg `var' $regressors $ww , a(cluster_joined) cl(cluster_joined);
  test project_post_rdp = spillover_post_rdp;
  estadd scalar pval = `=r(p)';
  sum `var' if e(sample)==1 & year ==2001 $ww, detail;
  estadd scalar Mean2001 = `=r(mean)';
  sum `var' if e(sample)==1 & year ==2011 $ww, detail;
  estadd scalar Mean2011 = `=r(mean)';
  count if e(sample)==1 & spillover==1 & !project==1;
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

areg pop_density ${regressors} $ww, a(cluster_joined) cl(cluster_joined);
test project_post_rdp = spillover_post_rdp;
estadd scalar pval = `=r(p)';
sum pop_density if e(sample)==1 & year ==2001, detail;
estadd scalar Mean2001 = `=r(mean)';
sum pop_density if e(sample)==1 & year ==2011, detail;
estadd scalar Mean2011 = `=r(mean)';
count if e(sample)==1 & spillover==1 & !project==1;
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
eststo pop_density;

global X "{\tim}";

estout using census_hh_DDregs_AGG.tex, replace
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
  stats(pval Mean2001 Mean2011 r2 projcount hhproj hhspill N , 
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

*****************************************************************;
*****************************************************************;
*****************************************************************;
if $data_regs_DDD==1 {;

keep if distance_rdp <= $tresh_dist_max_DDD  |  distance_placebo <= $tresh_dist_max_DDD ;

g project_rdp = (area_int_rdp > $tresh_area_DDD & distance_rdp<= $tresh_dist_DDD);
g project_placebo = (area_int_placebo > $tresh_area_DDD & distance_placebo<= $tresh_dist_DDD);
g project = (project_rdp==1 | project_placebo==1);
g project_post = project ==1 & year==2011;
g project_post_rdp = project_rdp ==1 & year==2011;

g spillover_rdp = project_rdp!=1 & distance_rdp<= $tresh_dist_DDD;
g spillover_placebo = project_placebo!=1 & distance_placebo<= $tresh_dist_DDD;
g spillover = (spillover_rdp==1 | spillover_placebo==1);
g spillover_post = spillover == 1 & year==2011;
g spillover_post_rdp = spillover_rdp==1 & year==2011; 

*g others      = project !=1 & spillover !=1;
g  post = year==2011;
g  rdp  = distance_rdp<= $tresh_dist_max_DDD;
g  post_rdp = post*rdp;


global regressors "
  project_post_rdp
  project_post
  project_rdp
  project
  spillover_post_rdp
  spillover_post
  spillover_rdp
  spillover
  post_rdp
  post
  ";

order $regressors;

global outcomes1 "
  toilet_flush 
  water_inside 
  electric_cooking 
  electric_heating 
  electric_lighting 
  tot_rooms
  hh_size
  ";

eststo clear;

*areg toilet_flush $regressors , a(cluster_joined) cl(cluster_joined);
*areg water_inside $regressors , a(cluster_joined) cl(cluster_joined);

foreach var of varlist $outcomes1 {;
  areg `var' $regressors , a(cluster_joined) cl(cluster_joined);
  test project_post_rdp = spillover_post_rdp;
  estadd scalar pval = `=r(p)';
  sum `var' if e(sample)==1 & year ==2001, detail;
  estadd scalar Mean2001 = `=r(mean)';
  sum `var' if e(sample)==1 & year ==2011, detail;
  estadd scalar Mean2011 = `=r(mean)';
  count if e(sample)==1 & spillover==1 & project==1; 
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

areg pop_density ${regressors} if a_n==1, a(cluster_joined) cl(cluster_joined);
test project_post_rdp = spillover_post_rdp;
estadd scalar pval = `=r(p)';
sum pop_density if e(sample)==1 & year ==2001, detail;
estadd scalar Mean2001 = `=r(mean)';
sum pop_density if e(sample)==1 & year ==2011, detail;
estadd scalar Mean2011 = `=r(mean)';
eststo pop_density;

global X "{\tim}";

estout $outcomes using census_hh_DDDregs.tex, replace
  style(tex) 
  drop(_cons)
  rename(
    project_post_rdp "project${X}post${X}constr"
    project_post "project${X}post"
    project_rdp "project${X}constr"
    spillover_post_rdp "spillover${X}post${X}constr"
    spillover_post "spillover${X}post"
    spillover_rdp "spillover${X}constr"
    post_rdp "post${X}constr"
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
    "spillover${X}constr" [0.5em]  
    "post${X}constr" [0.5em] 
    spillover [0.5em] 
    post  [0.5em] " \midrule"
  ))
  stats(pval Mean2001 Mean2011 r2 projcount hhproj hhspill N , 
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

* exit, STATA clear;

