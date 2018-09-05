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
* global output = "Output/GAUTENG/censusregs" ;
* global output = "Code/GAUTENG/paper/figures" ;
global output = "Code/GAUTENG/presentations/presentation_lunch";

* RUN LOCALLY?;
global LOCAL = 0;

* MAKE DATASET?;
global DATA_PREP = 1;

if $LOCAL==1 {;
	cd ..;
};

* load data;
cd ../..;
cd Generated/Gauteng;

if $DATA_PREP==1 {;

  local qry = " 

  	SELECT 

      AA.*, GP.mo_date_placebo, GR.mo_date_rdp

    FROM 	(
    SELECT A.H23_Quarters AS quarters_typ, A.H23a_HU AS dwelling_typ,
           A.H24_Room AS tot_rooms, A.H25_Tenure AS tenure, A.H26_Piped_Water AS water_piped,
           A.H26a_Sourc_Water AS water_source, A.H27_Toilet_Facil AS toilet_typ, 
           A.H28a_Cooking AS enrgy_cooking, A.H28b_Heating AS enrgy_heating,
           A.H28c_Lghting AS enrgy_lighting, A.H30_Refuse AS refuse_typ, A.DER2_HHSIZE AS hh_size,

           cast(B.input_id AS TEXT) as sal_code_rdp, B.distance AS distance_rdp, B.target_id AS cluster_rdp, 
           cast(BP.input_id AS TEXT) as sal_code_placebo, BP.distance AS distance_placebo, BP.target_id AS cluster_placebo, 
           area_int_rdp, area_int_placebo,

           'census2001hh' AS source, 2001 AS year

    FROM census_hh_2001 AS A  

    LEFT JOIN (SELECT input_id, distance, target_id, COUNT(input_id) AS count FROM distance_sal_2001_rdp WHERE distance<=4000
  GROUP BY input_id HAVING COUNT(input_id)<=50 AND distance == MIN(distance)) 
    AS B ON A.SAL=B.input_id

    LEFT JOIN (SELECT input_id, distance, target_id, COUNT(input_id) AS count FROM distance_sal_2001_placebo WHERE distance<=4000
  GROUP BY input_id HAVING COUNT(input_id)<=50 AND distance == MIN(distance)) 
    AS BP ON A.SAL=BP.input_id

    LEFT JOIN (SELECT sal_code, area_int AS area_int_rdp     FROM int_rdp_sal_2001)     AS IR ON IR.sal_code = A.SAL
    LEFT JOIN (SELECT sal_code, area_int AS area_int_placebo FROM int_placebo_sal_2001) AS IP ON IP.sal_code = A.SAL


        UNION ALL 

    SELECT A.H01_QUARTERS AS quarters_typ, A.H02_MAINDWELLING AS dwelling_typ,
           A.H03_TOTROOMS AS tot_rooms, A.H04_TENURE AS tenure, A.H07_WATERPIPED AS water_piped,
           A.H08_WATERSOURCE AS water_source, A.H10_TOILET AS toilet_typ, 
           A.H11_ENERGY_COOKING AS enrgy_cooking, A.H11_ENERGY_HEATING AS enrgy_heating,
           A.H11_ENERGY_LIGHTING AS enrgy_lighting, A.H12_REFUSE AS refuse_typ, A.DERH_HSIZE AS hh_size,

           cast(B.input_id AS TEXT) as sal_code_rdp, B.distance AS distance_rdp, B.target_id AS cluster_rdp, 
           cast(BP.input_id AS TEXT) as sal_code_placebo, BP.distance AS distance_placebo, BP.target_id AS cluster_placebo, 
           area_int_rdp, area_int_placebo,

           'census2011hh' AS source, 2011 AS year

    FROM census_hh_2011 AS A  

    LEFT JOIN (SELECT input_id, distance, target_id, COUNT(input_id) AS count FROM distance_sal_2011_rdp WHERE distance<=4000
  GROUP BY input_id HAVING COUNT(input_id)<=50 AND distance == MIN(distance)) 
    AS B ON A.SAL_CODE=B.input_id

    LEFT JOIN (SELECT input_id, distance, target_id, COUNT(input_id) AS count FROM distance_sal_2011_placebo WHERE distance<=4000
  GROUP BY input_id HAVING COUNT(input_id)<=50 AND distance == MIN(distance)) 
    AS BP ON A.SAL_CODE=BP.input_id

    LEFT JOIN (SELECT sal_code, area_int AS area_int_rdp     FROM int_rdp_sal_2011)     AS IR ON IR.sal_code = A.SAL_CODE
    LEFT JOIN (SELECT sal_code, area_int AS area_int_placebo FROM int_placebo_sal_2011) AS IP ON IP.sal_code = A.SAL_CODE

  ) AS AA

  LEFT JOIN (SELECT cluster_placebo, mo_date_placebo FROM cluster_placebo) AS GP ON AA.cluster_placebo = GP.cluster_placebo
  LEFT JOIN (SELECT cluster_rdp, mo_date_rdp FROM cluster_rdp) AS GR ON AA.cluster_rdp = GR.cluster_rdp    
    ";

  odbc query "gauteng";
  odbc load, exec("`qry'") clear;	
  

save DDcensus_hh_admin, replace;

};


use DDcensus_hh_admin, clear;
destring area_int_placebo area_int_rdp, replace force;  

* go to working dir;
cd ../..;
cd $output ;

 /* throw out clusters that were too early in the process */
  replace distance_placebo =. if mo_date_placebo<521;
  replace area_int_placebo =. if mo_date_placebo<521;
  replace distance_rdp =. if mo_date_rdp<512;
  replace area_int_rdp =. if mo_date_rdp<512;

drop if distance_rdp==. & distance_placebo==.;

* group definitions;
gen gr = .;
replace gr=1 if (area_int_rdp >= .3 & area_int_rdp<.)
            | (area_int_placebo >= .3 & area_int_placebo<.) ;
replace gr=2 if (area_int_rdp < .3)  
            | (area_int_placebo < .3) ;


* treatment and post vars;
gen post  	= (year==2011);
gen treat 	= area_int_rdp>0 & area_int_rdp<. ;
gen ptreat 	= post*treat; 

* flush toilet?;
gen toilet_flush = (toilet_typ==1|toilet_typ==2) if !missing(toilet_typ);
lab var toilet_flush "Flush Toilet";

* piped water?;
gen water_inside = (water_piped==1 & year==2011)|(water_piped==5 & year==2001) if !missing(water_piped);
lab var water_inside "Piped Water Inside";

gen water_yard   = (water_piped==1 | water_piped==2 & year==2011)|(water_piped==5 | water_piped==4 & year==2001) if !missing(water_piped);

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


g gr_1=gr==1;
lab var gr_1 "Project Area";

g gr_2=gr==2;
lab var gr_2 "Spillover";

g gr_1_treat = gr_1*treat;
lab var gr_1_treat "Project X Complete";

g gr_2_treat = gr_2*treat;
lab var gr_2_treat "Spillover X Complete";

g gr_1_post = gr_1*post;
lab var gr_1_post "Project X Post";

g gr_2_post = gr_2*post;
lab var gr_2_post "Spillover X Post";

g gr_1_post_treat = gr_1*post*treat;
lab var gr_1_post_treat "Project X Post X Complete";

g gr_2_post_treat = gr_2*post*treat;
lab var gr_2_post_treat "Spillover X Post X Complete";

g cluster_reg = cluster_rdp;
replace cluster_reg = cluster_placebo if cluster_reg==. & cluster_placebo!=.;

global vars "  gr_1_post_treat gr_2_post_treat  gr_1_post gr_2_post gr_2_treat gr_2 ";
global outcomes "water_inside electric_cooking electric_lighting house owner tot_rooms hh_size";
order $vars;

local table_name "census_DD_hh_sample_admin.tex";

areg toilet_flush $vars  , a(cluster_reg) cl(cluster_reg);
       outreg2 using "`table_name'", label  tex(frag) 
replace addtext(Project FE, YES) keep(gr_*) 
addnote("Standard errors are clustered at the project level.");

foreach var of varlist $outcomes {;
areg `var' $vars , a(cluster_reg) cl(cluster_reg);
       outreg2 using "`table_name'", label  tex(frag) 
append addtext(Project FE, YES) keep(gr_*) ;
};

exit, STATA clear;







