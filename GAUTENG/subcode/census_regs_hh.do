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
cd Output/GAUTENG/censusregs;

global ifsample = "
  (cluster < 1000 & frac1>.5 & mode_yr>2002 &
    cluster != 1   &
    cluster != 23  &
    cluster != 72  &
    cluster != 132 &
    cluster != 170 &
    cluster != 171 )
  |(cluster >= 1009 & placebo_yr!=. & placebo_yr > 2002 &
    cluster != 1013 &
    cluster != 1019 &
    cluster != 1046 &
    cluster != 1071 &
    cluster != 1074 &
    cluster != 1075 &
    cluster != 1078 &
    cluster != 1079 &
    cluster != 1084 &
    cluster != 1085 &
    cluster != 1092 &
    cluster != 1095 &
    cluster != 1117 &
    cluster != 1119 &
    cluster != 1125 &
    cluster != 1126 &
    cluster != 1127 &
    cluster != 1164 &
    cluster != 1172 &
    cluster != 1185 &
    cluster != 1190 &
    cluster != 1202 &
    cluster != 1203 &
    cluster != 1218 &
    cluster != 1219 &
    cluster != 1220 &
    cluster != 1224 &
    cluster != 1225 &
    cluster != 1230 &
    cluster != 1239)
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

* piped water?;
gen water_inside = (water_piped==1 & year==2011)|(water_piped==5 & year==2001) if !missing(water_piped);
gen water_yard   = (water_piped==1 | water_piped==2 & year==2011)|(water_piped==5 | water_piped==4 & year==2001) if !missing(water_piped);

* water source?;
gen water_utility = (water_source==1) if !missing(water_source);

* electricity?;
gen electricity = (enrgy_cooking==1 | enrgy_heating==1 | enrgy_lighting==1) if (enrgy_lighting!=. & enrgy_heating!=. & enrgy_cooking!=.);
gen electric_cooking  = enrgy_cooking==1 if !missing(enrgy_cooking);
gen electric_heating  = enrgy_heating==1 if !missing(enrgy_heating);
gen electric_lighting = enrgy_lighting==1 if !missing(enrgy_lighting);

* tenure?;
gen owner = (tenure==2 | tenure==4 & year==2011)|(tenure==1 | tenure==2 & year==2001) if !missing(tenure);

* house?;
gen house = dwelling_typ==1 if !missing(dwelling_typ);


eststo clear;
*areg hh_size 1.ptreat#i.gr 1.post#i.gr 1.treat#i.gr i.gr if $ifsample , a(cluster) cl(cluster);
*eststo reg1; 
*areg tot_rooms 1.ptreat#i.gr 1.post#i.gr 1.treat#i.gr i.gr if $ifsample , a(cluster) cl(cluster);
*eststo reg2;
areg toilet_flush 1.ptreat#i.gr 1.post#i.gr 1.treat#i.gr i.gr if $ifsample , a(cluster) cl(cluster);
eststo reg3; 
areg water_inside 1.ptreat#i.gr 1.post#i.gr 1.treat#i.gr i.gr if $ifsample , a(cluster) cl(cluster);
eststo reg4;
areg electric_cooking 1.ptreat#i.gr 1.post#i.gr 1.treat#i.gr i.gr if $ifsample , a(cluster) cl(cluster);
eststo reg5;
*areg electric_heating 1.ptreat#i.gr 1.post#i.gr 1.treat#i.gr i.gr if $ifsample , a(cluster) cl(cluster);
*eststo reg6;
areg electric_lighting 1.ptreat#i.gr 1.post#i.gr 1.treat#i.gr i.gr if $ifsample , a(cluster) cl(cluster); 
eststo reg7;
*areg owner 1.ptreat#i.gr 1.post#i.gr 1.treat#i.gr i.gr if $ifsample , a(cluster) cl(cluster);
*eststo reg8; 
areg house 1.ptreat#i.gr 1.post#i.gr 1.treat#i.gr i.gr if $ifsample , a(cluster) cl(cluster);
eststo reg9; 

esttab reg3 reg4 reg5 reg7 reg9 using census_DD_hh_sample,
keep(*ptreat*) 
replace nomti b(%12.3fc) se(%12.3fc) r2(%12.3fc) r2 tex star(* 0.10 ** 0.05 *** 0.01)
compress;


eststo clear;
*areg hh_size 1.ptreat#i.gr 1.post#i.gr 1.treat#i.gr i.gr , a(cluster) cl(cluster); 
*eststo reg1;  
*areg tot_rooms 1.ptreat#i.gr 1.post#i.gr 1.treat#i.gr i.gr , a(cluster) cl(cluster); 
*eststo reg2; 
areg toilet_flush 1.ptreat#i.gr 1.post#i.gr 1.treat#i.gr i.gr , a(cluster) cl(cluster);
eststo reg3;  
areg water_inside 1.ptreat#i.gr 1.post#i.gr 1.treat#i.gr i.gr , a(cluster) cl(cluster);
eststo reg4; 
areg electric_cooking 1.ptreat#i.gr 1.post#i.gr 1.treat#i.gr i.gr , a(cluster) cl(cluster);
eststo reg5; 
*areg electric_heating 1.ptreat#i.gr 1.post#i.gr 1.treat#i.gr i.gr , a(cluster) cl(cluster);
*eststo reg6; 
areg electric_lighting 1.ptreat#i.gr 1.post#i.gr 1.treat#i.gr i.gr , a(cluster) cl(cluster);
eststo reg7; 
*areg owner 1.ptreat#i.gr 1.post#i.gr 1.treat#i.gr i.gr , a(cluster) cl(cluster);
*eststo reg8; 
areg house 1.ptreat#i.gr 1.post#i.gr 1.treat#i.gr i.gr , a(cluster) cl(cluster);
eststo reg9; 

esttab reg3 reg4 reg5 reg7 reg9 using census_DD_hh,
keep(*ptreat*) 
replace nomti depvars b(%12.3fc) se(%12.3fc) r2(%12.3fc) r2 tex star(* 0.10 ** 0.05 *** 0.01)
compress;
  
















