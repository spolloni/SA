clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;

local rdp  = "`1'";
local algo = "`2'";
local par1 = "`3'";
local par2 = "`4'";
local bw   = "`5'";
local sig  = "`6'";
local type = "`7'";

local qry1 = "
	SELECT A.munic_name, A.purch_yr, A.purch_mo, 
         A.purch_day, A.prov_code, D.cluster     
	FROM transactions AS A
	JOIN erven AS B ON A.property_id = B.property_id
  JOIN rdp   AS C ON A.trans_id = C.trans_id
  JOIN rdp_clusters_`rdp'_`algo'_`par1'_`par2' AS D ON A.trans_id = D.trans_id
  WHERE D.cluster!=0
  ";

local qry2 = "
  SELECT A.OGC_FID, A.m_lu_code, A.s_lu_code, A.t_lu_code, A.dop,
  B.STR_FID, B.distance, B.cluster, B.inhull
  FROM bblu_pre AS A
  JOIN distance_bblupre_`rdp'_`algo'_`par1'_`par2'_`bw'_`sig' AS B
  ON A.OGC_FID=B.OGC_FID
  WHERE A.s_lu_code=7.1 OR A.s_lu_code=7.2
  UNION 
  SELECT C.OGC_FID, C.m_lu_code, C.s_lu_code, C.t_lu_code, C.dop,
  D.STR_FID, D.distance, D.cluster, D.inhull 
  FROM bblu_rl2017 AS C
  JOIN distance_bblupost_`rdp'_`algo'_`par1'_`par2'_`bw'_`sig' AS D
  ON C.OGC_FID=D.OGC_FID
  WHERE C.s_lu_code=7.1 OR C.s_lu_code=7.2
	";

* load data; 
odbc query "lightstone";
odbc load, exec("`qry1'") clear;

destring purch_yr purch_mo purch_day, replace;
bys cluster: egen mod_yr  = mode(purch_yr),min;
bys cluster: egen mod_yr2 = mode(purch_yr),max;
replace mod_yr = 0.5*(mod_yr+mod_yr2);
bys cluster: egen denom = count(mod_yr!=.);
gen dum1 = (abs(purch_yr-mod_yr) <= 0.5 );
bys cluster: egen num1 = sum(dum1);
gen dum2 = (abs(purch_yr-mod_yr) <= 1 );
bys cluster: egen num2 = sum(dum2);
gen frac1 = num1/denom;
gen frac2 = num2/denom;
keep munic_name prov_code cluster mod_yr frac1 frac2;
bys cluster: keep if _n==1;

tempfile file1;
save `file1';

odbc load, exec("`qry2'") clear;
merge m:1 cluster using `file1',keep(match) nogen;

* save data;
save "`8'bblu_densityplot.dta", replace;

* exit stata;
exit, STATA clear;  

