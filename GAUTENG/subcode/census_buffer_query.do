
clear 

set more off
set scheme s1mono

#delimit;

global buffer_query   = 0;
global buffer_add     = 1;


if $LOCAL==1 {;
	cd .. ;
};

* load data;
cd ../.. ;
cd Generated/Gauteng;

if $buffer_query == 1 {;

local qry = " 
SELECT OGC_FID AS area_code, census_area AS census_area_placebo , census_cluster_int AS census_cluster_int_placebo , census_b1_int AS census_b1_int_placebo, census_b2_int  AS census_b2_int_placebo, 1996 as year
    FROM 
    ea_1996_buffer_area_int_${dist_break_reg1}_${dist_break_reg2}_placebo 
  UNION 
SELECT sal_code AS area_code, census_area AS census_area_placebo , census_cluster_int AS census_cluster_int_placebo  , census_b1_int AS census_b1_int_placebo , census_b2_int AS census_b2_int_placebo, 2001 as year
    FROM 
    sal_2001_buffer_area_int_${dist_break_reg1}_${dist_break_reg2}_placebo 
  UNION 
SELECT sal_code AS area_code, census_area AS census_area_placebo , census_cluster_int  AS census_cluster_int_placebo , census_b1_int AS census_b1_int_placebo , census_b2_int AS census_b2_int_placebo, 2011 as year
    FROM 
    sal_2011_buffer_area_int_${dist_break_reg1}_${dist_break_reg2}_placebo 
 ";


odbc query "gauteng";
odbc load, exec("`qry'") clear; 

destring *, replace force ; 
save "buffer_${dist_break_reg1}_${dist_break_reg2}_placebo.dta", replace;


local qry = " 
SELECT OGC_FID AS area_code, census_area AS census_area_rdp , census_cluster_int AS census_cluster_int_rdp , census_b1_int AS census_b1_int_rdp, census_b2_int  AS census_b2_int_rdp, 1996 as year
    FROM 
    ea_1996_buffer_area_int_${dist_break_reg1}_${dist_break_reg2}_rdp
  UNION 
SELECT sal_code AS area_code, census_area AS census_area_rdp , census_cluster_int AS census_cluster_int_rdp  , census_b1_int AS census_b1_int_rdp , census_b2_int AS census_b2_int_rdp, 2001 as year
    FROM 
    sal_2001_buffer_area_int_${dist_break_reg1}_${dist_break_reg2}_rdp 
  UNION 
SELECT sal_code AS area_code, census_area AS census_area_rdp , census_cluster_int  AS census_cluster_int_rdp , census_b1_int AS census_b1_int_rdp , census_b2_int AS census_b2_int_rdp, 2011 as year
    FROM 
    sal_2011_buffer_area_int_${dist_break_reg1}_${dist_break_reg2}_rdp 
 ";


odbc query "gauteng";
odbc load, exec("`qry'") clear; 

destring *, replace force ; 

save "buffer_${dist_break_reg1}_${dist_break_reg2}_rdp.dta", replace;


local qry = " 
SELECT * FROM buffer_area_${dist_break_reg1}_${dist_break_reg2}
 ";
odbc query "gauteng";
odbc load, exec("`qry'") clear; 
destring *, replace force ; 

save "buffer_area_${dist_break_reg1}_${dist_break_reg2}.dta", replace;



};



if $buffer_add == 1 {;

cd ../..;
cd $output;

use "temp_censushh_agg${V}.dta", clear; 

cd ../../../..;
cd Generated/GAUTENG;

merge 1:1 area_code year using  "buffer_${dist_break_reg1}_${dist_break_reg2}_placebo.dta";
drop if _merge==2;
drop _merge;

merge 1:1 area_code year using  "buffer_${dist_break_reg1}_${dist_break_reg2}_rdp.dta";
drop if _merge==2;
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

save "temp_censushh_agg_buffer_${dist_break_reg1}_${dist_break_reg2}${V}.dta", replace; 





use "temp_censuspers_agg_het${V}.dta", clear; 

cd ../../../..;
cd Generated/GAUTENG;

merge 1:1 area_code year using  "buffer_${dist_break_reg1}_${dist_break_reg2}_placebo.dta";
drop if _merge==2;
drop _merge;

merge 1:1 area_code year using  "buffer_${dist_break_reg1}_${dist_break_reg2}_rdp.dta";
drop if _merge==2;
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

save "temp_censuspers_agg_buffer_${dist_break_reg1}_${dist_break_reg2}${V}.dta", replace; 



};


