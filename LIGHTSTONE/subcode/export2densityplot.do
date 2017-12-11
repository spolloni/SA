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

local qry = "
	SELECT A.munic_name, A.purch_yr, A.purch_mo, A.purch_day,
		    A.purch_price, A.trans_id, A.property_id, B.erf_size,
        C.rdp_`rdp', C.ever_rdp_`rdp', D.cluster, 
        A.seller_name, B.latitude, B.longitude
	FROM transactions AS A
	JOIN erven AS B ON A.property_id = B.property_id
  JOIN rdp   AS C ON A.trans_id = C.trans_id
  JOIN rdp_clusters_`rdp'_`algo'_`par1'_`par2' AS D ON A.trans_id = D.trans_id
  WHERE D.cluster!=0
  ";
*local qry = "
*  SELECT A.OGC_FID, A.m_lu_code, A.s_lu_code, A.t_lu_code,
*  B.STR_FID, B.distance, B.cluster, B.inhull
*  FROM bblu_pre AS A
*  JOIN distance_bblupre_`rdp'_`algo'_`par1'_`par2'_`bw'_`sig' AS B
*  ON A.OGC_FID=B.OGC_FID
*  UNION 
*  SELECT C.OGC_FID, C.m_lu_code, C.s_lu_code, C.t_lu_code,
*  D.STR_FID, D.distance, D.cluster, D.inhull 
*  FROM bblu_rl2017 AS C
*  JOIN distance_bblupost_`rdp'_`algo'_`par1'_`par2'_`bw'_`sig' AS D
*  ON C.OGC_FID=D.OGC_FID
*	";

* load data; 
odbc query "lightstone";
odbc load, exec("`qry'");

* save data;
save "`8'`type'_densityplot.dta", replace;

* exit stata;
exit, STATA clear;  