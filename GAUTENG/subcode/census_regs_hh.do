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
global output = "Code/GAUTENG/paper/figures" ;



* RUN LOCALLY?;
global LOCAL = 1;

* MAKE DATASET?;
global DATA_PREP = 0;

if $LOCAL==1 {;
	cd ..;
};

* import plotreg program;
do subcode/import_plotcoeffs.do;

* load data;
cd ../..;
cd Generated/Gauteng;

if $DATA_PREP==1 {;

  local qry = " 

  	SELECT 

      AA.*, 

      BB.mode_yr, BB.frac1,

      CC.placebo_yr

    FROM 

  	(

    SELECT A.H23_Quarters AS quarters_typ, A.H23a_HU AS dwelling_typ,
           A.H24_Room AS tot_rooms, A.H25_Tenure AS tenure, A.H26_Piped_Water AS water_piped,
           A.H26a_Sourc_Water AS water_source, A.H27_Toilet_Facil AS toilet_typ, 
           A.H28a_Cooking AS enrgy_cooking, A.H28b_Heating AS enrgy_heating,
           A.H28c_Lghting AS enrgy_lighting, A.H30_Refuse AS refuse_typ, A.DER2_HHSIZE AS hh_size,

           cast(B.sal_code AS TEXT) as sal_code, B.distance, B.cluster, B.area_int,

           'census2001hh' AS source, 'rdp' AS hulltype, 2001 AS year

    FROM census_hh_2001 AS A  
    JOIN distance_sal_2001_rdp AS B ON B.sal_code=A.SAL

    UNION ALL 

    SELECT A.H23_Quarters AS quarters_typ, A.H23a_HU AS dwelling_typ,
           A.H24_Room AS tot_rooms, A.H25_Tenure AS tenure, A.H26_Piped_Water AS water_piped,
           A.H26a_Sourc_Water AS water_source, A.H27_Toilet_Facil AS toilet_typ, 
           A.H28a_Cooking AS enrgy_cooking, A.H28b_Heating AS enrgy_heating,
           A.H28c_Lghting AS enrgy_lighting, A.H30_Refuse AS refuse_typ, A.DER2_HHSIZE AS hh_size,

           cast(B.sal_code AS TEXT) as sal_code, B.distance, B.cluster, B.area_int, 

           'census2001hh' AS source, 'placebo' AS hulltype, 2001 AS year
    FROM census_hh_2001 AS A  
    JOIN distance_sal_2001_placebo AS B ON B.sal_code=A.SAL

    UNION ALL 

    SELECT A.H01_QUARTERS AS quarters_typ, A.H02_MAINDWELLING AS dwelling_typ,
           A.H03_TOTROOMS AS tot_rooms, A.H04_TENURE AS tenure, A.H07_WATERPIPED AS water_piped,
           A.H08_WATERSOURCE AS water_source, A.H10_TOILET AS toilet_typ, 
           A.H11_ENERGY_COOKING AS enrgy_cooking, A.H11_ENERGY_HEATING AS enrgy_heating,
           A.H11_ENERGY_LIGHTING AS enrgy_lighting, A.H12_REFUSE AS refuse_typ, A.DERH_HSIZE AS hh_size,

           cast(B.sal_code AS TEXT) as sal_code, B.distance, B.cluster, B.area_int,

           'census2011hh' AS source, 'rdp' AS hulltype, 2011 AS year

    FROM census_hh_2011 AS A  
    JOIN distance_sal_2011_rdp AS B ON B.sal_code=A.SAL_code

    UNION ALL 

    SELECT A.H01_QUARTERS AS quarters_typ, A.H02_MAINDWELLING AS dwelling_typ,
           A.H03_TOTROOMS AS tot_rooms, A.H04_TENURE AS tenure, A.H07_WATERPIPED AS water_piped,
           A.H08_WATERSOURCE AS water_source, A.H10_TOILET AS toilet_typ, 
           A.H11_ENERGY_COOKING AS enrgy_cooking, A.H11_ENERGY_HEATING AS enrgy_heating,
           A.H11_ENERGY_LIGHTING AS enrgy_lighting, A.H12_REFUSE AS refuse_typ, A.DERH_HSIZE AS hh_size,

           cast(B.sal_code AS TEXT) as sal_code, B.distance, B.cluster, B.area_int,

           'census2011hh' AS source, 'placebo' AS hulltype, 2011 AS year

    FROM census_hh_2011 AS A  
    JOIN distance_sal_2011_placebo AS B ON B.sal_code=A.SAL_code

    ) AS AA

    LEFT JOIN (SELECT DISTINCT cluster, cluster_siz, mode_yr, frac1, frac2 
    FROM rdp_clusters) AS BB on AA.cluster = BB.cluster

    LEFT JOIN placebo_conhulls AS CC on CC.cluster = AA.cluster

    ";

  odbc query "gauteng";
  odbc load, exec("`qry'") clear;	
  		
  save DDcensus_hh, replace;

};

use DDcensus_hh, clear;

* go to working dir;
cd ../..;
cd $output ;

global ifsample = "
  (cluster < 1000 & frac1>.5 & mode_yr>2002 )
  |(cluster >= 1000 & placebo_yr!=. & placebo_yr > 2002 )
  ";

* group definitions;
gen gr = .;
replace gr=1 if area_int >= .3;
replace gr=2 if area_int < .3 ;

* drop clusters with no SAL;
bys cluster year: gen N = _N;
drop if N<100;
bys cluster: egen sd = sd(year);
drop if sd==0;
drop N sd;

* treatment and post vars;
gen post  	= (year==2011);
gen treat 	= (cluster<1000);
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



global vars "  gr_1_post_treat gr_2_post_treat  gr_1_post gr_2_post gr_2_treat gr_2 ";
global outcomes "water_inside electric_cooking electric_lighting house owner tot_rooms hh_size";
order $vars;

local table_name "census_DD_hh_sample.tex";

areg toilet_flush $vars if $ifsample , a(cluster) cl(cluster);
       outreg2 using "`table_name'", label  tex(frag) 
replace addtext(Project FE, YES) keep(gr_*) 
addnote("Standard errors are clustered at the project level.");

foreach var of varlist $outcomes {;
areg `var' $vars if $ifsample , a(cluster) cl(cluster);
       outreg2 using "`table_name'", label  tex(frag) 
append addtext(Project FE, YES) keep(gr_*) ;
};

exit STATA, clear;











