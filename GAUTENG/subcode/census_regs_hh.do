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
do subcode/import_plotreg.do;

* load data;
cd ../..;
cd Generated/Gauteng;

if $DATA_PREP==1 {;

  local qry = " 

  	SELECT * FROM 

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

    ";

  odbc query "gauteng";
  odbc load, exec("`qry'") clear;	
  		
  save DDcensus_hh, replace;

};

use DDcensus_hh, clear;

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













