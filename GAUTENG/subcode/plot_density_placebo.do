clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;

**************************;
*  PLOT PLACRBO DENSITY  *;
**************************;

* PARAMETERS;
global bin = 10; /* distance bin width */

* RUN LOCALLY?;
global LOCAL = 1;

* MAKE DATASET?;
global DATA_PREP = 0;

if $LOCAL==1 {;
	cd ..;
	global rdp  = "all";
};

* import plotreg program;
do subcode/import_plotreg.do;

* load data;
cd ../..;
cd Generated/Gauteng;

if $DATA_PREP==1 {;

  	local qry = " 

  	SELECT AA.STR_FID, AA.distance AS distance_placebo, 
           AA.cluster AS cluster_placebo, AA.s_lu_code,

           BB.area AS placebo_hull_area, BB.placebo_yr

    FROM 

  	(
    SELECT  B.STR_FID, B.distance, B.cluster, A.s_lu_code
    FROM bblu_pre  AS A  
    JOIN distance_bblu_placebo AS B ON A.STR_FID=B.STR_FID  
    WHERE A.s_lu_code=7.1 OR A.s_lu_code=7.2
  
    UNION
  
    SELECT D.STR_FID, D.distance, D.cluster, C.s_lu_code
    FROM bblu_post AS C 
    JOIN distance_bblu_placebo AS D ON C.STR_FID=D.STR_FID   
    WHERE (C.s_lu_code=7.1 OR C.s_lu_code=7.2)
    /**********************/
    AND C.cf_units = 'High'
    /**********************/
    ) AS AA 

    JOIN placebo_conhulls AS BB ON AA.cluster = BB.cluster

    ";

  odbc query "gauteng";
	odbc load, exec("`qry'") clear;

	g formal = (s_lu_code=="7.1");
	g post   = (substr(STR_FID,1,4)=="post");	

	save bbluplot_placebo, replace;

	};

use bbluplot_placebo, clear;

drop if placebo_yr==.;

* go to working dir;
cd ../..;
cd Output/GAUTENG/bbluplots_placebo;

* cut distances;
sum distance_placebo;
global max = round(ceil(`r(max)'),100);
egen dists_placebo = cut(distance_placebo),at(-100($bin)$max);

* gen counts;
bys cluster_placebo dists_placebo post formal: g count =_N;
bys cluster_placebo dists_placebo post formal: g n =_n;

preserve;
keep if n==1;
drop n STR_FID distance_placebo s_lu_code; 
reshape wide count, i(cluster_placebo dists_placebo formal ) j(post);
gen deltalog = ln(count1) - ln(count0);
gen delta = count1 - count0;
gen delta_prcnt = (count1 - count0)/count0;
gen dists_reg = dists_placebo;
replace dists_reg = 2000+abs(dists_placebo) if dists_placebo < 0;
reg delta b1190.dists_reg#b1.formal i.cluster_placebo;
plotreg bbluplot bbluplot_placebo;
restore;

* exit stata;
exit, STATA clear; 
