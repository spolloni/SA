clear all
set more off
set scheme s1mono
set matsize 11000
set maxvar 32767
#delimit;


/*
- imports and cleans price data
- at the bottom EXPORT TABLE of clusters and dates for use in next file
*/

* RUN LOCALLY?;
global LOCAL = 1;

local qry = "
  SELECT 

         A.munic_name, A.mun_code, A.purch_yr, A.purch_mo, A.purch_day,
         A.purch_price, A.trans_id, A.property_id, A.seller_name,

         B.erf_size, B.latitude, B.longitude, 

         C.rdp_all, C.rdp_gcroonly, C.rdp_notownship, C.rdp_phtownship, C.gov,
         C.no_seller_rdp, C.big_seller_rdp, C.rdp_never, C.trans_id as trans_id_rdp,

         D.distance AS distance_rdp, D.target_id AS cluster_rdp, D.count AS count_rdp,
         E.cluster AS cluster_rdp_int,

         F.distance AS distance_placebo, F.target_id AS cluster_placebo, F.count AS count_placebo,
         G.cluster AS cluster_placebo_int, F.placebo_yr AS mode_yr_placebo, GC.RDP_density

  FROM transactions AS A
  JOIN erven AS B ON A.property_id = B.property_id
  JOIN rdp   AS C ON B.property_id = C.property_id

  LEFT JOIN (
    SELECT input_id, distance, target_id, COUNT(input_id) AS count 
    FROM distance_erven_rdp 
    WHERE distance<=4000
    GROUP BY input_id 
    HAVING COUNT(input_id)<=50
      AND distance == MIN(distance)
  ) AS D ON D.input_id = B.property_id

  LEFT JOIN int_rdp_erven AS E  ON E.property_id = B.property_id

  LEFT JOIN  gcro AS GC ON D.target_id = GC.cluster

  LEFT JOIN (
    SELECT dep.input_id, dep.distance, dep.target_id, 
           COUNT(dep.input_id) AS count, gcro.placebo_yr
    FROM distance_erven_placebo as dep
    JOIN gcro on gcro.cluster = dep.target_id
    WHERE dep.distance<=4000
      AND gcro.placebo_yr IS NOT NULL
    GROUP BY dep.input_id 
    HAVING COUNT(dep.input_id)<=50 
      AND dep.distance == MIN(dep.distance)
  ) AS F ON F.input_id = B.property_id

  LEFT JOIN int_placebo_erven AS G  ON G.property_id = B.property_id";


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
destring trans_num, replace;

* get rid of missing distances;
drop if distance_placebo==. & distance_rdp==. ;

* get rid of missing prices;
drop if purch_price==. ;

* make distances negative if within projects ;
replace distance_placebo = distance_placebo*-1 if cluster_placebo==cluster_placebo_int;
replace distance_rdp = distance_rdp*-1 if cluster_rdp==cluster_rdp_int;

* purchase years/mode yr for transactions that intersect with projects;
g purch_yr_rdp = purch_yr if cluster_rdp!=. &  cluster_rdp == cluster_rdp_int & rdp_all==1 & trans_num==1;
egen mode_yr_rdp = mode(purch_yr_rdp), by(cluster_rdp) maxmode;

*drop cluster_rdp_int;
*drop cluster_placebo_int;

* create date variables;
gen abs_yrdist_rdp = abs(purch_yr - mode_yr_rdp); 
gen abs_yrdist_placebo = abs(purch_yr - mode_yr_placebo); 
gen day_date = mdy(purch_mo,purch_day,purch_yr);
gen mo_date  = ym(purch_yr,purch_mo);
gen hy_date  = hofd(dofm(mo_date)); // half-years;

* construction mode month for rdp;
bys mo_date cluster_rdp rdp_all trans_num: gen N = _N;
replace N = -99 if cluster_rdp==. | purch_yr != mode_yr_rdp | rdp_all==0 | trans_num!=1;
bys cluster_rdp: egen maxN = max(N);
gen NN = mo_date if N==maxN;
bys cluster_rdp: egen con_mo_rdp  = max(NN);
replace con_mo_rdp =. if maxN == -99;
drop N maxN NN;

* construction mode month for placebo;
set seed 1; /* set random month for placebo */
g random_month = ceil(12 * uniform()) ;
bys cluster_placebo: replace random_month = . if _n!=1;
bys cluster_placebo: egen mo_placebo = max(random_month);
g con_mo_placebo = ym(mode_yr_placebo,mo_placebo);

*******************;
gen mo2con_rdp  = mo_date - con_mo_rdp;
gen mo2con_placebo  = mo_date - con_mo_placebo;
format day_date %td;
format mo_date %tm;
format hy_date %th;

* joined to either placebo or rdp;
gen placebo = (distance_placebo < distance_rdp);
gen distance_joined = cond(placebo==1, distance_placebo, distance_rdp);
gen cluster_joined  = cond(placebo==1, cluster_placebo, cluster_rdp);
gen mo2con_joined   = cond(placebo==1, mo2con_placebo, mo2con_rdp);

* gen required vars;
gen lprice = log(purch_price);
gen erf_size2 = erf_size^2;
gen erf_size3 = erf_size^3;

* save data;
save "gradplot_admin.dta", replace;


* KEY : EXPORT THE RELEVANT CLUSTERS AND CONSTRUCTION DATES to sql tables ;
use "gradplot_admin.dta", clear;

cap program drop gentable;
program define gentable;
  odbc exec("DROP TABLE IF EXISTS `1';"), dsn("gauteng");
  odbc insert, table("`1'") dsn("gauteng") create;
  odbc exec("CREATE INDEX `1'_conacct_ind ON `1' (`1');"), dsn("gauteng");
end;

preserve;
  keep con_mo_rdp cluster_rdp;
  drop if con_mo_rdp==.;
  duplicates drop cluster_rdp, force;
  gentable cluster_rdp;
restore;

preserve;
  keep con_mo_placebo cluster_placebo;
  drop if con_mo_placebo==.;
  duplicates drop cluster_placebo, force;
  gentable cluster_placebo;
restore;

* exit stata;
*exit, STATA clear; 
