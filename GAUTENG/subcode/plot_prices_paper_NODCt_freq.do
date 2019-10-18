
clear
est clear

do reg_gen.do

set more off
set scheme s1mono

#delimit;
grstyle init;
grstyle set imesh, horizontal;

* RUN LOCALLY?;
global LOCAL = 1;
if $LOCAL==1{;
  cd ..;
};

***************************************;
*  PROGRAMS TO OMIT VARS FROM GLOBAL  *;
***************************************;
cap program drop omit;
program define omit;

  local original ${`1'};
  local temp1 `0';
  local temp2 `1';
  local except: list temp1 - temp2;
  local modified;
  foreach e of local except{;
   local modified = " `modified' o.`e'"; 
  };
  local new: list original - except;
  local new " `modified' `new'";
  global `1' `new';

end;

cap program drop takefromglobal;
program define takefromglobal;

  local original ${`1'};
  local temp1 `0';
  local temp2 `1';
  local except: list temp1 - temp2;
  local new: list original - except;
  global `1' `new';

end;

*******************;
*  PLOT GRADIENTS *;
*******************;

* data subset for regs (1);

* what to run?;

global ddd_regs_d = 1;
global ddd_regs_t = 0;
global ddd_table  = 0;

global ddd_regs_t_alt  = 0; /* these aren't working right now */
global ddd_regs_t2_alt = 0;
global countour = 0;


global post_control_price = "";

* load data; 
cd ../..;
cd Generated/GAUTENG;



use "gradplot_admin${V}.dta", clear;

merge m:1 sp_1 using "temp_2001_inc.dta";
drop if _merge==2;
drop _merge;

* go to working dir;
cd ../..;
cd $output ;

egen inc_q = cut(inc), group(2);


* transaction count per seller;
bys seller_name: g s_N=_N;

keep if s_N<30 &  purch_price > 2000 & purch_price<800000 & purch_yr > 2000 ;

g latr= round(latitude,.001) ;
g lonr= round(longitude,.001) ;
egen cell = group( latr lonr ) ;


* wow this is a pain... ;

global static_vars = "erf_size erf_size2 erf_size3 sp_1 inc_q cluster_rdp cluster_placebo distance_rdp distance_placebo latitude longitude cbd_dist type_rdp type_placebo con_mo_placebo con_mo_rdp " ;

keep cell mo_date $static_vars ;


bys cell mo_date: g sales=_N ;
bys cell mo_date: keep if _n==1 ;

tsset cell mo_date   ;
tsfill, full ;

foreach var of varlist $static_vars { ;
  egen m_`var'=min(`var'), by(cell) ;
  replace `var' = m_`var' ;
  drop m_`var' ;
} ;

replace sales=0 if sales==. ;

g mo2con_rdp = con_mo_rdp - mo_date ;
g mo2con_placebo = con_mo_placebo - mo_date ;


* spatial controls;
gen latbin = round(latitude,$round);
gen lonbin = round(longitude,$round);
egen latlongroup = group(latbin lonbin);

* cluster var for FE (arbitrary for obs contributing to 2 clusters?);
g cluster_reg = cluster_rdp;
replace cluster_reg = cluster_placebo if cluster_reg==. & cluster_placebo!=.;

g het = 1 if cbd_dist<${het};
replace het = 0 if cbd_dist>=${het} & cbd_dist<.;



keep if distance_rdp<$dist_max_reg | distance_placebo<$dist_max_reg ;

** ASSIGN TO CLOSEST PROJECTS  !! ; 
replace distance_placebo = . if distance_placebo>distance_rdp   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 ;
replace distance_rdp     = . if distance_rdp>=distance_placebo   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 ;

replace mo2con_placebo = . if distance_placebo==.  | distance_rdp<0;
replace mo2con_rdp = . if distance_rdp==. | distance_placebo<0;


g proj        = (distance_rdp<0 | distance_placebo<0) ;
g spill1      = proj==0 &  ( distance_rdp<=$dist_break_reg1 | 
                            distance_placebo<=$dist_break_reg1 );
g spill2      = proj==0 &  ( (distance_rdp>$dist_break_reg1 & distance_rdp<=$dist_break_reg2) 
                              | (distance_placebo>$dist_break_reg1 & distance_placebo<=$dist_break_reg2) );
g con = distance_rdp<=distance_placebo ;

cap drop cluster_joined;
g cluster_joined = cluster_rdp if con==1 ; 
replace cluster_joined = cluster_placebo if con==0 ; 

g proj_cluster = proj>.5 & proj<.;
g spill1_cluster = proj_cluster==0 & spill1>.5 & spill1<.;

if $many_spill == 1 { ;
g spill2_cluster = proj_cluster==0 & spill1_cluster==0 & spill2>.5 & spill2<.;
egen cj1 = group(cluster_joined proj_cluster spill1_cluster spill2_cluster) ;
drop cluster_joined ;
ren cj1 cluster_joined ;
};
if $many_spill == 0 {;
*replace spill1_cluster = 1 if spill2_cluster==1;
egen cj1 = group(cluster_joined proj_cluster spill1_cluster) ;
drop cluster_joined ;
ren cj1 cluster_joined ;
};


g post = (mo2con_rdp>0 & mo2con_rdp<.) |  (mo2con_placebo>0 & mo2con_placebo<.) ;

g t1 = (type_rdp==1 & con==1) | (type_placebo==1 & con==0);
g t2 = (type_rdp==2 & con==1) | (type_placebo==2 & con==0);
g t3 = (type_rdp==. & con==1) | (type_placebo==. & con==0);


* g Xs = round(latitude,${k}00);
* g Ys = round(longitude,${k}00);

* egen LL = group(Xs Ys purch_yr);



rgen ${no_post} ;
rgen_type ;
lab_var ;
lab_var_type ;


gen_LL_price ; 


*****************************************************************;
*************   DDD REGRESSION JOINED PLACEBO-RDP   *************;
*****************************************************************;




global outcomes="sales";

* egen clyrgroup = group(purch_yr cluster_joined);
* egen latlonyr = group(purch_yr latlongroup);


* global fecount = 3 ;
global fecount = 1 ;

global rl1 = "Lot Size/Year-Month";

mat define F = (0,1);


global a_pre = "";
global a_ll = "";
if "${k}"!="none" {;
global a_pre = "a";
global a_ll = "a(LL)";
};

g sales1 = sales*12 ;

global reg_1 = " ${a_pre}reg  sales1 $regressors  , cl(cluster_joined) ${a_ll}" ;
global reg_2 = " ${a_pre}reg  sales1 $regressors  i.mo_date  erf_size*, cl(cluster_joined) ${a_ll}" ;

price_regs s_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2} ;

preserve;
keep if inc_q==0;
price_regs s_k${k}_t0_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2} ;
restore;


preserve;
keep if inc_q==1;
price_regs s_k${k}_t1_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2} ;
restore;




* global reg_1 = " ${a_pre}reg  sales  $regressors2  , cl(cluster_joined) ${a_ll}" ;
* global reg_2 = " ${a_pre}reg  sales  $regressors2 i.mo_date  erf_size*, cl(cluster_joined) ${a_ll}" ;

* price_regs_type s_t_${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2} ;





* global reg_t = " areg lprice $tregressors i.purch_yr#i.purch_mo erf_size*  if T_id==1 & D_id==1, a(LL) cl(cluster_joined)  "; 

* time_reg price_to_event_${k}  ;



*** OLD SPECIFICATION *** ;

* global rl2 = "Cluster {\tim} Year FE";
* global rl3 = "Lat.-Long. {\tim} Year FE";

* global rl1 = "Cluster FE";
* global rl2 = "Cluster {\tim} Year FE";
* global rl3 = "Lat.-Long. {\tim} Year FE";


* mat define F = (0,1,0,0
*                \0,0,1,0
*                \0,0,0,1);

* global reg_1 = " reg  lprice $regressors i.purch_yr#i.purch_mo erf_size*, cl(cluster_joined)" ;
* global reg_2 = " areg lprice $regressors i.purch_yr#i.purch_mo erf_size*, a(cluster_joined) cl(cluster_joined)" ;
* global reg_3 = " areg lprice $regressors i.purch_mo erf_size*, a(clyrgroup) cl(cluster_joined)";
* global reg_4 = " areg lprice $regressors i.purch_mo erf_size*, a(latlonyr) cl(latlongroup) ";

* price_regs price_temp_Tester ;



* global reg_1 = " reg  lprice $regressors2 i.purch_yr#i.purch_mo erf_size*, cl(cluster_joined) a(LL)" ;
* global reg_2 = " areg lprice $regressors2 i.purch_yr#i.purch_mo erf_size*, a(cluster_joined) cl(cluster_joined)" ;
* global reg_3 = " areg lprice $regressors2 i.purch_mo erf_size*, a(clyrgroup) cl(cluster_joined)";
* global reg_4 = " areg lprice $regressors2 i.purch_mo erf_size*, a(latlonyr) cl(latlongroup) ";

* price_regs_type price_type_Tester ;

* global reg_t = " areg lprice $tregressors i.purch_yr#i.purch_mo erf_size*  if T_id==1 & D_id==1, a(latlonyr) cl(latlongroup)  "; 

* time_reg price_to_event ;

