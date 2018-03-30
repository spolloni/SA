clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;
******************;
*  PLOT DENSITY  *;
******************;

global bin  = 20;
global bw   = 1000;


global LOCAL = 1;
global DATA_PREP = 0;
	local temp_file "Generated/Gauteng/temp/plot_density_temp.dta";

if $LOCAL==1 {;
	cd ..;
	global rdp  = "all";
};
cd ../..;

if $DATA_PREP==1 {;
  local qry = "
  SELECT  B.STR_FID, B.distance, B.cluster, A.s_lu_code
  FROM bblu_pre  AS A  JOIN distance_bblu AS B     ON A.STR_FID=B.STR_FID  WHERE A.s_lu_code=7.1 OR A.s_lu_code=7.2
  	UNION
  SELECT D.STR_FID, D.distance, D.cluster, C.s_lu_code
  FROM bblu_post AS C  JOIN distance_bblu AS D    ON C.STR_FID=D.STR_FID   WHERE C.s_lu_code=7.1 OR C.s_lu_code=7.2
  ";
qui odbc query "gauteng";
odbc load, exec("`qry'") clear;
	g formal=s_lu_code=="7.1" 	;
		drop s_lu_code 			;
	g post=substr(STR_FID,1,4)=="post";
		drop STR_FID 			;
save `temp_file', replace;
	};



use `temp_file', clear;

egen dists = cut(distance),at(-100($bin)$bw)	;  
drop if dists==.							;
drop distance ;

bys dists post formal: g C=_N ;
bys dists post formal: g nn=_n ;

tw  
	scatter C dists if nn==1 & post==0 & formal==0, yaxis(1) ||
	scatter C dists if nn==1 & post==0 & formal==1, yaxis(1) ||
	scatter C dists if nn==1 & post==1 & formal==0, yaxis(1) ||
	scatter C dists if nn==1 & post==1 & formal==1, yaxis(1)	
	, legend(order(1 "pre inf" 2 "pre for" 3 "post inf" 4 "post for")) ;



*tw  
*	scatter C dists if nn==1 & post==0 & formal==0, yaxis(1) ||
*	scatter C dists if nn==1 & post==0 & formal==1, yaxis(1) 	
*	, legend(order(1 "pre inf" 2 "pre for")) ;



/*

* set parameters;
* PARAMETERS;
global rdp  = "`1'";
*global top  = "99";
*global bot  = "1";
global tw   = "4";
global bin  = 20;

*   import plotreg program;
* do subcode/import_plotreg.do; 

* indicate post-waves from pre-waves;m
gen post = (substr(STR_FID,1,4)=="post");

* remove clusters with no pre;
bys cluster: egen precount = sum(abs(post-1));
drop if precount==0;
drop precount;
replace area = area/1000;



* remove clusters non-concentrated;
*keep if frac1>=.7 & frac2>=.7;



*keep if distance < 0;
preserve;
gen formal = s_lu_code=="7.1" & distance < 0;
gen informal= s_lu_code=="7.2"& distance < 0;
bys cluster post: egen count_formal = sum(formal);
bys cluster post: egen count_informal = sum(informal);
bys cluster post: egen count_total = count(_n);
bys cluster post: gen n = _n;
keep if n==1;
gen formal_density = count_formal/area;
gen informal_density = count_informal/area;
gen total_density = count_total/area;
keep *_density cluster post frac2 prov_code;
reshape wide *_density, i(cluster frac2 prov_code) j(post);
gen formal_diff = formal_density1 - formal_density0;
drop if formal_density0==.;
drop if  formal_density1==.;
drop if  formal_density1==0;
drop if  formal_diff <.1896782;
keep cluster;
tempfile file1;
save `file1';
restore;

merge m:1 cluster using `file1',keep(match) nogen;





/*
tw
(scatter formal_density1 formal_density0, mc(gs3) msiz(small))
(function y=x, range(0 2.5) lc(gs0) lp(-)),
legend(off)
aspect(1)
title("Formal Housing")
xtitle("2001 density (building/100m{superscript:2})")
ytitle("2012 density ");
tw
(scatter informal_density1 informal_density0, mc(gs3) msiz(small))
(function y=x, range(0 4) lc(gs0) lp(-)),
legend(off)
aspect(1)
title("Informal Housing")
xtitle("2001 density (building/100m{superscript:2})");
*/




/*
keep if distance >0 & distance <600;

tw 
(kdensity  distance if post ==1 & s_lu_code=="7.1")
(kdensity  distance if post ==0 & s_lu_code=="7.1"), 
legend(order(1 "post" 2 "pre"));
*/
*tw (kdensity  distance if post ==1 & s_lu_code=="7.2")(kdensity  distance if post ==0 & s_lu_code=="7.2"), legend(order(1 "post" 2 "pre"));




* cut and keep positive distances;
egen dists = cut(distance),at(0($bin)$bw);  
drop if dists ==.;

* count by cut;
bys cluster post dists: egen all_resid = count(_n);
bys cluster post dists: egen for_resid = sum(s_lu_code=="7.1"); 
bys cluster post dists: egen inf_resid = sum(s_lu_code=="7.2");
bys cluster post dists: drop if _n>1;
gen rel_inf_resid = inf_resid/all_resid;
gen rel_for_resid = for_resid/all_resid;
ds *_resid;
foreach var in `r(varlist)'{;
bys post dists: egen mean_`var' = mean(`var');
};
bys post dists: gen n = _n;

* mean for plots;
tw 
(sc mean_inf_resid dists if n==1 & post==1 & dists>0) 
(sc mean_inf_resid dists if n==1 & post==0 & dists>0) ,
legend( order( 1 "post" 2 "pre"))
; */








