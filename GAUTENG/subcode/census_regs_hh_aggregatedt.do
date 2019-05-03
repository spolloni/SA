clear 

est clear
set more off
set scheme s1mono

do  reg_gen.do
do  reg_gen_dd.do

#delimit;



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

****************** ;
*  CENSUS REGS   * ;
****************** ;

* DOFILE SECTIONS ;


* WEIGHTS?? ;
global ww = ""; /// alternatively [aweight=hh_pop]; 

if $LOCAL==1 {;
	cd ..;
};

cd ../..;
cd $output;

*****************************************************************;
*****************************************************************;
*****************************************************************;




* go to working dir;

use "temp_censushh_agg_buffer_${dist_break_reg1}_${dist_break_reg2}${V}.dta", replace;






    ***** SUMMARY STATS REGS **** ;


mat SUM = J(9, 3,.);
keep if year ==2001;
g project_rdp     = (area_int_rdp     > $tresh_area & area_int_rdp    >=area_int_placebo);
g project_placebo = (area_int_placebo > $tresh_area & area_int_placebo> area_int_rdp);

* g project_rdp = (area_int_rdp > $tresh_area & distance_rdp<= $tresh_dist);
* g project_placebo = (area_int_placebo > $tresh_area & distance_placebo<= $tresh_dist);

* toilet_flush means;
sum toilet_flush if project_rdp ==1 $ww;
matrix SUM[1,1] = round(r(mean),.01);
sum toilet_flush if project_placebo ==1 $ww;
matrix SUM[1,2] = round(r(mean),.01);
sum toilet_flush $ww; 
matrix SUM[1,3] = round(r(mean),.01);

* water_inside means;
sum water_inside if project_rdp ==1 $ww;
matrix SUM[2,1] = round(r(mean),.01);
sum water_inside if project_placebo ==1 $ww;
matrix SUM[2,2] = round(r(mean),.01);
sum water_inside $ww;
matrix SUM[2,3] = round(r(mean),.01);

* electric_cooking means;
sum electric_cooking if project_rdp ==1 $ww;
matrix SUM[3,1] = round(r(mean),.01);
sum electric_cooking if project_placebo ==1 $ww;
matrix SUM[3,2] = round(r(mean),.01);
sum electric_cooking $ww;
matrix SUM[3,3] = round(r(mean),.01);

* electric_heating means;
sum electric_heating if project_rdp ==1 $ww;
matrix SUM[4,1] = round(r(mean),.01);
sum electric_heating if project_placebo ==1 $ww;
matrix SUM[4,2] = round(r(mean),.01);
sum electric_heating $ww;
matrix SUM[4,3] = round(r(mean),.01);

* electric_lighting means;
sum electric_lighting if project_rdp ==1 $ww;
matrix SUM[5,1] = round(r(mean),.01);
sum electric_lighting if project_placebo ==1 $ww;
matrix SUM[5,2] = round(r(mean),.01);
sum electric_lighting $ww; 
matrix SUM[5,3] = round(r(mean),.01);

* tot_rooms means;
sum tot_rooms if project_rdp ==1 $ww;
matrix SUM[6,1] = round(r(mean),.01);
sum tot_rooms if project_placebo ==1 $ww;
matrix SUM[6,2] = round(r(mean),.01);
sum tot_rooms $ww;
matrix SUM[6,3] = round(r(mean),.01);

* hh_size means;
sum hh_size if project_rdp ==1 $ww;
matrix SUM[7,1] = round(r(mean),.01);
sum hh_size if project_placebo ==1 $ww;
matrix SUM[7,2] = round(r(mean),.01);
sum hh_size $ww;
matrix SUM[7,3] = round(r(mean),.01);

* area_int means;
g asum = area_int_rdp + area_int_placebo;
sum asum if project_rdp ==1 $ww;
matrix SUM[8,1] = round(r(mean),.01);
sum asum if project_placebo ==1 $ww;
matrix SUM[8,2] = round(r(mean),.01);
sum asum $ww;
matrix SUM[8,3] = round(r(mean),.01);




* Counts;
count if project_rdp ==1;
global cons: di %15.0fc r(N);
count if project_placebo ==1;
global uncons: di %15.0fc r(N);
count;
global all: di %15.0fc r(N);


preserve;
clear;
svmat SUM; 
tostring * , replace force format(%9.2f);
gen names = "";
order names, first;
replace names = "Flush Toilet" in 1;
replace names = "Piped Water in Home" in 2;
replace names = "Electricity for Cooking" in 3;
replace names = "Electricity for Heating" in 4;
replace names = "Electricity for Lighting" in 5;
replace names = "Number of Rooms" in 6;
replace names = "Household Size" in 7;
replace names = "\% Area Overlap with Projects" in 8;

replace names = "N" in 9;
replace SUM1 = "$cons" in 9;
replace SUM2 = "$uncons" in 9;
replace SUM3 = "$all" in 9;

replace SUM3 = SUM3 + " \\";

export delimited using "census_at_baseline_AGG${V}.tex", novar delimiter("&") replace;

restore;



    ***** DD REGS **** ;





use "temp_censushh_agg_buffer_${dist_break_reg1}_${dist_break_reg2}${V}.dta", replace;



keep if distance_rdp<$dist_max_reg | distance_placebo<$dist_max_reg ;

replace distance_placebo = . if distance_placebo>distance_rdp   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 ;
replace distance_rdp     = . if distance_rdp>=distance_placebo   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 ;

replace census_cluster_int_rdp=0 if census_cluster_int_rdp==. ;
replace census_cluster_int_placebo=0 if census_cluster_int_placebo==. ;

drop area_int_rdp area_int_placebo ;

g area_2 = area*area;
g area_3 = area*area_2;

global area_levels = 0 ;

global extra_controls = " y1996 area area_2 area_3 ";

g area_int_rdp  =  census_cluster_int_rdp ; 
g area_int_placebo = census_cluster_int_placebo ; 

g area_b1_rdp = (census_b1_int_rdp - census_cluster_int_rdp);
g area_b1_placebo = (census_b1_int_placebo - census_cluster_int_placebo);

g area_b2_rdp = (census_b2_int_rdp - census_b1_int_rdp);
g area_b2_placebo = (census_b2_int_placebo - census_b1_int_placebo);

if $area_levels == 0 {;
foreach var of varlist area_int_rdp area_int_placebo area_b1_rdp area_b1_placebo area_b2_rdp area_b2_placebo {;
replace `var' = `var'/area ;
};
};

if $area_levels == 1 {;
foreach var of varlist area area_2 area_int_rdp area_int_placebo area_b1_rdp area_b1_placebo area_b2_rdp area_b2_placebo {;
replace `var' = `var'/(1000*1000);
};
};


replace area_int_rdp =0 if area_int_rdp==.;
replace area_int_placebo =0 if area_int_placebo==.;


replace area_b1_rdp = 0 if area_b1_rdp == .;
replace area_b1_placebo = 0 if area_b1_placebo == .;


replace area_b2_rdp = 0 if area_b2_rdp == .;
replace area_b2_placebo = 0 if area_b2_placebo == .;


g con = 0;
replace con=1 if area_int_rdp>0 & area_int_rdp>area_int_placebo  &  area_int_rdp<. & area_int_placebo<.;
replace con=1 if distance_rdp<=distance_placebo & con==0 & distance_rdp<.;

g proj = area_int_rdp  if con==1 ;
replace proj = area_int_placebo if con==0 ;
replace proj = 0 if proj==.;

g spill1 = area_b1_rdp if con==1;
replace spill1 = area_b1_placebo if con==0;
replace spill1 = 0 if spill1==.;

g spill2 = area_b2_rdp if con==1;
replace spill2 = area_b2_placebo if con==0;
replace spill2 = 0 if spill2 ==. ;





* g area_b2_rdp = (census_b2_int_rdp - census_b1_int_rdp)/(cluster_b2_area_rdp-cluster_b1_area_rdp);
* g area_b2_placebo = (census_b2_int_placebo - census_b1_int_placebo)/(cluster_b2_area_placebo-cluster_b1_area_placebo);


* g area_b1_rdp = (census_b1_int_rdp - census_cluster_int_rdp)/census_area_rdp;
* g area_b1_placebo = (census_b1_int_placebo - census_cluster_int_placebo)/(census_b1_area_placebo-cluster_area_placebo);



* g proj = (area_int_rdp_alt>.01 & area_int_rdp_alt<.) | (area_int_placebo_alt>.01 & area_int_placebo_alt<.) ;
* g proj     = (area_int_rdp     > $tresh_area ) | (area_int_placebo > $tresh_area);

* g spill1      = proj==0 & ( distance_rdp<=$dist_break_reg1 | 
*                             distance_placebo<=$dist_break_reg1 );
* g spill2      = proj==0 & ( (distance_rdp>$dist_break_reg1 & distance_rdp<=$dist_break_reg2) 
*                               | (distance_placebo>$dist_break_reg1 & distance_placebo<=$dist_break_reg2) );

* browse area_int_rdp area_int_placebo distance_rdp distance_placebo census_area_placebo census_cluster_int_placebo census_b1_int_placebo census_b2_int_placebo census_area_rdp census_cluster_int_rdp census_b1_int_rdp census_b2_int_rdp cluster_area_placebo cluster_b1_area_placebo cluster_b2_area_placebo cluster_area_rdp cluster_b1_area_rdp cluster_b2_area_rdp
* browse area_int_rdp census_cluster_int_rdp;


g post = year==2011;

cap drop cluster_joined;
g cluster_joined = cluster_rdp if con==1 ; 
replace cluster_joined = cluster_placebo if con==0 ; 

if $many_spill == 1 { ;
egen cj1 = group(cluster_joined proj spill1 spill2) ;
drop cluster_joined ;
ren cj1 cluster_joined ;
};
if $many_spill == 0 {;
egen cj1 = group(cluster_joined proj spill1) ;
drop cluster_joined ;
ren cj1 cluster_joined ;
};


g t1 = (type_rdp==1 & con==1) | (type_placebo==1 & con==0);
g t2 = (type_rdp==2 & con==1) | (type_placebo==2 & con==0);
g t3 = (type_rdp==. & con==1) | (type_placebo==. & con==0);


gen_LL ;


rgen ${no_post} ;
rgen_type ;

g y1996= year==1996;
g formal_house = house + house_bkyd ;
g informal_house = shack_bkyd + shack_non_bkyd ;

* if $spatial == 0 {;

global outcomes "
  toilet_flush 
  water_inside 
  electric_cooking 
  electric_heating 
  electric_lighting 
  tot_rooms
  hh_size
  pop_density
  ";


regs ch_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2} ;

regs_type ch_t_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2} ;



global outcomes "
  formal_house
  informal_house
  owner
  ";

regs chouse_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}  ;

regs_type chouse_t_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}  ;



**** NOW DO DD *** ;

global outcomes "
  toilet_flush 
  water_inside 
  electric_cooking 
  electric_heating 
  electric_lighting 
  tot_rooms
  hh_size
  pop_density
  ";


 rgen_dd_full  ;
 rgen_dd_cc   ;

 regs_dd_full ch_dd_full_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}  ; 

regs_dd_cc ch_cc_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}  ;


global outcomes "
  formal_house
  informal_house
  owner
  ";

regs_dd_full chouse_dd_full_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}  ; 

regs_dd_cc chouse_cc_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}  ;




* foreach var of varlist house_dens  house_bkyd_dens  shack_non_bkyd_dens  shack_bkyd_dens  {;
* replace `var' = . if `var'>10000;
* };

* g total_building_dens = house_dens + house_bkyd_dens + shack_non_bkyd_dens + shack_bkyd_dens ;
* g formal = house_dens + house_bkyd_dens ;

* global outcomes "
*   house_dens
*   house_bkyd_dens
*   shack_non_bkyd_dens
*   shack_bkyd_dens
*   owner
*   ";


* global outcomes "
*   house_bkyd
*   house
*   shack_bkyd
*   shack_non_bkyd
*   owner
*   ";





* };



* regs_dd hh_dd_test_unconst 0 ; 

* regs_type_dd hh_dd_test_const_type 1 ; 
* regs_type_dd hh_dd_test_unconst_type 0 ; 




* rgen_dd_cc ;
* regs_dd_cc hh_dd_cc ;



* areg own $regressors  y1996, a(LL) r cluster(cluster_joined)
* areg house $regressors  y1996, a(LL) r cluster(cluster_joined)

* areg house_bkyd $regressors  y1996, a(LL) r cluster(cluster_joined)
* areg shack_bkyd $regressors  y1996, a(LL) r cluster(cluster_joined)
* areg shack_non_bkyd $regressors  y1996, a(LL) r cluster(cluster_joined)


* if $spatial == 1 {;

* regs_spatial ch_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_spatial ;

* regs_type_spatial ch_t_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_spatial ;

* };



/*
*** these are the same... 
ols_spatial_HAC toilet_flush post proj, lat(Y) lon(X) t(post) p(sp_1) dist(1) lag(1) bartlett disp
reg  toilet_flush post proj, nocons


*** these are the same...
areg toilet_flush post proj, a(sp_1)
reg2hdfe toilet_flush proj, id1(sp_1) id2(post)


*** these are also the same
areg toilet_flush proj, a(LL)
reg2hdfe toilet_flush proj, id1(LL) id2(post)


areg toilet_flush $regressors, a(LL)
reg2hdfe toilet_flush $regressors, id1(LL) id2(post)


reg2hdfespatial toilet_flush $regressors , timevar(post) panelvar(LL) lat(Y) lon(X) distcutoff(5) lagcutoff(1)



areg toilet_flush $regressors, a(LL) r cluster(cluster_joined) 





reg toilet_flush post proj
matrix regtab = r(table)
matrix regtab = regtab[2,1...]
matrix rbse = regtab


reg toilet_flush post proj, r
est sto testing
estadd matrix rbse=rbse

esttab, cells(b se rbse)




areg toilet_flush post proj, a(sp_1)





/*


egen m_tf = mean(toilet_flush), by(sp_1 post)
egen m_prof = mean(proj), by(sp_1 post)

g tf_fe = toilet_flush - m_tf
g proj_fe = proj - m_prof

reg tf_fe proj_fe if post==0

areg toilet_flush proj if post==0, a(sp_1)


g constant=1 ;




reg toilet_flush proj, r cluster(cluster_joined)



reg2hdfespatial toilet_flush $regressors , timevar(post) panelvar(LL) lat(Y) lon(X) distcutoff(1) lagcutoff(1)

reg2hdfespatial toilet_flush $regressors , timevar(post) panelvar(sp_1) lat(Y) lon(X) distcutoff(1) lagcutoff(1)






