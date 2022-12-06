
clear 

set more off
set scheme s1mono

#delimit;

global buffer_query   = 1;


if $LOCAL==1 {;
	cd .. ;
};

* load data;
cd ../.. ;
cd Generated/Gauteng;

if $buffer_query == 1 {;


local qry = " SELECT A.*, B.cluster_area, B.cluster_b1_area, B.cluster_b2_area, 
 B.cluster_b3_area, B.cluster_b4_area,
  B.cluster_b5_area, B.cluster_b6_area, B.cluster_b7_area, B.cluster_b8_area, 1996 as year
FROM 
ea_1996_buffer_area_int_${dist_break_reg1}_${dist_break_reg2} AS A
JOIN buffer_area_${dist_break_reg1}_${dist_break_reg2}_ea_1996 AS B ON A.OGC_FID = B.OGC_FID ";
odbc query "gauteng";
odbc load, exec("`qry'") clear; 

destring *, replace force ; 

save "buffer_${dist_break_reg1}_${dist_break_reg2}_1996_overlap.dta", replace;


local qry = " SELECT A.*, B.cluster_area, B.cluster_b1_area, B.cluster_b2_area, 
 B.cluster_b3_area, B.cluster_b4_area,
  B.cluster_b5_area, B.cluster_b6_area, B.cluster_b7_area, B.cluster_b8_area, 2001 as year
FROM 
sal_2001_buffer_area_int_${dist_break_reg1}_${dist_break_reg2} AS A
JOIN buffer_area_${dist_break_reg1}_${dist_break_reg2}_sal_2001 AS B ON A.OGC_FID = B.OGC_FID ";
odbc query "gauteng";
odbc load, exec("`qry'") clear; 

destring *, replace force ; 

save "buffer_${dist_break_reg1}_${dist_break_reg2}_2001_overlap.dta", replace;


local qry = " SELECT A.*, B.cluster_area, B.cluster_b1_area, B.cluster_b2_area, 
 B.cluster_b3_area, B.cluster_b4_area,
  B.cluster_b5_area, B.cluster_b6_area, B.cluster_b7_area, B.cluster_b8_area, 2011 as year, S.sal_code
FROM 
sal_ea_2011_buffer_area_int_${dist_break_reg1}_${dist_break_reg2} AS A
JOIN buffer_area_${dist_break_reg1}_${dist_break_reg2}_sal_ea_2011 AS B ON A.OGC_FID = B.OGC_FID 
LEFT JOIN sal_ea_2011 AS S ON A.OGC_FID = S.OGC_FID";
odbc query "gauteng";
odbc load, exec("`qry'") clear; 

destring *, replace force ; 

drop sal_code;
* drop OGC_FID;
* ren sal_code OGC_FID;

save "buffer_${dist_break_reg1}_${dist_break_reg2}_2011_overlap.dta", replace;



use "buffer_${dist_break_reg1}_${dist_break_reg2}_1996_overlap.dta", clear;
append using "buffer_${dist_break_reg1}_${dist_break_reg2}_2001_overlap.dta" ;
append using "buffer_${dist_break_reg1}_${dist_break_reg2}_2011_overlap.dta" ;

* save "buffer_${dist_break_reg1}_${dist_break_reg2}_overlap.dta", replace;



* erase "buffer_${dist_break_reg1}_${dist_break_reg2}_1996_overlap.dta";
* erase "buffer_${dist_break_reg1}_${dist_break_reg2}_2001_overlap.dta";
* erase "buffer_${dist_break_reg1}_${dist_break_reg2}_2011_overlap.dta";



cd ../..;
cd $output;




foreach var of varlist cluster_int b1_int b2_int b3_int b4_int b5_int b6_int b7_int b8_int  {;
forvalues r=0/1 {;

if `r'==1 {;
    local name "rdp";
};
else  {;
    local name "placebo";
};

g `var'_`name'=`var' if rdp==`r';
gegen `var'_tot_`name'  = sum(`var'_`name'), by(OGC_FID year);
gegen `var'_`name'_max  = max(`var'_`name'), by(OGC_FID year);

g `var'_`name'_id_max = cluster if `var'_`name'_max == `var'_`name' & `var'_`name'!=.;
gegen `var'_`name'_id = max(`var'_`name'_id_max), by(OGC_FID year);

* g `var'_`name'_shr   = `var'_tot_`name'/`var'_area;

drop `var'_`name' `var'_`name'_id_max `var'_`name'_max ;

};
};



keep OGC_FID *_id *_tot_* *_area  year ;
duplicates drop OGC_FID year, force;

ren OGC_FID area_code;

save "temp_census_overlap.dta", replace;



use "temp_censushh_agg${V}.dta", clear; 

    merge 1:1 area_code year using  "temp_census_overlap.dta";
    drop if _merge==2;
    drop _merge;


save "temp_censushh_agg_buffer_${dist_break_reg1}_${dist_break_reg2}_overlap.dta", replace; 



};






