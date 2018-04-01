clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;


global LOCAL = 1;

local qry1 = "
	SELECT A.purch_yr, A.purch_mo, 
         A.purch_day, A.prov_code, D.cluster, D.mode_yr,
         D.frac1, D.frac2     

	FROM transactions AS A
	JOIN erven AS B ON A.property_id = B.property_id
  JOIN rdp   AS C ON B.property_id = C.property_id
  JOIN rdp_clusters AS D ON B.property_id = D.property_id
  LEFT JOIN rdp_conhulls as E on D.cluster = E.cluster

  WHERE D.cluster!=0
  ";

* A.t_lu_code

local qry2 = "
  SELECT  B.STR_FID, B.distance, B.cluster, A.s_lu_code
  FROM bblu_pre  AS A  JOIN distance_bblu AS B     ON A.STR_FID=B.STR_FID
  WHERE A.s_lu_code=7.1 OR A.s_lu_code=7.2

  UNION

  SELECT D.STR_FID, D.distance, D.cluster, C.s_lu_code
  FROM bblu_post AS C  JOIN distance_bblu AS D    ON C.STR_FID=D.STR_FID
    WHERE C.s_lu_code=7.1 OR C.s_lu_code=7.2
  ";


* load data; 
qui odbc query "gauteng";
odbc load, exec("`qry2'") clear;

** cd ../..;
if $LOCAL==1{;cd ..;};
** cd Generated/GAUTENG/;


*exit, stata clear;  

/*



destring purch_yr purch_mo purch_day, replace;
keep munic_name prov_code cluster mode_yr frac1 frac2 perimeter area;
bys cluster: keep if _n==1;

tempfile file1;
save `file1';

odbc load, exec("`qry2'") clear;
merge m:1 cluster using `file1',keep(match) nogen;

* save data;
* save "`8'bblu_densityplot.dta", replace;

* exit stata;
* exit, STATA clear;  

