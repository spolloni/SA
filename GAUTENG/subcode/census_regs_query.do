
clear 

set more off
set scheme s1mono

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

cap program drop gen_het;
prog gen_het;
  sum cbd_dist, detail;
  g het = cbd_dist>= `=r(p50)' & cbd_dist<.;
end;

global data_load  = 1;
global aggregate  = 1;

if $LOCAL==1 {;
	cd .. ;
};




* load data;
cd ../.. ;
cd Generated/Gauteng;

*****************************************************************;
************************ LOAD DATA ******************************;
*****************************************************************;
if $data_load == 1 {;

*  cast(B.input_id AS TEXT) as sal_code_rdp, ; 
* cast(BP.input_id AS TEXT) as sal_code_placebo,;



local qry = " 

  SELECT 

  AA.*,

  CR.cbd_dist AS cbd_dist_rdp, CP.cbd_dist AS cbd_dist_placebo,

  GT.type AS type_rdp, GTP.type AS type_placebo

  FROM (

    SELECT 

      A.H23_Quarters AS quarters_typ, A.H23a_HU AS dwelling_typ,
      A.H24_Room AS tot_rooms, A.H25_Tenure AS tenure, A.H26_Piped_Water AS water_piped,
      A.H26a_Sourc_Water AS water_source, A.H27_Toilet_Facil AS toilet_typ, 
      A.H28a_Cooking AS enrgy_cooking, A.H28b_Heating AS enrgy_heating,
      A.H28c_Lghting AS enrgy_lighting, A.H30_Refuse AS refuse_typ, A.DER2_HHSIZE AS hh_size,

      B.distance AS distance_rdp, B.target_id AS cluster_rdp, 
       BP.distance AS distance_placebo, BP.target_id AS cluster_placebo, 
      
      IR.area_int_rdp, IP.area_int_placebo, QQ.area,

      2001 AS year, A.SAL AS area_code,  XY.X, XY.Y, 

      SP.sp_code AS sp_1

    FROM census_hh_2001 AS A  

    LEFT JOIN 
        (SELECT D.input_id, D.distance, D.target_id, COUNT(D.input_id) AS count
          FROM distance_sal_2001_gcro${flink} AS D
          JOIN rdp_cluster AS R ON R.cluster = D.target_id
          WHERE D.distance<=4000
          GROUP BY D.input_id HAVING COUNT(D.input_id)<=50 AND D.distance == MIN(D.distance)
        ) AS B ON A.SAL=B.input_id

    LEFT JOIN 
        (SELECT D.input_id, D.distance, D.target_id, COUNT(D.input_id) AS count
          FROM distance_sal_2001_gcro${flink} AS D
          JOIN placebo_cluster AS R ON R.cluster = D.target_id
          WHERE D.distance<=4000
          GROUP BY D.input_id HAVING COUNT(D.input_id)<=50 AND D.distance == MIN(D.distance)
        ) AS BP ON A.SAL=BP.input_id

    LEFT JOIN  
    (SELECT IT.sal_code, IT.area_int AS area_int_rdp, IT.cluster  
    FROM  int_gcro${flink}_sal_2001 
    AS IT JOIN rdp_cluster AS PC ON PC.cluster = IT.cluster
    GROUP BY IT.sal_code
        HAVING IT.area_int = MAX(IT.area_int)
      )  
    AS IR ON IR.sal_code = A.SAL

    LEFT JOIN     
    (SELECT IT.sal_code, IT.area_int AS area_int_placebo, IT.cluster  
    FROM  int_gcro${flink}_sal_2001 
    AS IT JOIN placebo_cluster AS PC ON PC.cluster = IT.cluster
    GROUP BY IT.sal_code
        HAVING IT.area_int = MAX(IT.area_int)
     )  
    AS IP ON IP.sal_code = A.SAL

    LEFT JOIN area_sal_2001 AS QQ ON QQ.sal_code = A.SAL

    LEFT JOIN sal_2001_xy AS XY ON A.SAL = XY.sal_code

    LEFT JOIN sal_2001 AS SP ON A.SAL = SP.sal_code

    /* *** */
    UNION ALL 
    /* *** */

    SELECT 

      A.H01_QUARTERS AS quarters_typ, A.H02_MAINDWELLING AS dwelling_typ,
      A.H03_TOTROOMS AS tot_rooms, A.H04_TENURE AS tenure, A.H07_WATERPIPED AS water_piped,
      A.H08_WATERSOURCE AS water_source, A.H10_TOILET AS toilet_typ, 
      A.H11_ENERGY_COOKING AS enrgy_cooking, A.H11_ENERGY_HEATING AS enrgy_heating,
      A.H11_ENERGY_LIGHTING AS enrgy_lighting, A.H12_REFUSE AS refuse_typ, A.DERH_HSIZE AS hh_size,

      B.distance AS distance_rdp, B.target_id AS cluster_rdp, 
      BP.distance AS distance_placebo, BP.target_id AS cluster_placebo, 
      
      IR.area_int_rdp, IP.area_int_placebo, QQ.area,

      2011 AS year, A.SAL_CODE AS area_code,  XY.X, XY.Y, 

      SP.sp_1

    FROM census_hh_2011 AS A  

      LEFT JOIN 
        (SELECT D.input_id, D.distance, D.target_id, COUNT(D.input_id) AS count
          FROM distance_sal_2011_gcro${flink} AS D
          JOIN rdp_cluster AS R ON R.cluster = D.target_id
          WHERE D.distance<=4000
          GROUP BY D.input_id HAVING COUNT(D.input_id)<=50 AND D.distance == MIN(D.distance)
        ) AS B ON A.SAL_CODE=B.input_id

      LEFT JOIN 
        (SELECT D.input_id, D.distance, D.target_id, COUNT(D.input_id) AS count
          FROM distance_sal_2011_gcro${flink} AS D
          JOIN placebo_cluster AS R ON R.cluster = D.target_id
          WHERE D.distance<=4000
          GROUP BY D.input_id HAVING COUNT(D.input_id)<=50 AND D.distance == MIN(D.distance)
        ) AS BP ON A.SAL_CODE=BP.input_id

    LEFT JOIN  
    (SELECT IT.sal_code, IT.area_int AS area_int_rdp, IT.cluster  
    FROM  int_gcro${flink}_sal_2011 
    AS IT JOIN rdp_cluster AS PC ON PC.cluster = IT.cluster
    GROUP BY IT.sal_code
        HAVING IT.area_int = MAX(IT.area_int)
      )  
    AS IR ON IR.sal_code = A.SAL_CODE

    LEFT JOIN     
    (SELECT IT.sal_code, IT.area_int AS area_int_placebo, IT.cluster  
    FROM  int_gcro${flink}_sal_2011 
    AS IT JOIN placebo_cluster AS PC ON PC.cluster = IT.cluster
    GROUP BY IT.sal_code
        HAVING IT.area_int = MAX(IT.area_int)
     )  
    AS IP ON IP.sal_code = A.SAL_CODE

    LEFT JOIN  (SELECT * FROM sal_2011_s2001 AS G GROUP BY G.sal_code HAVING G.area_int==max(G.area_int)) AS SP ON A.SAL_CODE = SP.sal_code

    LEFT JOIN area_sal_2011 AS QQ ON QQ.sal_code = A.SAL_CODE

    LEFT JOIN sal_2011_xy AS XY ON A.SAL_CODE = XY.sal_code

  ) AS AA

  LEFT JOIN cbd_dist${flink} AS CP ON CP.cluster = AA.cluster_placebo

  LEFT JOIN cbd_dist${flink} AS CR ON CR.cluster = AA.cluster_rdp

  LEFT JOIN gcro_type AS GTP ON GTP.OGC_FID = CP.cluster

  LEFT JOIN gcro_type AS GT ON GT.OGC_FID = CR.cluster

  ";

odbc query "gauteng";
odbc load, exec("`qry'") clear;	

destring area_int_placebo area_int_rdp, replace force;  

drop if distance_rdp==. & distance_placebo==.;

destring cbd_dist_rdp cbd_dist_placebo, replace force;
g cbd_dist = cbd_dist_rdp ;
replace cbd_dist = cbd_dist_placebo if cbd_dist==. & cbd_dist_placebo!=. ;
drop cbd_dist_rdp cbd_dist_placebo ; 

save "DDcensus_hh_admin${V}.dta", replace;

};



if $aggregate == 1 {;

use "DDcensus_hh_admin${V}.dta", clear;


g het =1 if  cbd_dist<=$het ;
replace het = 0 if cbd_dist>$het & cbd_dist<. ;  /* NOTE! cbd_dist is only measured for treated/placebo clusters!!  careful! */

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
  distance_joined cluster_joined distance_rdp distance_placebo cluster_rdp cluster_placebo het type_rdp type_placebo  X Y sp_1
  , by(area_code year);


cd ../..;
cd $output;

save "temp_censushh_agg${V}.dta", replace;

};
*****************************************************************;
*****************************************************************;
*****************************************************************;

* exit, STATA clear;


