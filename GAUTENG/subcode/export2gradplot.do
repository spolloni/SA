clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;

* RUN LOCALLY?;
global LOCAL = 1;

local qry = "
  SELECT 

         A.munic_name, A.mun_code, A.purch_yr, A.purch_mo, A.purch_day,
         A.purch_price, A.trans_id, A.property_id, A.seller_name,

         B.erf_size, B.latitude, B.longitude, 

         C.rdp_all, C.rdp_gcroonly, C.rdp_notownship, C.rdp_phtownship, C.gov,
         C.no_seller_rdp, C.big_seller_rdp, C.rdp_never, C.trans_id as trans_id_rdp,

         D.distance, D.cluster, 

         E.cluster as cl, E.mode_yr, E.frac1, E.frac2, E.cluster_siz, 

         F.formal_pre, F.informal_pre, F.formal_post, F.informal_post

  FROM transactions AS A
  JOIN erven AS B ON A.property_id = B.property_id
  JOIN rdp   AS C ON B.property_id = C.property_id
  LEFT JOIN distance_nrdp_rdp AS D ON B.property_id = D.property_id 
  LEFT JOIN rdp_conhulls AS F ON F.cluster = D.cluster
  LEFT JOIN (SELECT property_id, cluster, mode_yr, frac1, frac2, cluster_siz
       FROM rdp_clusters WHERE cluster != 0 ) AS E ON B.property_id = E.property_id
  WHERE NOT (D.cluster IS NULL AND E.cluster IS NULL) 
  ";

* set cd;
cd ../..;
if $LOCAL==1{;cd ..;};
cd Generated/GAUTENG;

* load data; 
odbc query "gauteng";
odbc load, exec("`qry'") clear;

* set up frac vars;
destring purch_yr purch_mo purch_day mun_code, replace;
gen trans_num = substr(trans_id,strpos(trans_id, "_")+1,.);
replace cluster=cl if cluster==.;
foreach var in mode_yr frac1 frac2 cluster_siz  formal_pre informal_pre formal_post informal_post {;
   bys cluster: egen max = max(`var');
   replace `var' = max if cl ==.;
   drop max;
};

* create date variables and dummies;
gen abs_yrdist = abs(purch_yr - mode_yr); 
gen day_date = mdy(purch_mo,purch_day,purch_yr);
gen mo_date  = ym(purch_yr,purch_mo);
gen hy_date  = hofd(dofm(mo_date)); // half-years;
*******************;
bys mo_date cluster rdp_all: gen N = _N if purch_yr == mode_yr;
replace N = -99 if rdp_all==0 | N==.;
bys cluster: egen maxN  = max(N);
gen NN = mo_date if N==maxN;
bys cluster: egen con_mo  = max(NN);
drop N maxN NN;
*gen con_mo   = ym(mode_yr,07);
*******************;
gen mo2con  = mo_date - con_mo;
format day_date %td;
format mo_date %tm;
format hy_date %th;

* non-rdp cluster size;
bys cluster rdp_never: gen n = _n;
replace n = 0 if rdp_never==0;
bys cluster: egen cluster_siz_nrdp = max(n);
drop n;

* gen required vars;
gen lprice = log(purch_price);
gen erf_size2 = erf_size^2;
gen erf_size3 = erf_size^3;

* save data;
save "gradplot.dta", replace;

* exit stata;
exit, STATA clear; 
