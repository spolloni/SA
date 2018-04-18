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

* RUN LOCALLY?;
global LOCAL = 1;

* MAKE DATASET?;
global DATA_PREP = 1;

if $LOCAL==1 {;
	cd ..;
};

* import plotreg program;
do subcode/import_plotreg.do;

* load data;
cd ../..;
cd Generated/Gauteng;

if $DATA_PREP==1 {;

  local qry = " 

  	SELECT * FROM 

  	(

    SELECT A.P03_Sex AS sex, A.P02_Age AS age, A.P04_Rel AS relation, A.P02_Yr AS birth_yr,
           A.P05_Mar AS marit_stat, A.P06_Race AS race, A.P07_lng AS language, P09a_Prv AS birth_prov,
           A.P22_Incm AS income, P17_Educ AS education, A.DER10_EMPL_ST1 AS employment, 
           A.P19b_Ind AS industry, A.P19c_Occ as occupation, 

           cast(B.sal_code AS TEXT) as sal_code, B.distance, B.cluster, B.area_int,

           'census2001pers' AS source, 'rdp' AS hulltype, 2001 AS year

    FROM census_pers_2001 AS A  
    JOIN distance_sal_2001_rdp AS B ON B.sal_code=A.SAL

    UNION ALL 

    SELECT A.P03_Sex AS sex, A.P02_Age AS age, A.P04_Rel AS relation, A.P02_Yr AS birth_yr,
           A.P05_Mar AS marit_stat, A.P06_Race AS race, A.P07_lng AS language, P09a_Prv AS birth_prov,
           A.P22_Incm AS income, P17_Educ AS education, A.DER10_EMPL_ST1 AS employment, 
           A.P19b_Ind AS industry, A.P19c_Occ as occupation,

           cast(B.sal_code AS TEXT) as sal_code, B.distance, B.cluster, B.area_int, 

           'census2001pers' AS source, 'placebo' AS hulltype, 2001 AS year
    FROM census_pers_2001 AS A  
    JOIN distance_sal_2001_placebo AS B ON B.sal_code=A.SAL

    UNION ALL 

    SELECT A.F03_SEX AS sex, A.F02_AGE AS age, A.P02_RELATION AS relation, A.P01_YEAR AS birth_yr,
           A.P03_MARITAL_ST AS marit_stat, A.P05_POP_GROUP AS race, A.P06A_LANGUAGE AS language,
           A.P07_PROV_POB AS birth_prov, A.P16_INCOME AS income, A.P20_EDULEVEL AS education,
           A.DERP_EMPLOY_STATUS_OFFICIAL AS employment, A.DERP_INDUSTRY AS industry, A.DERP_OCCUPATION AS occupation,

           cast(B.sal_code AS TEXT) as sal_code, B.distance, B.cluster, B.area_int,

           'census2011pers' AS source, 'rdp' AS hulltype, 2011 AS year

    FROM census_pers_2011 AS A  
    JOIN distance_sal_2011_rdp AS B ON B.sal_code=A.SAL_code

    UNION ALL 

    SELECT A.F03_SEX AS sex, A.F02_AGE AS age, A.P02_RELATION AS relation, A.P01_YEAR AS birth_yr,
           A.P03_MARITAL_ST AS marit_stat, A.P05_POP_GROUP AS race, A.P06A_LANGUAGE AS language,
           A.P07_PROV_POB AS birth_prov, A.P16_INCOME AS income, A.P20_EDULEVEL AS education,
           A.DERP_EMPLOY_STATUS_OFFICIAL AS employment, A.DERP_INDUSTRY AS industry, A.DERP_OCCUPATION AS occupation,

           cast(B.sal_code AS TEXT) as sal_code, B.distance, B.cluster, B.area_int,

           'census2011pers' AS source, 'placebo' AS hulltype, 2011 AS year

    FROM census_pers_2011 AS A  
    JOIN distance_sal_2011_placebo AS B ON B.sal_code=A.SAL_code

    ) AS AA

    LIMIT 10000000

    ";

  odbc query "gauteng";
  odbc load, exec("`qry'") clear;	
  		
  save DDcensus_pers, replace;

};

use DDcensus_pers, clear;
/*
* go to working dir;
cd ../..;
cd Output/GAUTENG/censusregs;

* SUBSET SALs "INSIDE";
keep if area_int > .3;

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
gen toilet_flush = (toilet_typ==1|toilet_typ==2);

* piped water?;
gen water_inside = (water_piped==1 & year==2011)|(water_piped==5 & year==2001);
gen water_yard   = (water_piped==1 | water_piped==2 & year==2011)|(water_piped==5 | water_piped==4 & year==2001);

* water source?;
gen water_utility = (water_source==1);

* electricity?;
gen electricity = (enrgy_cooking==1 | enrgy_heating==1 | enrgy_lighting==1);
gen electric_cooking  = enrgy_cooking==1;
gen electric_heating  = enrgy_heating==1;
gen electric_lighting = enrgy_lighting==1;

* tenure?;
gen owner = (tenure==2 | tenure==4 & year==2011)|(tenure==1 | tenure==2 & year==2001);

* house?;
gen house = dwelling_typ==1;
*/












