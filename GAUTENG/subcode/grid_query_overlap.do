clear


set more off
set scheme s1mono

#delimit;
grstyle init;
grstyle set imesh, horizontal;

if $LOCAL==1 {;
	cd ..;
};

global gcro_over 		= 0;
global load_buffer_1 	= 0;
global load_grids 		= 1;

global load_buffer_2 	= 0;
global merge_all  		= 0;
global undev   			= 0;
global elev   			= 0;


global grid = "100";
global dist_break_reg1 = "500";
global dist_break_reg2 = "4000";

* global dist_break_reg1 = "250";
* global dist_break_reg2 = "2000";

global outcomes = 
" total_buildings for inf inf_backyard 
inf_non_backyard other shops shops_inf
util util_water util_energy util_refuse
community health school";


cd ../..;
cd Generated/Gauteng;

cap program drop outcome_gen;
prog outcome_gen;

  g for    = s_lu_code == "7.1";
  g inf    = s_lu_code == "7.2";
  g total_buildings = for + inf ;

  g inf_backyard  = t_lu_code == "7.2.3";
  g inf_non_backyard  = inf_b==0 & inf==1;

  g other = s_lu_code != "7.1" & s_lu_code != "7.2";

  g shops = regexm(s_lu_code,"11.")==1;
  g shops_inf =  regexm(s_lu_code,"11.6")==1;

  g util        = regexm(s_lu_code,"6.")==1;
  g util_water  = regexm(s_lu_code,"6.1")==1;
  g util_energy = regexm(s_lu_code,"6.2")==1;
  g util_refuse = regexm(s_lu_code,"6.3")==1;
  
  g community = regexm(s_lu_code,"8.")==1;
  g health = regexm(s_lu_code,"9.")==1;
  g school = regexm(s_lu_code,"10.")==1;

end;


if $gcro_over  == 1 {;

local qry = " SELECT * FROM gcro_over ";
odbc query "gauteng";
odbc load, exec("`qry'") clear; 

destring *, replace force ; 


g shr_1 = area_int/AREA_1;
g shr_2 = area_int/AREA_2;

* browse if shr_1 >.5 | shr_2>.5;
* drop dp_1 dp_2;

g dp_1 = shr_1>.75 & rdp_1 == 0;
g dp_2 = shr_2>.75 & rdp_2 == 0;

replace dp_1 = 1 if dp_1==0 & rdp_1 == rdp_2 & shr_1 > shr_2 & shr_1>.5;
replace dp_2 = 1 if dp_2==0 & rdp_1 == rdp_2 & shr_2 > shr_1 & shr_2>.5;

g dp_1 = shr_1>.75 & rdp_1 == 0 & shr_2<.25;
g dp_2 = shr_1<.25 & shr_2>.75  & rdp_2 == 0;

preserve ;
	keep if dp_1 == 1;
	keep OGC_FID_1;
	ren OGC_FID_1 OGC_FID;
	save "over_1.dta", replace;
restore;

preserve ;
	keep if dp_2 == 1;
	keep OGC_FID_2;
	ren OGC_FID_2 OGC_FID;
	save "over_2.dta", replace;
restore;

use "over_1.dta", clear;
append using "over_2.dta";
duplicates drop OGC_FID, force;

g dp = 1;

odbc exec("DROP TABLE IF EXISTS gcro_over_list;"), dsn("gauteng");
	odbc insert, table("gcro_over_list") create;
odbc exec("CREATE INDEX gcro_over_index ON gcro_over_list (OGC_FID) ;"), dsn("gauteng");

};







if $load_buffer_1 == 1 {;

local qry = " SELECT A.*, B.cluster_area, B.cluster_b1_area, B.cluster_b2_area, 
 B.cluster_b3_area, B.cluster_b4_area,
  B.cluster_b5_area, B.cluster_b6_area,   B.cluster_b7_area, B.cluster_b8_area 
FROM 
(SELECT A.* FROM grid_temp_100_4000_buffer_area_int_${dist_break_reg1}_${dist_break_reg2} AS A 
LEFT JOIN gcro_over_list AS G ON G.OGC_FID = A.cluster 
WHERE G.dp IS NULL) AS A
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



foreach var of varlist cluster_int b1_int b2_int b3_int b4_int b5_int b6_int b7_int b8_int  {;
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

};


if $load_grids == 1 {;

cap prog drop grid_query;

prog define grid_query;

clear;
	local qry = "
	SELECT  AA.grid_id, C.OGC_FID, C.s_lu_code, C.t_lu_code,

	B.distance AS rdp_distance, B.target_id AS rdp_cluster, B.count AS rdp_count,
	P.distance AS placebo_distance, P.target_id AS placebo_cluster, P.count AS placebo_count,

	Y.cbd_dist AS cbd_dist_r, Z.cbd_dist AS cbd_dist_p,
	R.road_dist AS road_dist_r, Q.road_dist AS road_dist_p,

	V.X AS XX , V.Y AS YY

	FROM grid_temp_${grid}_4000 AS AA 

	LEFT JOIN 
	        (SELECT D.input_id, D.distance, D.target_id, COUNT(D.input_id) AS count
	          FROM distance_grid_temp_100_4000_gcro_full AS D
	          JOIN (SELECT R.* FROM rdp_cluster AS R LEFT JOIN gcro_over_list AS G ON  R.cluster =                           
                       G.OGC_FID WHERE G.dp IS NULL ) AS R ON R.cluster = D.target_id   		
	          GROUP BY D.input_id HAVING D.distance == MIN(D.distance ) ) AS B ON AA.grid_id=B.input_id

	LEFT JOIN 
	        (SELECT D.input_id, D.distance, D.target_id, COUNT(D.input_id) AS count
	          FROM distance_grid_temp_100_4000_gcro_full AS D
	          JOIN (SELECT R.* FROM placebo_cluster AS R LEFT JOIN gcro_over_list AS G ON  R.cluster =                           
                       G.OGC_FID WHERE G.dp IS NULL ) AS R ON R.cluster = D.target_id   		
	          GROUP BY D.input_id HAVING D.distance == MIN(D.distance ) )  AS P ON AA.grid_id=P.input_id  

	LEFT JOIN grid_bblu_`1'grid_temp_${grid}_4000 AS A  ON A.grid_id=AA.grid_id
	LEFT JOIN (SELECT A.* FROM  bblu_`1' AS A `2') 
	      AS C ON A.OGC_FID = C.OGC_FID


	LEFT JOIN cbd_dist AS Y ON Y.cluster = B.target_id
	LEFT JOIN cbd_dist AS Z ON Z.cluster = P.target_id

	LEFT JOIN road_dist AS R ON R.OGC_FID = B.target_id
	LEFT JOIN road_dist AS Q ON Q.OGC_FID = P.target_id

	LEFT JOIN grid_xy_100_4000 AS V ON V.grid_id = AA.grid_id
	";


	* LEFT JOIN cbd_dist AS CB ON AA.distance_ = CB.grid_id;
	* LEFT JOIN road_dist_grid AS RD ON AA.grid_id = RD.grid_id;

* WHERE (A.s_lu_code=7.1 OR A.s_lu_code=7.2) ;

	odbc query "gauteng";
	odbc load, exec("`qry'");

	outcome_gen;

	destring cbd_dist* road_dist*, replace force;

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
* grid_query post  " AND A.cf_units = 'High' "; 
grid_query post  "  WHERE A.cf_units = 'High' "; 



use bbluplot_grid_pre_overlap, clear;

g post=0;

append using bbluplot_grid_post_overlap;
replace post = 1 if post==. ;

ren id grid_id ;
fmerge m:1 grid_id using "buffer_grid_${dist_break_reg1}_${dist_break_reg2}_overlap.dta" ;
drop if _merge==2;
drop _merge;
ren grid_id id;

save bbluplot_grid_${grid}_${dist_break_reg1}_${dist_break_reg2}_overlap, replace;

};






if $load_buffer_2 == 1 {;


use bbluplot_grid_${grid}_overlap, clear;


g   proj_rdp = cluster_int_tot_rdp / cluster_area;
replace proj_rdp = 1 if proj_rdp>1 & proj_rdp<.;
g   proj_placebo = cluster_int_tot_placebo / cluster_area;
replace proj_placebo = 1 if proj_placebo>1 & proj_placebo<.;

g cluster_joined = .;
replace cluster_joined = cluster_int_placebo_id if (cluster_int_tot_placebo>  cluster_int_tot_rdp ) & cluster_joined==.;
replace cluster_joined = cluster_int_rdp_id if (cluster_int_tot_placebo<  cluster_int_tot_rdp ) & cluster_joined==.;

keep if post==0;
keep if proj_rdp==1 | proj_placebo==1;
gegen tbm = mean(total_buildings), by(cluster_joined);
keep if tbm ==0;

keep cluster_joined;
duplicates drop cluster_joined, force;
save "zeros.dta", replace;



local qry = " SELECT OGC_FID AS cluster_joined, name, descriptio AS des FROM gcro_publichousing";

odbc query "gauteng";
odbc load, exec("`qry'") clear;

duplicates drop cluster_joined, force;

replace des = lower(des);
g mixed = regexm(des,"mixed")==1;
keep if mixed==1;
keep cluster_joined;

save "mixed.dta", replace;




local qry = " SELECT A.*, B.cluster_area, B.cluster_b1_area, B.cluster_b2_area, 
 B.cluster_b3_area, B.cluster_b4_area,
  B.cluster_b5_area, B.cluster_b6_area, B.cluster_b7_area, B.cluster_b8_area 
FROM 
(SELECT A.* FROM grid_temp_100_buffer_area_int_${dist_break_reg1}_${dist_break_reg2} AS A 
LEFT JOIN gcro_over_list AS G ON G.OGC_FID = A.cluster 
WHERE G.dp IS NULL)
JOIN buffer_area_${dist_break_reg1}_${dist_break_reg2} AS B ON A.grid_id = B.grid_id ";
odbc query "gauteng";
odbc load, exec("`qry'") clear; 

destring *, replace force ; 


ren cluster cluster_joined;
merge m:1 cluster_joined using "mixed.dta";
	g mixed = _merge==3;
	drop if _merge==2;
	drop _merge;
ren cluster_joined cluster;


ren cluster cluster_joined;
merge m:1 cluster_joined using "zeros.dta";
	g zeros = _merge==3;
	drop if _merge==2;
	drop _merge;
ren cluster_joined cluster;



foreach var of varlist cluster_int b1_int b2_int b3_int b4_int b5_int b6_int  b7_int b8_int  {;
forvalues r=0/1 {;
foreach het in "" "_mixed" "_zeros" {;

if `r'==1 {;
	local name "rdp";
};
else {;
	local name "placebo";
};

local khet "";
if "`het'"=="_mixed" {;
	local khet " & mixed==1 ";
};
if "`het'"=="_zeros" {;
	local khet " & zeros==1 ";
};


g `var'_`name'`het'=`var' if rdp==`r' `khet';
gegen `var'_tot_`name'`het'  = sum(`var'_`name'`het'), by(grid_id);
gegen `var'_`name'`het'_max  = max(`var'_`name'`het'), by(grid_id);

g `var'_`name'`het'_id_max = cluster if `var'_`name'`het'_max == `var'_`name'`het' & `var'_`name'`het'!=.;
gegen `var'_`name'`het'_id = max(`var'_`name'`het'_id_max), by(grid_id);

drop `var'_`name'`het' `var'_`name'`het'_id_max `var'_`name'`het'_max ;

};
};
};

keep grid_id *_id *_tot_* *_area ;
duplicates drop grid_id, force;


save "buffer_grid_${dist_break_reg1}_${dist_break_reg2}_overlap_het.dta", replace;


};


if $merge_all== 1 {;

use bbluplot_grid_pre_overlap, clear;

g post=0;

append using bbluplot_grid_post_overlap;
replace post=1 if post==.;

ren id grid_id ;
fmerge m:1 grid_id using "buffer_grid_${dist_break_reg1}_${dist_break_reg2}_overlap_het.dta" ;
drop if _merge==2;
drop _merge;
ren grid_id id;

save "bbluplot_grid_${grid}_overlap_full_het.dta", replace;

};



if $undev == 1 {;

local qry = " 
SELECT * FROM grid_100_4000_to_cult_recreational 
UNION
SELECT * FROM grid_100_4000_to_hydr_areas
UNION
SELECT * FROM grid_100_4000_to_phys_landform_artific
";

odbc query "gauteng";
odbc load, exec("`qry'") clear; 

destring *, replace force;

gegen asum = sum(area_int), by(grid_id);

keep if asum>5000;

keep grid_id;
duplicates drop grid_id, force;
ren grid_id id;

save "undev_100_4000.dta", replace;

};



if $elev == 1 {;

local qry = " 
SELECT E.grid_id, F.height
 FROM grid_to_elevation_points_100_4000 AS E 
 JOIN elevation AS F ON E.fid = F.OGC_FID
";

odbc query "gauteng";
odbc load, exec("`qry'") clear; g

destring *, replace force;

gegen height_m = max(height), by(grid_id);
replace height=height_m;
keep grid_id height;
duplicates drop grid_id, force;
ren grid_id id;

save "grid_elevation_100_4000.dta", replace;

};




* erase  bbluplot_grid_pre_overlap.dta;
* erase  bbluplot_grid_post_overlap.dta;

* erase "buffer_grid_${dist_break_reg1}_${dist_break_reg2}_overlap.dta";
