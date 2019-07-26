sum 
clear 

set more off
set scheme s1mono

#delimit;



if $LOCAL==1 {;
	cd .. ;
};

* load data;
cd ../.. ;
cd Generated/Gauteng;


cap prog drop building_query ;
prog define building_query ;

local qry = " 
SELECT C.ea_code AS area_code, 
SUM(CASE WHEN B.s_lu_code=='7.1' THEN 1 ELSE 0 END) AS for,
SUM(CASE WHEN B.s_lu_code=='7.2' THEN 1 ELSE 0 END) AS inf,  
SUM(CASE WHEN B.t_lu_code=='7.2.3' THEN 1 ELSE 0 END) AS bkyd
 FROM bblu_`2'_in_`1' AS A 
 JOIN `1' AS C ON C.OGC_FID = A.OGC_FID
 JOIN bblu_`2' AS B ON A.OGC_FID_bblu_`2' = B.OGC_FID `3'

GROUP BY A.OGC_FID ";

odbc query "gauteng";
odbc load, exec("`qry'") clear; 

destring *, replace force ; 
* ren OGC_FID area_code;
save "building_query_`1'_`2'.dta", replace;
end;


building_query "ea_2001" "pre";
building_query "ea_2001" "post" " WHERE B.cf_units = 'High' ";



use  "building_query_ea_2001_pre.dta", clear ;
g bblu_year = 2001;
append using  "building_query_ea_2001_post.dta" ;
replace bblu_year= 2011 if bblu_year==.;
* g year = 2001 ; 


cd ../..;
cd $output;

duplicates drop area_code bblu_year, force;
save "census_building_query_ghs.dta", replace;




