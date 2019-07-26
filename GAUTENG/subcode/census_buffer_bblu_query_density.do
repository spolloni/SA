sum 
clear 

set more off
set scheme s1mono

#delimit;

global buffer_bblu_query   = 0;
global buffer_bblu_add     = 1;


if $LOCAL==1 {;
	cd .. ;
};

* load data;
cd ../.. ;
cd Generated/Gauteng;


cap prog drop building_query ;
prog define building_query ;

local qry = " 
SELECT A.OGC_FID, 
SUM(CASE WHEN B.s_lu_code=='7.1' THEN 1 ELSE 0 END) AS for,
SUM(CASE WHEN B.s_lu_code=='7.2' THEN 1 ELSE 0 END) AS inf,  
SUM(CASE WHEN B.t_lu_code=='7.2.3' THEN 1 ELSE 0 END) AS bkyd
 FROM bblu_`2'_in_`1' AS A 
 JOIN bblu_`2' AS B ON A.OGC_FID_bblu_`2' = B.OGC_FID `3'
GROUP BY A.OGC_FID ";

odbc query "gauteng";
odbc load, exec("`qry'") clear; 

destring *, replace force ; 
ren OGC_FID area_code;
save "building_query_`1'.dta", replace;
end;

building_query "ea_1996" "pre";
building_query "sal_2001" "pre";
building_query "sal_2011" "post" " WHERE B.cf_units = 'High' ";



use  "building_query_ea_1996.dta", clear ;
g year = 1996 ; 
append using  "building_query_sal_2001.dta" ;
replace year=2001 if year==.;
append using  "building_query_sal_2011.dta" ;
replace year=2011 if year==.;

cd ../..;
cd $output;

duplicates drop area_code year, force;
save "census_building_query.dta", replace;




/*


save "temp_censuspers_agg_buffer_bblu_${dist_break_reg1}_${dist_break_reg2}${V}.dta", replace; 




/*



if $buffer_bblu_add == 1 {;

cd ../..;
cd $output;

use "temp_censushh_agg${V}.dta", clear; 

*drop area area_int_rdp area_int_placebo ;

cd ../../../..;
cd Generated/GAUTENG;

merge 1:1 area_code year using  "buffer_${dist_break_reg1}_${dist_break_reg2}_bblu.dta";
* drop if _merge==2;
drop _merge;


ren cluster_placebo cluster; 
merge m:1 cluster using "buffer_area_${dist_break_reg1}_${dist_break_reg2}.dta" ;
drop if _merge==2;
drop _merge;
ren cluster cluster_placebo;
ren cluster_area cluster_area_placebo;
ren cluster_b1_area cluster_b1_area_placebo;
ren cluster_b2_area cluster_b2_area_placebo;


ren cluster_rdp cluster; 
merge m:1 cluster using "buffer_area_${dist_break_reg1}_${dist_break_reg2}.dta" ;
drop if _merge==2;
drop _merge;
ren cluster cluster_rdp;
ren cluster_area cluster_area_rdp;
ren cluster_b1_area cluster_b1_area_rdp;
ren cluster_b2_area cluster_b2_area_rdp;


cd ../..;
cd $output;


save "temp_censushh_agg_buffer_bblu_${dist_break_reg1}_${dist_break_reg2}${V}.dta", replace; 




use "temp_censuspers_agg${V}.dta", clear; 

cd ../../../..;
cd Generated/GAUTENG;

merge 1:1 area_code year using  "buffer_${dist_break_reg1}_${dist_break_reg2}_bblu.dta";
* drop if _merge==2;
drop _merge;

ren cluster_placebo cluster; 
merge m:1 cluster using "buffer_area_${dist_break_reg1}_${dist_break_reg2}.dta" ;
drop if _merge==2;
drop _merge;
ren cluster cluster_placebo;
ren cluster_area cluster_area_placebo;
ren cluster_b1_area cluster_b1_area_placebo;
ren cluster_b2_area cluster_b2_area_placebo;


ren cluster_rdp cluster; 
merge m:1 cluster using "buffer_area_${dist_break_reg1}_${dist_break_reg2}.dta" ;
drop if _merge==2;
drop _merge;
ren cluster cluster_rdp;
ren cluster_area cluster_area_rdp;
ren cluster_b1_area cluster_b1_area_rdp;
ren cluster_b2_area cluster_b2_area_rdp;


cd ../..;
cd $output;

save "temp_censuspers_agg_buffer_bblu_${dist_break_reg1}_${dist_break_reg2}${V}.dta", replace; 



};




* local qry = " 
* SELECT A.OGC_FID, COUNT(A.OGC_FID) AS buildings, 
* sum(CASE   WHEN DI.OGC_FID IS NOT NULL  THEN 1 ELSE 0   END) AS proj_rdp,        
* sum(CASE   WHEN D.distance<=250 AND DI.OGC_FID IS NULL THEN 1 ELSE 0    END) AS buffer_rdp_1,
* sum(CASE   WHEN D.distance>250 AND D.distance<=500 AND DI.OGC_FID IS NULL    THEN 1      ELSE 0  END) AS buffer_rdp_2,

* sum(CASE   WHEN DIP.OGC_FID IS NOT NULL      THEN 1  ELSE 0 END) AS proj_placebo,         
* sum(CASE   WHEN DP.distance<=250 AND DIP.OGC_FID IS NULL   THEN 1 ELSE 0  END) AS buffer_placebo_1,
* sum(CASE   WHEN DP.distance>250 AND DP.distance<=500 AND DIP.OGC_FID IS NULL   THEN 1   ELSE 0  END) AS buffer_placebo_2

*  FROM bblu_pre_in_ea_1996 AS A 
* LEFT JOIN
* (SELECT D.distance, D.input_id  
*     FROM (SELECT DB.* FROM distance_bblu_pre_gcro_full AS DB JOIN rdp_cluster AS CR ON DB.target_id=CR.cluster )
*      AS D
*      GROUP BY D.input_id 
*     HAVING D.distance==min(D.distance) ) AS D ON D.input_id = A.OGC_FID_bblu_pre
* LEFT JOIN
* (SELECT DI.OGC_FID      FROM (SELECT DB.* FROM int_gcro_full_bblu_pre AS DB JOIN rdp_cluster AS CR ON DB.cluster=CR.cluster ) AS DI) 
* AS DI ON DI.OGC_FID = A.OGC_FID_bblu_pre
* LEFT JOIN
* (SELECT D.distance, D.input_id  
*     FROM (SELECT DB.* FROM distance_bblu_pre_gcro_full AS DB JOIN placebo_cluster AS CR ON DB.target_id=CR.cluster )     AS D
*      GROUP BY D.input_id 
*     HAVING D.distance==min(D.distance)) 
*     AS DP ON DP.input_id = A.OGC_FID_bblu_pre
* LEFT JOIN
* (SELECT DI.OGC_FID  
*     FROM (SELECT DB.* FROM int_gcro_full_bblu_pre AS DB JOIN placebo_cluster AS CR ON DB.cluster=CR.cluster ) AS DI) 
* AS DIP ON DIP.OGC_FID = A.OGC_FID_bblu_pre
* GROUP BY A.OGC_FID
* ";



