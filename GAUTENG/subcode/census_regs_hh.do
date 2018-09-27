clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;

******************;
*  CENSUS REGS   *;
******************;

* PARAMETERS;

* SET OUTPUT GLOBAL;
global output = "Output/GAUTENG/censusregs" ;
* global output = "Code/GAUTENG/paper/figures";
* global output = "Code/GAUTENG/presentations/presentation_lunch";

* RUN LOCALLY?;
global LOCAL = 1;

* MAKE DATASET?;
global data_prep = 1;
global data_anal = 0;

if $LOCAL==1 {;
	cd ..;
};

* load data;
cd ../..;
cd Generated/Gauteng;

*****************************************************************;
************************ LOAD DATA ******************************;
*****************************************************************;
if $data_prep==1 {;

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

      'census2001hh' AS source, 2001 AS year

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

      'census2011hh' AS source, 2011 AS year

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
  
save DDcensus_hh_admin, replace;

};
*****************************************************************;
*****************************************************************;
*****************************************************************;

*****************************************************************;
************************ ANALYZE DATA ***************************;
*****************************************************************;
if $data_anal==1 {;

use DDcensus_hh_admin, clear;


* go to working dir;
cd ../..;
cd $output ;



*drop if distance_rdp==. & distance_placebo==.;

* group definitions;
*gen gr = .;
*replace gr=1 if (area_int_rdp >= .3 & area_int_rdp<.)
*            | (area_int_placebo >= .3 & area_int_placebo<.) ;
*replace gr=2 if (area_int_rdp < .3 & area_int_rdp>0)  
*            | (area_int_placebo < .3 & area_int_placebo>0) ;


g project_rdp = (area_int_rdp > 0 & area_int_rdp<.);
g project_placebo = (area_int_placebo > 0 & area_int_placebo<.) ;

g spillover_rdp = project_rdp!=1 & distance_rdp<=2000 ;
g spillover_placebo = project_placebo!=1 & distance_placebo<=2000 ;

g post = (year==2011);

g project_rdp_post = project_rdp*post;
g project_placebo_post = project_placebo*post;

g spillover_rdp_post = spillover_rdp*post;
g spillover_placebo_post = spillover_placebo*post;


global vars " project_rdp_post project_placebo_post spillover_rdp_post spillover_placebo_post  post project_rdp project_placebo spillover_rdp spillover_placebo  ";
order $vars;

* flush toilet?;
gen toilet_flush = (toilet_typ==1|toilet_typ==2) if !missing(toilet_typ);
lab var toilet_flush "Flush Toilet";

* piped water?;
gen water_inside = (water_piped==1 & year==2011)|(water_piped==5 & year==2001) if !missing(water_piped);
lab var water_inside "Piped Water Inside";

gen water_yard  = (water_piped==1 | water_piped==2 & year==2011)|(water_piped==5 | water_piped==4 & year==2001) if !missing(water_piped);

* water source?;
gen water_utility = (water_source==1) if !missing(water_source);

* electricity?;
gen electricity = (enrgy_cooking==1 | enrgy_heating==1 | enrgy_lighting==1) if (enrgy_lighting!=. & enrgy_heating!=. & enrgy_cooking!=.);
gen electric_cooking  = enrgy_cooking==1 if !missing(enrgy_cooking);
lab var electric_cooking "Electric Cooking";

gen electric_heating  = enrgy_heating==1 if !missing(enrgy_heating);
gen electric_lighting = enrgy_lighting==1 if !missing(enrgy_lighting);
lab var electric_lighting "Electric Lighting";

* tenure?;
gen owner = (tenure==2 | tenure==4 & year==2011)|(tenure==1 | tenure==2 & year==2001) if !missing(tenure);
lab var owner "Owns House";

* house?;
gen house = dwelling_typ==1 if !missing(dwelling_typ);
lab var house "Single House";

replace tot_rooms=. if tot_rooms>9;
lab var tot_rooms "No. Rooms";

replace hh_size=. if hh_size>10;
lab var hh_size "Household Size";

g cluster_reg = cluster_rdp;
replace cluster_reg = cluster_placebo if cluster_reg==. & cluster_placebo!=.;

g o = 1;
egen pop = sum(o), by(area year);
bys area: g a_n=_n;
g density = pop/area;
lab var density "Households per m2";

egen pop_n = sum(hh_size), by(area year);
g density_n = pop_n/area;
lab var density_n "People per m2";


global outcomes "water_inside electric_cooking electric_lighting house owner tot_rooms hh_size";

local table_name "census_DD_hh_sample_admin_dist.tex";

areg toilet_flush $vars  , a(cluster_reg) cl(cluster_reg);
       outreg2 using "`table_name'", label  tex(frag) 
replace addtext(Project FE, YES) keep($vars) 
addnote("Standard errors are clustered at the project level.");

foreach var of varlist $outcomes {;
areg `var' $vars , a(cluster_reg) cl(cluster_reg);
       outreg2 using "`table_name'", label  tex(frag) 
append addtext(Project FE, YES) keep($vars) ;
};

areg density $vars if a_n==1 , a(cluster_reg) cl(cluster_reg);
outreg2 using "`table_name'",  label  tex(frag) append addtext(Project FE, YES) keep($vars) ;

areg density_n $vars if a_n==1 , a(cluster_reg) cl(cluster_reg);
outreg2 using "`table_name'",  label  tex(frag) append addtext(Project FE, YES) keep($vars) ;

/*
preserve

  local table_name_true "census_DD_hh_sample_admin_dist_true.tex"

  g project = project_rdp==1 | project_placebo==1
  g project_post = project*post
  g spillover = spillover_rdp==1 | spillover_placebo==1
  g spillover_post = spillover*post

  *keep if project==1 | spillover==1

  global vars_true " spillover project spillover_rdp project_rdp post spillover_post project_post spillover_rdp_post project_rdp_post "

  order $vars_true

  areg toilet_flush $vars_true  , a(cluster_reg) cl(cluster_reg)
       outreg2 using "`table_name_true'", label  tex(frag) replace addtext(Project FE, YES) keep($vars_true) addnote("Standard errors are clustered at the project level.")


  foreach var of varlist $outcomes {
  areg `var' $vars_true , a(cluster_reg) cl(cluster_reg)
  outreg2 using "`table_name_true'", label  tex(frag) append addtext(Project FE, YES) keep($vars_true) 
  }

  areg density $vars_true if a_n==1 , a(cluster_reg) cl(cluster_reg)
  outreg2 using "`table_name_true'",  label  tex(frag) append addtext(Project FE, YES) keep($vars_true) 

  areg density_n $vars_true if a_n==1 , a(cluster_reg) cl(cluster_reg)
  outreg2 using "`table_name_true'",  label  tex(frag) append addtext(Project FE, YES) keep($vars_true) 

restore */

};
*****************************************************************;
*****************************************************************;
*****************************************************************;

* exit, STATA clear;

