clear


set more off
set scheme s1mono

#delimit;
grstyle init;
grstyle set imesh, horizontal;

if $LOCAL==1 {;
	cd ..;
};

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


cap prog drop grid_query;

prog define grid_query;


*  GC.name, GC.descriptio;
*  GC.name, GC.descriptio;
* 		      JOIN gcro_publichousing AS GC ON D.target_id = GC.OGC_FID; 
*	          JOIN gcro_publichousing AS GC ON D.target_id = GC.OGC_FID;
*	BP.name AS name_placebo, BP.descriptio AS desc_placebo, ;
*	B.name AS name_rdp, B.descriptio AS desc_rdp ; 

clear;
	local qry = "
	SELECT  AA.grid_id, C.OGC_FID, C.s_lu_code, C.t_lu_code, XY.X, XY.Y, 

	B.distance AS rdp_distance, B.target_id AS rdp_cluster, IR.area_int AS area_int_rdp, 

	BP.distance AS placebo_distance, BP.target_id AS placebo_cluster, IP.area_int AS area_int_placebo, 

 	GT.type AS type_rdp, GTP.type AS type_placebo

	FROM grid_temp_3 AS AA 

	LEFT JOIN grid_bblu_`1' AS A  ON A.grid_id=AA.grid_id

	      LEFT JOIN 
	        (SELECT D.input_id, D.distance, D.target_id, COUNT(D.input_id) AS count
	          FROM distance_grid_temp_3_gcro_full AS D
	          JOIN rdp_cluster AS R ON R.cluster = D.target_id
	          GROUP BY D.input_id  HAVING D.distance == MIN(D.distance) 
	        ) AS B ON AA.grid_id=B.input_id

	      LEFT JOIN 
	        (SELECT D.input_id, D.distance, D.target_id, COUNT(D.input_id) AS count
	          FROM distance_grid_temp_3_gcro_full AS D
	          JOIN placebo_cluster AS R ON R.cluster = D.target_id
	          GROUP BY D.input_id  HAVING D.distance == MIN(D.distance) 
	        ) AS BP ON AA.grid_id=BP.input_id  

	      LEFT JOIN (SELECT A.* FROM  bblu_`1' AS A WHERE (A.s_lu_code=7.1 OR A.s_lu_code=7.2) `2') 
	      AS C ON A.OGC_FID = C.OGC_FID

	      LEFT JOIN grid_xy AS XY ON XY.grid_id = AA.grid_id

	    LEFT JOIN (SELECT IT.* FROM  int_gcro_full_grid_temp_3 AS IT JOIN rdp_cluster AS PC ON PC.cluster = IT.cluster ) 
	      AS IR ON IR.grid_id = AA.grid_id

	    LEFT JOIN (SELECT IT.* FROM  int_gcro_full_grid_temp_3 AS IT JOIN placebo_cluster AS PC ON PC.cluster = IT.cluster ) 
	      AS IP ON IP.grid_id = AA.grid_id

	    LEFT JOIN gcro_type AS GT ON GT.OGC_FID = B.target_id
		LEFT JOIN gcro_type AS GTP ON GTP.OGC_FID = BP.target_id

	";


	odbc query "gauteng";
	odbc load, exec("`qry'");

	drop if rdp_cluster==. & placebo_cluster==.;

	outcome_gen;

	drop s_lu_code t_lu_code;


	destring area_int*, replace force;

	 foreach var in $outcomes {;
	    egen `var'_s = sum(`var'), by(grid_id);
	    drop `var';
	    ren `var'_s `var';
	  };

	  drop OGC_FID;

	  duplicates drop grid_id, force;

	  ren grid_id id  ;

	  save bbluplot_grid_`1', replace  ;

end;


grid_query pre ;
grid_query post  " AND A.cf_units = 'High' "; 

use bbluplot_grid_pre, clear;

g post=0;

append using bbluplot_grid_post;
replace post=1 if post==.;

save bbluplot_grid, replace;

erase  bbluplot_grid_pre.dta;
erase  bbluplot_grid_post.dta;


