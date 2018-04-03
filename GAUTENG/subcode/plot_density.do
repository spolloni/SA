clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;

******************;
*  PLOT DENSITY  *;
******************;

* PARAMETERS;
global fr1 = "0";
global fr2 = "0";
global bin = 10; /* distance bin width */

* RUN LOCALLY?;
global LOCAL = 0;

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

  	SELECT * FROM 

  	(
    SELECT  B.STR_FID, B.distance, B.cluster, A.s_lu_code
    FROM bblu_pre  AS A  
    JOIN distance_bblu AS B ON A.STR_FID=B.STR_FID  
    WHERE A.s_lu_code=7.1 OR A.s_lu_code=7.2
  
    UNION
  
    SELECT D.STR_FID, D.distance, D.cluster, C.s_lu_code
    FROM bblu_post AS C 
    JOIN distance_bblu AS D ON C.STR_FID=D.STR_FID   
    WHERE C.s_lu_code=7.1 OR C.s_lu_code=7.2
    ) AS AA 

    JOIN (SELECT DISTINCT cluster as cl, mode_yr, frac1, frac2 from rdp_clusters) AS BB 
    ON AA.cluster = BB.cl
    ";

    odbc query "gauteng";
	odbc load, exec("`qry'") clear;

	g formal = (s_lu_code=="7.1");
	g post   = (substr(STR_FID,1,4)=="post");	
	
	drop cl;		
	save bbluplot, replace;

	};

use bbluplot, clear;

* go to working dir;
cd ../..;
cd Output/GAUTENG/bbluplots;

* cut distances;
sum distance;
global max = round(ceil(`r(max)'),100);
egen dists = cut(distance),at(-100($bin)$max);


* gen counts;
bys cluster dists post formal: g count =_N;
bys cluster dists post formal: g n =_n;

* data subset for regs;
global ifregs = "
       frac1 > $fr1  &
       frac2 > $fr2  &
       mode_yr>2002 
       ";

preserve;
keep if n==1;
drop n STR_FID distance s_lu_code; 
reshape wide count, i(cluster mode_yr frac1 frac2 dists formal ) j(post);
gen deltalog = ln(count1) - ln(count0);
gen delta = count1 - count0;
gen delta_prcnt = (count1 - count0)/count0;
gen dists_reg = dists;	
replace dists_reg = 2000+abs(dists) if dists < 0;
reg delta b1190.dists_reg#b1.formal i.cluster if $ifregs;
plotreg bbluplot bbluplot;
restore;

* exit stata;
exit, STATA clear; 

