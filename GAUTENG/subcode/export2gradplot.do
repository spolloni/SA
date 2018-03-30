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

         E.cluster as cl, E.mode_yr, E.frac1, E.frac2, E.cluster_siz

  FROM transactions AS A
  JOIN erven AS B ON A.property_id = B.property_id
  JOIN rdp   AS C ON B.property_id = C.property_id
  LEFT JOIN distance_nrdp AS D ON B.property_id = D.property_id 
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
foreach var in mode_yr frac1 frac2 {;
   bys cluster: egen max = max(`var');
   replace `var' = max if cl ==.;
   drop max;
};

* create date variables and dummies;
gen abs_yrdist = abs(purch_yr - mode_yr); 
gen day_date = mdy(purch_mo,purch_day,purch_yr);
gen mo_date  = ym(purch_yr,purch_mo);
gen con_day  = mdy(07,02,mode_yr);
replace con_day = mdy(01,01,mode_yr+1 ) if mod(mode_yr,1)>0;
gen con_mo   = ym(mode_yr,07);
format day_date %td;
format mo_date %tm;
gen day2con = day_date - con_day;
gen mo2con  = mo_date - con_mo;

* gen required vars;
gen lprice = log(purch_price);
gen erf_size2 = erf_size^2;
gen erf_size3 = erf_size^3;

* identify bank sellers;

* save data;
save "gradplot.dta", replace;

* exit stata;
exit, STATA clear; 
