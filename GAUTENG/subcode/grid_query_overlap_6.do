clear


set more off
set scheme s1mono

#delimit;
grstyle init;
grstyle set imesh, horizontal;

if $LOCAL==1 {;
	cd ..;
};

global load_grids = 1;

global grid = "100";
global dist_break_reg1 = "500";
global dist_break_reg2 = "3000";

global outcomes = " total_buildings for inf inf_backyard inf_non_backyard ";


cd ../..;
cd Generated/Gauteng;

cap program drop outcome_gen;
prog outcome_gen;

  g for    = s_lu_code == "7.1";
  g inf    = s_lu_code == "7.2";
  g total_buildings = for + inf ;

  g inf_backyard  = t_lu_code == "7.2.3";
  g inf_non_backyard  = inf_b==0 & inf==1;

end;


local qry = " SELECT A.*, B.cluster_area, B.cluster_b1_area, B.cluster_b2_area, 
 B.cluster_b3_area, B.cluster_b4_area,
  B.cluster_b5_area, B.cluster_b6_area 
FROM 
grid_temp_${grid}_buffer_area_int_${dist_break_reg1}_${dist_break_reg2} AS A
JOIN buffer_area_${dist_break_reg1}_${dist_break_reg2} AS B ON A.grid_id = B.grid_id ";
odbc query "gauteng";
odbc load, exec("`qry'") clear; 

destring *, replace force ; 
* ren cluster_area cluster_int_area;
* ren cluster_b1_area b1_int_area;
* ren cluster_b2_area b2_int_area;
* ren cluster_b3_area b3_int_area;
* ren cluster_b4_area b4_int_area;
* ren cluster_b5_area b5_int_area;
* ren cluster_b6_area b6_int_area;



foreach var of varlist cluster_int b1_int b2_int b3_int b4_int b5_int b6_int  {;
forvalues r=0/1 {;

if `r'==1 {;
	local name "rdp";
};
else  {;
	local name "placebo";
};

g `var'_`name'=`var' if rdp==`r';
gegen `var'_tot_`name'  = sum(`var'_`name'), by(grid_id);
gegen `var'_`name'_max  = max(`var'_`name'), by(grid_id);

g `var'_`name'_id_max = cluster if `var'_`name'_max == `var'_`name' & `var'_`name'!=.;
gegen `var'_`name'_id = max(`var'_`name'_id_max), by(grid_id);

* g `var'_`name'_shr   = `var'_tot_`name'/`var'_area;

drop `var'_`name' `var'_`name'_id_max `var'_`name'_max ;

};
};



keep grid_id *_id *_tot_* *_area ;
duplicates drop grid_id, force;


save "buffer_grid_${dist_break_reg1}_${dist_break_reg2}_overlap.dta", replace;




if $load_grids == 1 {;

cap prog drop grid_query;

prog define grid_query;

clear;
	local qry = "
	SELECT  AA.grid_id, C.OGC_FID, C.s_lu_code, C.t_lu_code

	FROM grid_temp_${grid} AS AA 

	LEFT JOIN grid_bblu_`1'grid_temp_${grid} AS A  ON A.grid_id=AA.grid_id

	LEFT JOIN (SELECT A.* FROM  bblu_`1' AS A WHERE (A.s_lu_code=7.1 OR A.s_lu_code=7.2) `2') 
	      AS C ON A.OGC_FID = C.OGC_FID

	";


	odbc query "gauteng";
	odbc load, exec("`qry'");

	outcome_gen;

	drop s_lu_code t_lu_code;

	 foreach var in $outcomes {;
	    gegen `var'_s = sum(`var'), by(grid_id);
	    drop `var';
	    ren `var'_s `var';
	  };

	  drop OGC_FID;

	  duplicates drop grid_id, force;

	  ren grid_id id  ;

	  save bbluplot_grid_`1'_overlap, replace  ;
end;


grid_query pre ;
grid_query post  " AND A.cf_units = 'High' "; 

};

use bbluplot_grid_pre_overlap, clear;

g post=0;

append using bbluplot_grid_post_overlap;
replace post=1 if post==.;

ren id grid_id ;
fmerge m:1 grid_id using "buffer_grid_${dist_break_reg1}_${dist_break_reg2}_overlap.dta" ;
drop if _merge==2;
drop _merge;
ren grid_id id;

save bbluplot_grid_${grid}_overlap, replace;


* erase  bbluplot_grid_pre_overlap.dta;
* erase  bbluplot_grid_post_overlap.dta;

* erase "buffer_grid_${dist_break_reg1}_${dist_break_reg2}_overlap.dta";
