
clear
est clear
set matsize 10000

do reg_gen.do
* do reg_gen_price.do

do reg_gen_price_new.do


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


*******************;
*  PLOT GRADIENTS *;
*******************;

* data subset for regs (1);

* what to run?;

global ddd_regs_d = 0;
global ddd_regs_t = 0;
global ddd_table  = 0;

global ddd_regs_t_alt  = 0; /* these aren't working right now */
global ddd_regs_t2_alt = 0;
global countour = 0;

global graph_plotmeans = 0;

global group_size = 4 ;


* load data; 

cd ../..;
cd $output ;


use "temp_censushh_agg_buffer_${dist_break_reg1}_${dist_break_reg2}${V}.dta", clear;
keep if year==2001;


keep sp_1 inc;

ren inc inc1;
egen inc= mean(inc1), by(sp_1);
drop inc1;
duplicates drop sp_1, force ;

cd ../../../..;
cd Generated/GAUTENG;

save "temp_2001_inc.dta", replace;


use "gradplot_admin${V}.dta", clear;

merge m:1 sp_1 using "temp_2001_inc.dta";
drop if _merge==2;
drop _merge;

cd ../..;
cd $output ;


* go to working dir;


* transaction count per seller;
bys seller_name: g s_N=_N;

*extra time-controls;
gen day_date_sq = day_date^2;
gen day_date_cu = day_date^3;

* spatial controls;
gen latbin = round(latitude,$round);
gen lonbin = round(longitude,$round);
egen latlongroup = group(latbin lonbin);

* cluster var for FE (arbitrary for obs contributing to 2 clusters?);
g cluster_reg = cluster_rdp;
replace cluster_reg = cluster_placebo if cluster_reg==. & cluster_placebo!=.;

keep if distance_rdp<$dist_max_reg | distance_placebo<$dist_max_reg ;

** ASSIGN TO CLOSEST PROJECTS  !! ; 
replace distance_placebo = . if distance_placebo>distance_rdp   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 ;
replace distance_rdp     = . if distance_rdp>=distance_placebo   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 ;

replace mo2con_placebo = . if distance_placebo==.  | distance_rdp<0;
replace mo2con_rdp = . if distance_rdp==. | distance_placebo<0;


g proj        = (distance_rdp<0 | distance_placebo<0) ;
g spill1      = proj==0 &  ( distance_rdp<=$dist_break_reg2 | 
                            distance_placebo<=$dist_break_reg2 );

g con = distance_rdp<=distance_placebo ;

cap drop cluster_joined;
g cluster_joined = cluster_rdp if con==1 ; 
replace cluster_joined = cluster_placebo if con==0 ; 

g proj_cluster = proj>.5 & proj<.;
g spill1_cluster = proj_cluster==0 & spill1>.5 & spill1<.;

egen cj1 = group(cluster_joined proj_cluster spill1_cluster) ;
drop cluster_joined ;
ren cj1 cluster_joined ;

g con_date = mo2con_rdp if con==1 ;
replace con_date = mo2con_placebo if con==0 ;

g post = (mo2con_rdp>0 & mo2con_rdp<. & con==1) |  (mo2con_placebo>0 & mo2con_placebo<. & con==0) ;

g t1 = (type_rdp==1 & con==1) | (type_placebo==1 & con==0);
g t2 = (type_rdp==2 & con==1) | (type_placebo==2 & con==0);
g t3 = (type_rdp==. & con==1) | (type_placebo==. & con==0);

* egen inc_q = cut(inc), group(2) ;
* g low_inc  = inc_q==0;
* g high_inc = inc_q==1;

* sum inc, detail ; 
* g low_inc  = inc<=`=r(p75)' ;
* g high_inc = inc>=`=r(p75)' ;

keep if s_N<30 &  purch_price > 250 & purch_price<800000 & purch_yr > 2000 ;

keep if distance_rdp>=0 & distance_placebo>=0 ; 


egen inc_q = cut(inc), group($group_size) ;
replace inc_q=inc_q+1 ;



rgen ${no_post} ;
rgen_type ;
* rgen_inc_het ;
rgen_q_het ;

lab_var ;
lab_var_type ;
* lab_var_inc ;
lab_var_q ;

gen_LL_price ; 

save "price_regs${V}.dta", replace;


use "price_regs${V}.dta", clear ;



global outcomes="lprice";





* egen clyrgroup = group(purch_yr cluster_joined);
* egen latlonyr = group(purch_yr latlongroup);

* global fecount = 2 ;

* global rl1 = "Year-Month FE";
* global rl2 = "Plot Size (up to cubic polynomial)";
* *global rl3 = "Constructed Diff-in-Diff";

* * mat define F = (0,1,0,1
* *                \0,1,0,1
* *                \0,0,1,1);

* mat define F = (0,1
*                \0,1);


* global reg_1 = " areg lprice $regressors , a(LL) cl(cluster_joined)"   ;
* global reg_2 = " areg lprice $regressors i.purch_yr#i.purch_mo erf_size*, a(LL) cl(cluster_joined)"   ;
* * global reg_3 = " areg lprice $regressors if  con==1, a(LL) cl(cluster_joined)"   ;
* * global reg_4 = " areg lprice $regressors i.purch_yr#i.purch_mo erf_size* if  con==1, a(LL) cl(cluster_joined)"   ;

* price_regs_o price_temp_Tester_3d ;


* global reg_1 = " areg lprice $r_q_het , a(LL) cl(cluster_joined)"   ;
* global reg_2 = " areg lprice $r_q_het i.purch_yr#i.purch_mo erf_size* , a(LL) cl(cluster_joined)"   ;
* * global reg_3 = " areg lprice $r_q_het if  con==1 , a(LL) cl(cluster_joined)"   ;
* * global reg_4 = " areg lprice $r_q_het i.purch_yr#i.purch_mo erf_size* if  con==1 , a(LL) cl(cluster_joined)"   ;

* price_regs_q price_temp_Tester_3d_q     ;
     


* * global reg_1 = " areg lprice $regressors , a(LL) cl(cluster_joined)"   ;
* * global reg_2 = " areg lprice $regressors i.purch_yr#i.purch_mo erf_size*, a(LL) cl(cluster_joined)"   ;
* global reg_1 = " areg lprice $regressors if  con==1, a(LL) cl(cluster_joined)"   ;
* global reg_2 = " areg lprice $regressors i.purch_yr#i.purch_mo erf_size* if  con==1, a(LL) cl(cluster_joined)"   ;

* price_regs_o price_temp_Tester_2d ;


* * global reg_1 = " areg lprice $r_q_het , a(LL) cl(cluster_joined)"   ;
* * global reg_2 = " areg lprice $r_q_het i.purch_yr#i.purch_mo erf_size* , a(LL) cl(cluster_joined)"   ;
* global reg_1 = " areg lprice $r_q_het if  con==1 , a(LL) cl(cluster_joined)"   ;
* global reg_2 = " areg lprice $r_q_het i.purch_yr#i.purch_mo erf_size* if  con==1 , a(LL) cl(cluster_joined)"   ;

* price_regs_q price_temp_Tester_2d_q     ;
     
* est clear ;


    

global a_pre = "";
global a_ll = "";
if "${k}"!="none" {;
global a_pre = "a";
global a_ll = "a(LL)";
};


#delimit cr;




global dist_bins = 250
global key_fe = "LL"
global month_window = 48


*global D_shift = 100
*   (1) name                  (2) type    (3) round var         (4) time thresh   (5) post yr    (6) DDD    (7) controls  (8) fe  (9) inside  (10) dshift

pf "price_dist_3d_ctrl_q"       "dist"          $dist_bins              ""                   0              1         1       "$key_fe"      0    100

pf "price_time_3d_ctrl_q"       "time"             24               $month_window             0             1         1      "$key_fe"        0  6


*   (1) name                  (2) type    (3) round var   (4) time thresh   (5) post yr    (6) DDD    (7) controls  (8) fe  (9) inside   (10) dshift

* pf "price_dist_3d_no_ctrl"      "dist"       $dist_bins             ""              0              1         0      "$key_fe"        0 1000
* pf "price_time_3d_no_ctrl_q"    "time"       24               $month_window     0           1         0      "$key_fe"        0  6



/*

pf "price_time_3d_no_ctrl_q"   "time"          24               $month_window               0             1         0     "$key_fe"     0  6
pf "price_dist_3d_no_ctrl_q"       "dist"       $dist_bins              ""              0              1         0       "$key_fe"     0      100



pf "price_dist_3d_ctrl_q"          "dist"          $dist_bins              ""              0              1         1       "$key_fe"      0    100

pf "price_dist_2d_no_ctrl_q"       "dist"         $dist_bins               ""              0              0         0         "$key_fe"       0    100
pf "price_dist_2d_ctrl_q"          "dist"          $dist_bins             ""              0              0         1          "$key_fe"      0    100

* pf "price_dist_3d_no_ctrl_pfe"   "dist"        $dist_bins             ""              0              1         0         property_id           0
* pf "price_dist_3d_ctrl_pfe"      "dist"       $dist_bins             ""              0              1         1          property_id           0
* pf "price_dist_2d_no_ctrl_pfe"   "dist"       $dist_bins             ""              0              0         0           property_id           0
* pf "price_dist_2d_ctrl_pfe"      "dist"        $dist_bins              ""              0              0         1        property_id           0

* pf "price_dist_3d_no_ctrl_2005"   "dist"    $dist_bins               ""           2005              1         0          "$key_fe"            0
* pf "price_dist_3d_no_ctrl_2006"   "dist"    $dist_bins               ""           2006              1         0        "$key_fe"           0
* pf "price_dist_3d_no_ctrl_2007"   "dist"   $dist_bins               ""           2007              1         0         "$key_fe"        0
* pf "price_dist_3d_no_ctrl_2008"   "dist"    $dist_bins              ""           2008              1         0         "$key_fe"           0
* pf "price_dist_3d_no_ctrl_2009"   "dist"     $dist_bins              ""           2009              1         0         "$key_fe"          0

pf "price_time_3d_no_ctrl_q"   "time"          12               $month_window               0             1         0     "$key_fe"     0  6
pf "price_time_3d_ctrl_q"   "time"             12               $month_window               0             1         1    "$key_fe"      0  6

pf "price_time_2d_no_ctrl_q"   "time"          12               $month_window              0             0         0         "$key_fe"   0  6
pf "price_time_2d_ctrl_q"      "time"          12               $month_window               0             0         1        "$key_fe"   0  6
  
  
* pf "price_time_3d_no_ctrl_pfe"   "time"          12                36               0             1         0       property_id 0
* pf "price_time_3d_ctrl_pfe"      "time"          12                36               0             1         1        property_id  0
* pf "price_time_2d_no_ctrl_pfe"   "time"          12                36               0             0         0        property_id   0
* pf "price_time_2d_ctrl_pfe"      "time"          12                36               0             0         1         property_id   0
  
  


