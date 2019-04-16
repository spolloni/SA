clear
est clear

set more off
set scheme s1mono

#delimit;


local qry = "
  SELECT 

         A.munic_name, A.mun_code, A.purch_yr, A.purch_mo, A.purch_day,
         A.purch_price, A.trans_id, A.property_id, A.seller_name,

         B.erf_size, B.latitude, B.longitude, 

         C.rdp_property,
 
         D.distance AS distance_rdp,     D.target_id AS cluster_rdp,     D.count AS count_rdp,  D.mode_yr_rdp, D.con_mo_rdp,
         E.cluster AS cluster_rdp_int,

         F.distance AS distance_placebo, F.target_id AS cluster_placebo, F.count AS count_placebo,
         G.cluster AS cluster_placebo_int,

         CB.cbd_dist, 

         GY.start_yr, GY.end_yr, GY.score

  FROM transactions AS A
  JOIN erven AS B ON A.property_id = B.property_id

  LEFT JOIN (SELECT 1 AS rdp_property, property_id FROM rdp_property)  AS C ON B.property_id = C.property_id


  LEFT JOIN 
        (SELECT D.input_id, D.distance, D.target_id, COUNT(D.input_id) AS count, R.mode_yr_rdp, R.con_mo_rdp
          FROM distance_erven_gcro${flink} AS D
          JOIN rdp_cluster AS R ON R.cluster = D.target_id
          WHERE D.distance<=4000
          GROUP BY D.input_id HAVING COUNT(D.input_id)<=50 AND D.distance == MIN(D.distance)
        ) AS D ON D.input_id=B.property_id

  LEFT JOIN (SELECT IT.* FROM  int_gcro${flink}_erven AS IT JOIN rdp_cluster AS PC ON PC.cluster = IT.cluster ) 
      AS E ON E.property_id = B.property_id

  LEFT JOIN 
        (SELECT D.input_id, D.distance, D.target_id, COUNT(D.input_id) AS count
          FROM distance_erven_gcro${flink} AS D
          JOIN placebo_cluster AS R ON R.cluster = D.target_id
          WHERE D.distance<=4000
          GROUP BY D.input_id HAVING COUNT(D.input_id)<=50 AND D.distance == MIN(D.distance)
        ) AS F ON F.input_id=B.property_id

  LEFT JOIN (SELECT IT.* FROM  int_gcro${flink}_erven AS IT JOIN placebo_cluster AS PC ON PC.cluster = IT.cluster ) 
      AS G ON G.property_id = B.property_id

  LEFT JOIN  gcro${flink} AS GC ON D.target_id = GC.cluster

  LEFT JOIN  cbd_dist${flink} AS CB ON CB.cluster = GC.cluster

  LEFT JOIN gcro${flink}_temp_year AS GY ON GY.cluster = GC.cluster


  ";





*   goes after 4000 and before GROUP for F:    AND gcro.placebo_yr IS NOT NULL;

* set cd;
cd ../..;
if $LOCAL==1{;cd ..;};
cd Generated/GAUTENG;


* load data; 
odbc query "gauteng";
odbc load, exec("`qry'") clear;


destring rdp_property, replace force       ;
replace rdp_property=0 if rdp_property==.  ;

* set up frac vars;
destring purch_yr purch_mo purch_day mun_code, replace       ;
gen trans_num = substr(trans_id,strpos(trans_id, "_")+1,.)   ;
destring trans_num, replace                                  ;

* get rid of missing distances;
drop if distance_placebo==. & distance_rdp==.                 ;

* get rid of missing prices;
drop if purch_price==.     ;

* make distances negative if within projects ;
replace distance_placebo = distance_placebo*-1 if cluster_placebo==cluster_placebo_int & cluster_placebo!=.   ;
replace distance_rdp = distance_rdp*-1 if cluster_rdp==cluster_rdp_int & cluster_rdp!=.   ;

* make placebo dates! ;
cap drop c_n ;
bys cluster_rdp: g c_n=_n ;
sum mode_yr_rdp if mode_yr_rdp!=. & c_n==1 ;
scalar define my = "`=round(r(mean),1)'" ;
sum start_yr if mode_yr_rdp!=. & c_n==1 ;
scalar define sy = "`=round(r(mean),1)'" ;
scalar define yr_gap = `=my' - `=sy' ;
g mode_yr_placebo = start_yr + `=yr_gap' if cluster_placebo!=. ;

* create date variables;
gen abs_yrdist_rdp = abs(purch_yr - mode_yr_rdp); 
gen abs_yrdist_placebo = abs(purch_yr - mode_yr_placebo); 
gen day_date = mdy(purch_mo,purch_day,purch_yr);
gen mo_date  = ym(purch_yr,purch_mo);
gen hy_date  = hofd(dofm(mo_date)); // half-years;


* construction mode month for placebo;
set seed 1; /* set random month for placebo */
g random_month = ceil(12 * uniform()) ;
bys cluster_placebo: replace random_month = . if _n!=1;
bys cluster_placebo: egen mo_placebo = max(random_month);
g con_mo_placebo = ym(mode_yr_placebo,mo_placebo);
drop random_month ;

sum con_mo_rdp, detail ;
replace con_mo_placebo = . if con_mo_placebo<`=r(min)' | con_mo_placebo>`=r(max)' ;
replace mode_yr_placebo = . if con_mo_placebo<`=r(min)' | con_mo_placebo>`=r(max)' ;


*******************;
gen mo2con_rdp  = mo_date - con_mo_rdp;
gen mo2con_placebo  = mo_date - con_mo_placebo;
format day_date %td;
format mo_date %tm;
format hy_date %th;

* joined to either placebo or rdp;
gen placebo = (distance_placebo < distance_rdp & distance_placebo<.);
gen distance_joined = cond(placebo==1, distance_placebo, distance_rdp);
gen cluster_joined  = cond(placebo==1, cluster_placebo, cluster_rdp);
gen mo2con_joined   = cond(placebo==1, mo2con_placebo, mo2con_rdp);

* gen required vars;
gen lprice = log(purch_price);
gen erf_size2 = erf_size^2;
gen erf_size3 = erf_size^3;

      
* save data;
save "gradplot_admin${V}.dta", replace;


