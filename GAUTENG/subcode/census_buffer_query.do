
clear 

set more off
set scheme s1mono

#delimit;

global buffer_query   = 1;
global buffer_add     = 1;


if $LOCAL==1 {;
	cd .. ;
};

* load data;
cd ../.. ;
cd Generated/Gauteng;

if $buffer_query == 1 {;

local qry = " 
SELECT A.OGC_FID AS area_code, area AS shape_area,

cluster_int_rdp, b1_int_rdp, b2_int_rdp, 
cluster_int_placebo, b1_int_placebo, b2_int_placebo,

cluster_int_rdp_1, b1_int_rdp_1, b2_int_rdp_1,
cluster_int_placebo_1, b1_int_placebo_1, b2_int_placebo_1, 

cluster_int_rdp_2, b1_int_rdp_2, b2_int_rdp_2 ,
cluster_int_placebo_2, b1_int_placebo_2, b2_int_placebo_2 ,

cluster_int_rdp_3, b1_int_rdp_3, b2_int_rdp_3 ,
cluster_int_placebo_3, b1_int_placebo_3, b2_int_placebo_3, 1996 as year

    FROM 
    ea_1996_buffer_area_int_${dist_break_reg1}_${dist_break_reg2} AS A 
    JOIN ea_1996_area AS B ON A.OGC_FID = B.OGC_FID
";
odbc query "gauteng";
odbc load, exec("`qry'") clear; 

destring *, replace force ; 

save "buffer_${dist_break_reg1}_${dist_break_reg2}_1996.dta", replace;



local qry = " 

SELECT A.OGC_FID AS area_code, area AS shape_area,

cluster_int_rdp, b1_int_rdp, b2_int_rdp, 
cluster_int_placebo, b1_int_placebo, b2_int_placebo,

cluster_int_rdp_1, b1_int_rdp_1, b2_int_rdp_1,
cluster_int_placebo_1, b1_int_placebo_1, b2_int_placebo_1, 

cluster_int_rdp_2, b1_int_rdp_2, b2_int_rdp_2 ,
cluster_int_placebo_2, b1_int_placebo_2, b2_int_placebo_2 ,

cluster_int_rdp_3, b1_int_rdp_3, b2_int_rdp_3 ,
cluster_int_placebo_3, b1_int_placebo_3, b2_int_placebo_3, 2001 as year

    FROM 
    sal_2001_buffer_area_int_${dist_break_reg1}_${dist_break_reg2} AS A
    JOIN sal_2001_area AS B ON A.OGC_FID = B.OGC_FID ;";
odbc query "gauteng";
odbc load, exec("`qry'") clear; 

destring *, replace force ; 

save "buffer_${dist_break_reg1}_${dist_break_reg2}_2001.dta", replace;



local qry = "

SELECT B.OGC_FID AS area_code, AA.OGC_FID*-1 AS ea_id, area AS shape_area,

cluster_int_rdp, b1_int_rdp, b2_int_rdp, 
cluster_int_placebo, b1_int_placebo, b2_int_placebo,

cluster_int_rdp_1, b1_int_rdp_1, b2_int_rdp_1,
cluster_int_placebo_1, b1_int_placebo_1, b2_int_placebo_1, 

cluster_int_rdp_2, b1_int_rdp_2, b2_int_rdp_2 ,
cluster_int_placebo_2, b1_int_placebo_2, b2_int_placebo_2 ,

cluster_int_rdp_3, b1_int_rdp_3, b2_int_rdp_3 ,
cluster_int_placebo_3, b1_int_placebo_3, b2_int_placebo_3, 2011 as year
    FROM 
    ea_2011_buffer_area_int_${dist_break_reg1}_${dist_break_reg2} AS A 
    LEFT JOIN ea_2011 AS AA ON  
    	A.OGC_FID = AA.OGC_FID
    LEFT JOIN sal_2011 AS B ON 
    	AA.sal_code = B.sal_code
    LEFT JOIN ea_2011_area AS C ON A.OGC_FID = C.OGC_FID ; ";

odbc query "gauteng";
odbc load, exec("`qry'") clear; 

destring *, replace force ; 

replace area_code = ea_id if area_code==. & ea_id!=.;
drop ea_id;

fcollapse  (sum) shape_area cluster_int_rdp b1_int_rdp b2_int_rdp 
cluster_int_placebo b1_int_placebo b2_int_placebo 

cluster_int_rdp_1 b1_int_rdp_1 b2_int_rdp_1 
cluster_int_placebo_1 b1_int_placebo_1 b2_int_placebo_1  

cluster_int_rdp_2 b1_int_rdp_2 b2_int_rdp_2 
cluster_int_placebo_2 b1_int_placebo_2 b2_int_placebo_2 

cluster_int_rdp_3 b1_int_rdp_3 b2_int_rdp_3 
cluster_int_placebo_3 b1_int_placebo_3 b2_int_placebo_3 (firstnm) year, by(area_code) ;

save "buffer_${dist_break_reg1}_${dist_break_reg2}_2011.dta", replace;


use "buffer_${dist_break_reg1}_${dist_break_reg2}_1996.dta", clear;
append using "buffer_${dist_break_reg1}_${dist_break_reg2}_2001.dta" ;
append using "buffer_${dist_break_reg1}_${dist_break_reg2}_2011.dta" ;

save "buffer_${dist_break_reg1}_${dist_break_reg2}.dta", replace;




erase "buffer_${dist_break_reg1}_${dist_break_reg2}_1996.dta";
erase "buffer_${dist_break_reg1}_${dist_break_reg2}_2001.dta";
erase "buffer_${dist_break_reg1}_${dist_break_reg2}_2011.dta";





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

*drop area area_int_rdp area_int_placebo ;

cd ../../../..;
cd Generated/GAUTENG;

merge 1:1 area_code year using  "buffer_${dist_break_reg1}_${dist_break_reg2}.dta";
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


replace area= shape_area if area==.;
drop shape_area;

cd ../..;
cd $output;


save "temp_censushh_agg_buffer_${dist_break_reg1}_${dist_break_reg2}${V}.dta", replace; 




use "temp_censuspers_agg${V}.dta", clear; 

cd ../../../..;
cd Generated/GAUTENG;

merge 1:1 area_code year using  "buffer_${dist_break_reg1}_${dist_break_reg2}.dta";
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


replace area= shape_area if area==.;
drop shape_area;

cd ../..;
cd $output;

save "temp_censuspers_agg_buffer_${dist_break_reg1}_${dist_break_reg2}${V}.dta", replace; 



};


