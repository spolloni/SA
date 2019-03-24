
clear
set more off
set scheme s1mono


#delimit;

local qry = "SELECT A.*, B.score 
	FROM gcro AS A
	JOIN gcro_link AS C ON A.cluster = C.cluster_new
	LEFT JOIN gcro_temp_year AS B ON C.cluster_original = B.OGC_FID WHERE area>0.5";
	qui odbc query "gauteng";
	odbc load, exec("`qry'") clear;

egen max_score=max(score), by(cluster);
keep if score+.00001>=max_score;
duplicates drop cluster, force;

browse if score!=.;
browse if max_score==1; /* 44 match exactly */




