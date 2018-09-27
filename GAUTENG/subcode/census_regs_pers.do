clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;

******************;
*  CENSUS REGS   *;
******************;

* global output = "Output/GAUTENG/censusregs" ;
* global output = "Code/GAUTENG/paper/figures" ;
global output = "Code/GAUTENG/presentations/presentation_lunch";

* PARAMETERS;
global area = .3;

* RUN LOCALLY?;
global LOCAL = 1;

* MAKE DATASET?;
global DATA_PREP = 0;


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

  	SELECT 

        AA.*, (RANDOM()/(2*9223372036854775808)+.5) as random,

        BB.mode_yr, BB.frac1,

        CC.placebo_yr 

    FROM

  	(

    SELECT A.P03_Sex AS sex, A.P02_Age AS age, A.P04_Rel AS relation, A.P02_Yr AS birth_yr,
           A.P05_Mar AS marit_stat, A.P06_Race AS race, A.P07_lng AS language, P09a_Prv AS birth_prov,
           A.P22_Incm AS income, P17_Educ AS education, A.DER10_EMPL_ST1 AS employment, 
           A.P19b_Ind AS industry, A.P19c_Occ as occupation, 

           cast(B.sal_code AS TEXT) as sal_code, B.distance, B.cluster, B.area_int,

           'census2001pers' AS source, 'rdp' AS hulltype, 2001 AS year

    FROM census_pers_2001 AS A 
    JOIN distance_sal_2001_rdp AS B ON B.sal_code=A.SAL
    /* WHERE area_int > $area */

    UNION ALL 

    SELECT A.P03_Sex AS sex, A.P02_Age AS age, A.P04_Rel AS relation, A.P02_Yr AS birth_yr,
           A.P05_Mar AS marit_stat, A.P06_Race AS race, A.P07_lng AS language, P09a_Prv AS birth_prov,
           A.P22_Incm AS income, P17_Educ AS education, A.DER10_EMPL_ST1 AS employment, 
           A.P19b_Ind AS industry, A.P19c_Occ as occupation,

           cast(B.sal_code AS TEXT) as sal_code, B.distance, B.cluster, B.area_int, 

           'census2001pers' AS source, 'placebo' AS hulltype, 2001 AS year

    FROM census_pers_2001 AS A  
    JOIN distance_sal_2001_placebo AS B ON B.sal_code=A.SAL
    /* WHERE area_int > $area */

    UNION ALL 

    SELECT A.F03_SEX AS sex, A.F02_AGE AS age, A.P02_RELATION AS relation, A.P01_YEAR AS birth_yr,
           A.P03_MARITAL_ST AS marit_stat, A.P05_POP_GROUP AS race, A.P06A_LANGUAGE AS language,
           A.P07_PROV_POB AS birth_prov, A.P16_INCOME AS income, A.P20_EDULEVEL AS education,
           A.DERP_EMPLOY_STATUS_OFFICIAL AS employment, A.DERP_INDUSTRY AS industry, A.DERP_OCCUPATION AS occupation,

           cast(B.sal_code AS TEXT) as sal_code, B.distance, B.cluster, B.area_int,

           'census2011pers' AS source, 'rdp' AS hulltype, 2011 AS year

    FROM census_pers_2011 AS A  
    JOIN distance_sal_2011_rdp AS B ON B.sal_code=A.SAL_code
    /* WHERE area_int > $area */

    UNION ALL 

    SELECT A.F03_SEX AS sex, A.F02_AGE AS age, A.P02_RELATION AS relation, A.P01_YEAR AS birth_yr,
           A.P03_MARITAL_ST AS marit_stat, A.P05_POP_GROUP AS race, A.P06A_LANGUAGE AS language,
           A.P07_PROV_POB AS birth_prov, A.P16_INCOME AS income, A.P20_EDULEVEL AS education,
           A.DERP_EMPLOY_STATUS_OFFICIAL AS employment, A.DERP_INDUSTRY AS industry, A.DERP_OCCUPATION AS occupation,

           cast(B.sal_code AS TEXT) as sal_code, B.distance, B.cluster, B.area_int,

           'census2011pers' AS source, 'placebo' AS hulltype, 2011 AS year

    FROM census_pers_2011 AS A  
    JOIN distance_sal_2011_placebo AS B ON B.sal_code=A.SAL_code
    /* WHERE area_int > $area */

    ) AS AA

    LEFT JOIN (SELECT DISTINCT cluster, cluster_siz, mode_yr, frac1, frac2 
    FROM rdp_clusters) AS BB on AA.cluster = BB.cluster

    LEFT JOIN placebo_conhulls AS CC on CC.cluster = AA.cluster

    WHERE random < .5

    ";

  odbc query "gauteng";
  odbc load, exec("`qry'") clear;	
  		
  save DDcensus_pers, replace;

};

use DDcensus_pers, clear;

* go to working dir;
cd ../..;
cd Output/GAUTENG/censusregs;

global ifsample = "
  (cluster < 1000 & frac1>.5 & mode_yr>2002 )
  |(cluster >= 1009 & placebo_yr!=. & placebo_yr > 2002 )
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
gen post   = (year==2011);
gen treat  = (cluster<1000);
gen ptreat = post*treat; 

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
global outcomes "inc_value_earners unemployed";
order $vars;

local table_name "census_DD_pers_sample.tex";

areg schooling_hschool $vars if $ifsample , a(cluster) cl(cluster);
       outreg2 using "`table_name'", label  tex(frag) 
replace addtext(Project FE, YES) keep(gr_*) 
addnote("Standard errors are clustered at the project level.");

foreach var of varlist $outcomes {;
areg `var' $vars if $ifsample , a(cluster) cl(cluster);
       outreg2 using "`table_name'", label  tex(frag) 
append addtext(Project FE, YES) keep(gr_*) ;
};

exit STATA, clear;












