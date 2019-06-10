sum 
clear 

set more off
set scheme s1mono

#delimit;

global buffer_bblu_query   = 1;
global buffer_bblu_add     = 1;


if $LOCAL==1 {;
	cd .. ;
};

* load data;
cd ../.. ;
cd Generated/Gauteng;

if $buffer_bblu_query == 1 {;

cap prog drop buffer_query ;
prog define buffer_query ;

local qry = " 
SELECT A.OGC_FID, COUNT(A.OGC_FID) AS buildings, 
sum(CASE   WHEN DI.OGC_FID IS NOT NULL  THEN 1 ELSE 0   END) AS proj_rdp,        
sum(CASE   WHEN D.distance<=250 AND DI.OGC_FID IS NULL THEN 1 ELSE 0    END) AS buffer_rdp_1,
sum(CASE   WHEN D.distance>250 AND D.distance<=500 AND DI.OGC_FID IS NULL    THEN 1      ELSE 0  END) AS buffer_rdp_2,

sum(CASE   WHEN DIP.OGC_FID IS NOT NULL      THEN 1  ELSE 0 END) AS proj_placebo,         
sum(CASE   WHEN DP.distance<=250 AND DIP.OGC_FID IS NULL   THEN 1 ELSE 0  END) AS buffer_placebo_1,
sum(CASE   WHEN DP.distance>250 AND DP.distance<=500 AND DIP.OGC_FID IS NULL   THEN 1   ELSE 0  END) AS buffer_placebo_2

 FROM bblu_pre_in_`1' AS A 
LEFT JOIN
(SELECT D.distance, D.input_id  
    FROM (SELECT DB.* FROM distance_bblu_pre_gcro_full AS DB JOIN rdp_cluster AS CR ON DB.target_id=CR.cluster )
     AS D
     GROUP BY D.input_id 
    HAVING D.distance==min(D.distance) ) AS D ON D.input_id = A.OGC_FID_bblu_pre
LEFT JOIN
(SELECT DI.OGC_FID      FROM (SELECT DB.* FROM int_gcro_full_bblu_pre AS DB JOIN rdp_cluster AS CR ON DB.cluster=CR.cluster ) AS DI) 
AS DI ON DI.OGC_FID = A.OGC_FID_bblu_pre
LEFT JOIN
(SELECT D.distance, D.input_id  
    FROM (SELECT DB.* FROM distance_bblu_pre_gcro_full AS DB JOIN placebo_cluster AS CR ON DB.target_id=CR.cluster )     AS D
     GROUP BY D.input_id 
    HAVING D.distance==min(D.distance)) 
    AS DP ON DP.input_id = A.OGC_FID_bblu_pre
LEFT JOIN
(SELECT DI.OGC_FID  
    FROM (SELECT DB.* FROM int_gcro_full_bblu_pre AS DB JOIN placebo_cluster AS CR ON DB.cluster=CR.cluster ) AS DI) 
AS DIP ON DIP.OGC_FID = A.OGC_FID_bblu_pre
GROUP BY A.OGC_FID ";

odbc query "gauteng";
odbc load, exec("`qry'") clear; 

destring *, replace force ; 

 g year = `2';

save "buffer_${dist_break_reg1}_${dist_break_reg2}_bblu_`1'.dta", replace;
end;


cap prog drop buffer_query_type ;
prog define buffer_query_type ;

local qry = " 
SELECT A.OGC_FID, COUNT(A.OGC_FID) AS buildings, 
sum(CASE   WHEN DI.OGC_FID IS NOT NULL  THEN 1 ELSE 0   END) AS proj_rdp,        
sum(CASE   WHEN D.distance<=250 AND DI.OGC_FID IS NULL THEN 1 ELSE 0    END) AS buffer_rdp_1,
sum(CASE   WHEN D.distance>250 AND D.distance<=500 AND DI.OGC_FID IS NULL    THEN 1      ELSE 0  END) AS buffer_rdp_2,

sum(CASE   WHEN DIP.OGC_FID IS NOT NULL      THEN 1  ELSE 0 END) AS proj_placebo,         
sum(CASE   WHEN DP.distance<=250 AND DIP.OGC_FID IS NULL   THEN 1 ELSE 0  END) AS buffer_placebo_1,
sum(CASE   WHEN DP.distance>250 AND DP.distance<=500 AND DIP.OGC_FID IS NULL   THEN 1   ELSE 0  END) AS buffer_placebo_2

 FROM bblu_pre_in_`1' AS A 
LEFT JOIN
(SELECT D.distance, D.input_id  
    FROM (SELECT DB.* FROM distance_bblu_pre_gcro_full AS DB JOIN rdp_cluster AS CR ON DB.target_id=CR.cluster LEFT JOIN gcro_type AS GT ON GT.OGC_FID = CR.cluster WHERE GT.type`4'  )
     AS D
     GROUP BY D.input_id 
    HAVING D.distance==min(D.distance) ) AS D ON D.input_id = A.OGC_FID_bblu_pre
LEFT JOIN
(SELECT DI.OGC_FID      FROM (SELECT DB.* FROM int_gcro_full_bblu_pre AS DB JOIN rdp_cluster AS CR ON DB.cluster=CR.cluster LEFT JOIN gcro_type AS GT ON GT.OGC_FID = CR.cluster WHERE GT.type`4') AS DI) 
AS DI ON DI.OGC_FID = A.OGC_FID_bblu_pre
LEFT JOIN
(SELECT D.distance, D.input_id  
    FROM (SELECT DB.* FROM distance_bblu_pre_gcro_full AS DB JOIN placebo_cluster AS CR ON DB.target_id=CR.cluster LEFT JOIN gcro_type AS GT ON GT.OGC_FID = CR.cluster WHERE GT.type`4')     AS D
     GROUP BY D.input_id 
    HAVING D.distance==min(D.distance)) 
    AS DP ON DP.input_id = A.OGC_FID_bblu_pre
LEFT JOIN
(SELECT DI.OGC_FID   FROM (SELECT DB.* FROM int_gcro_full_bblu_pre AS DB JOIN placebo_cluster AS CR ON DB.cluster=CR.cluster LEFT JOIN gcro_type AS GT ON GT.OGC_FID = CR.cluster WHERE GT.type`4') AS DI) 
AS DIP ON DIP.OGC_FID = A.OGC_FID_bblu_pre
GROUP BY A.OGC_FID ";

odbc query "gauteng";
odbc load, exec("`qry'") clear; 

destring *, replace force ; 

foreach var of varlist buildings proj_rdp buffer_rdp_1 buffer_rdp_2 proj_placebo buffer_placebo_1 buffer_placebo_2 {;
ren `var' `var'_t`3';
};
 g year = `2';

save "buffer_${dist_break_reg1}_${dist_break_reg2}_bblu_`1'_type_`3'.dta", replace;
end;


* buffer_query ea_1996 1996 ;
* buffer_query_type ea_1996 1996 1 "==1" ;
* buffer_query_type ea_1996 1996 2 "==2" ;
* buffer_query_type ea_1996 1996 3 " IS NULL" ;

* buffer_query sal_2001 2001 ;
* buffer_query_type sal_2001 2001 1 "==1" ;
* buffer_query_type sal_2001 2001 2 "==2" ;
* buffer_query_type sal_2001 2001 3 " IS NULL" ;

* buffer_query sal_ea_2011      2011 ;
* buffer_query_type sal_ea_2011 2011 1 "==1" ;
* buffer_query_type sal_ea_2011 2011 2 "==2" ;
* buffer_query_type sal_ea_2011 2011 3 " IS NULL" ;


use "buffer_${dist_break_reg1}_${dist_break_reg2}_bblu_ea_1996.dta", clear ;
merge 1:1 OGC_FID using "buffer_${dist_break_reg1}_${dist_break_reg2}_bblu_ea_1996_type_1.dta", nogen;
merge 1:1 OGC_FID using "buffer_${dist_break_reg1}_${dist_break_reg2}_bblu_ea_1996_type_2.dta", nogen;
merge 1:1 OGC_FID using "buffer_${dist_break_reg1}_${dist_break_reg2}_bblu_ea_1996_type_3.dta", nogen;
drop buildings_t1 buildings_t2 buildings_t3 ;
save "buffer_${dist_break_reg1}_${dist_break_reg2}_bblu_ea_1996_total.dta", replace;

use "buffer_${dist_break_reg1}_${dist_break_reg2}_bblu_sal_2001.dta", clear ;
merge 1:1 OGC_FID using "buffer_${dist_break_reg1}_${dist_break_reg2}_bblu_sal_2001_type_1.dta", nogen;
merge 1:1 OGC_FID using "buffer_${dist_break_reg1}_${dist_break_reg2}_bblu_sal_2001_type_2.dta", nogen;
merge 1:1 OGC_FID using "buffer_${dist_break_reg1}_${dist_break_reg2}_bblu_sal_2001_type_3.dta", nogen;
drop buildings_t1 buildings_t2 buildings_t3 ;
save "buffer_${dist_break_reg1}_${dist_break_reg2}_bblu_sal_2001_total.dta", replace;

use "buffer_${dist_break_reg1}_${dist_break_reg2}_bblu_sal_ea_2011.dta", clear ;
merge 1:1 OGC_FID using "buffer_${dist_break_reg1}_${dist_break_reg2}_bblu_sal_ea_2011_type_1.dta", nogen;
merge 1:1 OGC_FID using "buffer_${dist_break_reg1}_${dist_break_reg2}_bblu_sal_ea_2011_type_2.dta", nogen;
merge 1:1 OGC_FID using "buffer_${dist_break_reg1}_${dist_break_reg2}_bblu_sal_ea_2011_type_3.dta", nogen;
drop buildings_t1 buildings_t2 buildings_t3 ;
save "buffer_${dist_break_reg1}_${dist_break_reg2}_bblu_sal_ea_2011_total.dta", replace;


use "buffer_${dist_break_reg1}_${dist_break_reg2}_bblu_ea_1996_total.dta", clear;
append using "buffer_${dist_break_reg1}_${dist_break_reg2}_bblu_sal_2001_total.dta" ;
append using "buffer_${dist_break_reg1}_${dist_break_reg2}_bblu_sal_ea_2011_total.dta" ;

ren OGC_FID area_code;
save "buffer_${dist_break_reg1}_${dist_break_reg2}_bblu.dta", replace;

};






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



