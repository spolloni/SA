clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;

* RUN LOCALLY?;
global LOCAL = 1;

local qry = "

  SELECT AA.*, BB.distance AS dist_rdp, BB.cluster AS clust_rdp,
         CC.cluster_siz AS clust_siz_rdp, CC.mode_yr AS mode_yr_rdp,
         CC.frac1 AS frac1_rdp, CC.frac2 AS frac2_rdp, EE.area,
         DD.distance AS dist_placebo, DD.cluster AS clust_placebo 

  FROM 

  (SELECT 
         A.munic_name, A.mun_code, A.purch_yr, A.purch_mo, A.purch_day,
         A.purch_price, A.trans_id, A.property_id, A.seller_name,
         B.erf_size, B.latitude, B.longitude 
  FROM transactions AS A
  JOIN erven AS B ON A.property_id = B.property_id
  JOIN rdp   AS C ON B.property_id = C.property_id
  WHERE C.rdp_never=1 ) AS AA

  LEFT JOIN distance_nrdp_rdp AS BB ON BB.property_id = AA.property_id 

  LEFT JOIN (SELECT DISTINCT cluster, cluster_siz, mode_yr, frac1, frac2 
  FROM rdp_clusters) AS CC on BB.cluster = CC.cluster

  LEFT JOIN distance_nrdp_placebo AS DD ON DD.property_id = AA.property_id 

  LEFT JOIN placebo_conhulls AS EE on EE.cluster = DD.cluster

  ";

* set cd;
cd ../..;
if $LOCAL==1{;cd ..;};
cd Generated/GAUTENG;

* load data; 
odbc query "gauteng";
odbc load, exec("`qry'") clear;

* set up ;
destring purch_yr purch_mo purch_day mun_code, replace;
gen trans_num = substr(trans_id,strpos(trans_id, "_")+1,.);

* non-rdp cluster size;
bys clust_placebo: gen n = _n;
bys clust_placebo: egen clust_placebo_siz = max(n);
drop n;

* gen required vars;
gen lprice = log(purch_price);
gen erf_size2 = erf_size^2;
gen erf_size3 = erf_size^3;

* save data;
save "gradplot_placebo.dta", replace;

* exit stata;
exit, STATA clear; 
