clear
est clear

set more off
set scheme s1mono


global prep_data = 0




if $prep_data == 1 {

#delimit;


global transaction_subset = 0;


if $transaction_subset == 1 {;

local qry = "
  SELECT  A.* FROM transactions AS A 
";

odbc query "gauteng";
odbc load, exec("`qry'") clear;

bys seller_name: g s_N=_N;

destring purch_price purch_yr, replace force;
keep if s_N<30 &  purch_price > 250 & purch_price<800000 & purch_yr > 2000 ;

keep property_id;
duplicates drop property_id, force;

odbc exec("DROP TABLE IF EXISTS transactions_clean;"), dsn("gauteng");
odbc insert, table("transactions_clean") create;
odbc exec("CREATE INDEX transactions_clean_ind ON transactions_clean (property_id);"), dsn("gauteng");


};


local qry = "

  SELECT LNB.* ,

        BA.cluster_area, 
        BA.cluster_b1_area, BA.cluster_b2_area, 
        BA.cluster_b3_area, BA.cluster_b4_area,
        BA.cluster_b5_area, BA.cluster_b6_area,
        BA.cluster_b7_area, BA.cluster_b8_area

  FROM 

  landplots_near_buffer_area_int_${dist_break_reg1}_${dist_break_reg2} AS LNB 

  LEFT JOIN buffer_area_${dist_break_reg1}_${dist_break_reg2}_landplots_near AS BA ON BA.plot_id = LNB.plot_id

";

* set cd;
cd ../..;
if $LOCAL==1{;cd ..;};
cd Generated/GAUTENG;


* load data; 
odbc query "gauteng";
odbc load, exec("`qry'") clear;


destring *, replace force ; 



foreach var of varlist cluster_int b1_int b2_int b3_int b4_int b5_int b6_int b7_int b8_int  {;
forvalues r=0/1 {;

if `r'==1 {;
    local name "rdp";
};
else  {;
    local name "placebo";
};

g `var'_`name'=`var' if rdp==`r';
gegen `var'_tot_`name'  = sum(`var'_`name'), by(plot_id);
gegen `var'_`name'_max  = max(`var'_`name'), by(plot_id);

g `var'_`name'_id_max = cluster if `var'_`name'_max == `var'_`name' & `var'_`name'!=.;
gegen `var'_`name'_id = max(`var'_`name'_id_max), by(plot_id);

drop `var'_`name' `var'_`name'_id_max `var'_`name'_max ;

};
};



keep plot_id *_id *_tot_* *_area ;
duplicates drop plot_id , force;


save "temp_prices_overlap.dta", replace;


local qry = "SELECT R.cluster, R.con_mo_rdp FROM rdp_cluster AS R";  
odbc query "gauteng";
odbc load, exec("`qry'") clear;
save "temp_rdp_date.dta", replace;



local qry = "SELECT RA.cluster, RA.start_yr FROM gcro_full_temp_year AS RA ";  
odbc query "gauteng";
odbc load, exec("`qry'") clear;
save "temp_proj_date.dta", replace;



local qry = "
  SELECT 

         A.munic_name, A.mun_code, A.purch_yr, A.purch_mo, A.purch_day,
         A.purch_price, A.trans_id, A.property_id, A.seller_name,

         B.erf_size, B.latitude, B.longitude, B.bblu_pre, LN.plot_id, G.grid_id,

        SP.sp_1

  FROM transactions AS A
  JOIN erven AS B ON A.property_id = B.property_id
  JOIN landplots_near AS LN ON LN.property_id = A.property_id

  LEFT JOIN erven_s2001 AS SP ON SP.property_id = A.property_id

  LEFT JOIN grid_to_landplots_near_100_4000 AS G ON G.plot_id = LN.plot_id

  ";


* load data; 
odbc query "gauteng";
odbc load, exec("`qry'") clear;

#delimit cr;

destring purch_yr purch_mo purch_day, replace force
keep if purch_yr>=2001


merge m:1 plot_id using "temp_prices_overlap.dta"
drop if _merge==2
drop _merge

keep if cluster_int_tot_rdp==0 & cluster_int_tot_placebo==0

g cluster_joined = .
g rdp=.
forvalues r=1/8 {
  replace cluster_joined = b`r'_int_placebo_id if (b`r'_int_tot_placebo >  b`r'_int_tot_rdp  ) & cluster_joined==.
  replace rdp=0                                if (b`r'_int_tot_placebo >  b`r'_int_tot_rdp  ) & rdp==.
  replace cluster_joined = b`r'_int_rdp_id     if (b`r'_int_tot_placebo <  b`r'_int_tot_rdp  ) & cluster_joined==.
  replace rdp=1                                if (b`r'_int_tot_placebo <  b`r'_int_tot_rdp  ) & rdp==.
}

ren cluster_joined cluster
  merge m:1 cluster using "temp_rdp_date.dta"
    drop if _merge==2
    drop _merge
  merge m:1 cluster using "temp_proj_date.dta"
    drop if _merge==2
    drop _merge
ren cluster cluster_joined


drop if con_mo_rdp<500

* make placebo dates! 

g rdp_date = dofm(con_mo_rdp)
g mode_yr_rdp = year(rdp_date)

cap drop c_n 
bys cluster_joined: g c_n=_n 
sum mode_yr_rdp if mode_yr_rdp!=. & c_n==1 
scalar define my = "`=round(r(mean),1)'" 
sum start_yr if mode_yr_rdp!=. & c_n==1 
scalar define sy = "`=round(r(mean),1)'" 
scalar define yr_gap = `=my' - `=sy' 


g mode_yr_placebo = start_yr + `=yr_gap' if rdp==0

* create date variables
gen abs_yrdist_rdp = abs(purch_yr - mode_yr_rdp)
gen abs_yrdist_placebo = abs(purch_yr - mode_yr_placebo)
gen day_date = mdy(purch_mo,purch_day,purch_yr)
gen mo_date  = ym(purch_yr,purch_mo)
gen hy_date  = hofd(dofm(mo_date))


* construction mode month for placebo;
set seed 1
g random_month = ceil(12 * uniform()) 
bys cluster_joined: replace random_month = . if _n!=1
bys cluster_joined: egen mo_placebo = max(random_month)
g con_mo_placebo = ym(mode_yr_placebo,mo_placebo)
drop random_month mo_placebo

sum con_mo_rdp, detail 
replace con_mo_placebo = . if con_mo_placebo<`=r(min)' | con_mo_placebo>`=r(max)' 
replace mode_yr_placebo = . if con_mo_placebo<`=r(min)' | con_mo_placebo>`=r(max)' 


*******************;
gen mo2con_rdp  = mo_date - con_mo_rdp
gen mo2con_placebo  = mo_date - con_mo_placebo

format day_date %td
format mo_date %tm
format hy_date %th

* * joined to either placebo or rdp;
* gen distance_joined = cond(placebo==1, distance_placebo, distance_rdp);
* gen cluster_joined  = cond(placebo==1, cluster_placebo, cluster_rdp);
* gen mo2con_joined   = cond(placebo==1, mo2con_placebo, mo2con_rdp);

* gen required vars

keep if purch_price > 250 & purch_price<800000

gen lprice = log(purch_price)
gen erf_size2 = erf_size^2
gen erf_size3 = erf_size^3

      
* save data;

save "gradplot_admin${V}_overlap.dta", replace

}



if $prep_data == 0 {
  cd ../..
  if $LOCAL==1{
    cd ..
  }
  cd Generated/GAUTENG
}


use "gradplot_admin${V}_overlap.dta", clear


preserve
  g post = purch_yr>2006

  g o = 1
  gegen P = mean(purch_price), by(grid_id post)
  gegen B = sum(o), by(grid_id post)



  g purch_alt = purch_price if purch_yr<=2004 | purch_yr>=2009
  g o_alt = o if purch_yr<=2004 | purch_yr>=2009

  gegen P_alt = mean(purch_alt), by(grid_id post)
  gegen B_alt = sum(o_alt), by(grid_id post)
  keep P P_alt B B_alt grid_id post
  duplicates drop grid_id post, force

  save "temp/grid_price.dta", replace
restore

* drop if mo2con_rdp==. & mo2con_placebo==.

* g post = ( mo2con_rdp>0 & mo2con_rdp<. & rdp==1 ) | ( mo2con_placebo>0 & mo2con_placebo<. & rdp==0 )





/*
preserve ;
  gegen P = mean(purch_price), by(grid_id);
  keep grid_id P;
  drop if P==.;
  duplicates drop grid_id, force;
  save "temp/grid_price.dta", replace;

restore;





