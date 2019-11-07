clear

est clear
set more off
set scheme s1mono

do  reg_gen_overlap.do


#delimit;



if $LOCAL==1 {;
	cd ..;
};

cd ../..;
cd $output;

*****************************************************************;
*****************************************************************;
*****************************************************************;

#delimit cr;

use "temp_censushh_agg_buffer_${dist_break_reg1}_${dist_break_reg2}${V}_overlap.dta", clear


g post = year==2011

g cluster_joined = .
foreach var of varlist  *_id {
  replace cluster_joined = `var' if cluster_joined==.
}
replace cluster_joined=0 if cluster_joined==.


g   proj_rdp = cluster_int_tot_rdp / cluster_area
replace proj_rdp = 1 if proj_rdp>1 & proj_rdp<.
g   proj_placebo = cluster_int_tot_placebo / cluster_area
replace proj_placebo = 1 if proj_placebo>1 & proj_placebo<.


foreach v in rdp placebo {
  if "`v'"=="rdp" {
    local v1 "R"
  }
  else {
    local v1 "P"
  }
g s1p_a_1_`v1' = (b1_int_tot_`v' - cluster_int_tot_`v')/(cluster_b1_area-cluster_area)
  replace s1p_a_1_`v1'=1 if s1p_a_1_`v1'>1 & s1p_a_1_`v1'<.

forvalues r= 2/6 {
g s1p_a_`r'_`v1' = (b`r'_int_tot_`v' - b`=`r'-1'_int_tot_`v')/(cluster_b`r'_area - cluster_b`=`r'-1'_area )
  replace s1p_a_`r'_`v1'=1 if s1p_a_`r'_`v1'>1 & s1p_a_`r'_`v1'<.
}
}

foreach var of varlist s1p_a* {
  g `var'_tP = `var'*proj_placebo
  g `var'_tR = `var'*proj_rdp
}

foreach var of varlist  proj_* s1p_* {
  g `var'_post = `var'*post 
}



g pop_density  = 1000000*(person_pop/cluster_area)
* replace pop_density=. if pop_density>100000

g conPR = 1       if proj_rdp>0 & proj_rdp<.
replace conPR = 0 if conPR==.

g PR = proj_rdp if conPR==1
replace PR =  proj_placebo if conPR==0

g PR_conPR = conPR*PR
g PR_post = PR*post
g post_conPR=post*conPR
g PR_post_conPR = PR_post*conPR

global cells = 3
global weight = "  [pweight = area]   "


global outcomes "  water_inside   toilet_flush  electricity  tot_rooms  pop_density "

regs census_overlap





* sum s1p_a_1_R if proj_rdp==0 & s1p_a_1_R>0 & s1p_a_1_R<1
* sum s1p_a_1_R if proj_rdp>0 & proj_rdp<.2 & s1p_a_1_R>0 & s1p_a_1_R<1



* drop *SP*

g conSP = 1 if  s1p_a_1_P==0 & proj_rdp==0 & proj_placebo==0
replace conSP = 0 if s1p_a_1_R==0 & proj_rdp==0 & proj_placebo==0
* replace conSP = . if s1p_a_1_P==0 & s1p_a_1_R==0 & proj_placebo==0 & proj_rdp==0

g SP = s1p_a_1_R if conSP==1
replace SP = s1p_a_1_P if conSP==0

g SP_conSP = conSP*SP
g SP_post = SP*post
g post_conSP=post*conSP
g SP_post_conSP = SP_post*conSP


global outcomes "  water_inside   toilet_flush  electricity  tot_rooms  pop_density "

regs_spill census_spill





g con = 1 if s1p_a_1_P==0 & proj_placebo==0
replace con = 0 if s1p_a_1_R==0 & proj_rdp==0
* replace con = . if sp_a_2_P==0 & sp_a_2_R==0 & proj_placebo==0 & proj_rdp==0

g PR3 = proj_rdp if con==1
replace PR3 =  proj_placebo if con==0

g PR3_con = con*PR3
g PR3_post = PR*post
g PR3_post_con = PR3_post*con

g SP3 = s1p_a_1_R if con==1
replace SP3 = s1p_a_1_P if con==0

g SP3_con = con*SP3
g SP3_post = SP3*post
g post_con=post*con
g SP3_post_con = SP3_post*con

g SP3_PR3 = SP3*PR3
g SP3_PR3_con = con*SP3_PR3
g SP3_PR3_post = SP3_PR3*post
g SP3_PR3_post_con = SP3_PR3_post*con


global outcomes "  water_inside   toilet_flush  electricity  tot_rooms  pop_density "

regs_3 census_3



* drop *SP*

* g conSP = 1 if  s1p_a_1_P==0 & proj_rdp<.2 & proj_placebo<.2
* replace conSP = 0 if s1p_a_1_R==0 & proj_rdp<.2 & proj_placebo<.2
* * replace conSP = . if s1p_a_1_P==0 & s1p_a_1_R==0 & proj_placebo==0 & proj_rdp==0

* g SP = s1p_a_1_R if conSP==1
* replace SP = s1p_a_1_P if conSP==0

* g SP_conSP = conSP*SP
* g SP_post = SP*post
* g post_conSP=post*conSP
* g SP_post_conSP = SP_post*conSP


* global outcomes "  water_inside   toilet_flush  electricity  tot_rooms  pop_density "

* regs_spill census_spill_20







* regs ch1_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area} ;

* regs_q_cen ch1_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area}_q ;

* global outcomes "
*   hh_size
*   age
*   african
*   emp
*   ln_inc
*   "; 






/*


    ***** SUMMARY STATS REGS **** ;



mat SUM = J(8, 3,.);
keep if year ==2001 | year==1996;
replace area_int_rdp=0 if area_int_rdp==.;
replace area_int_placebo=0 if area_int_placebo==.;

g project_rdp     = (area_int_rdp     >= $tresh_area & area_int_rdp<. & area_int_rdp    >area_int_placebo);
g project_placebo = (area_int_placebo >= $tresh_area & area_int_placebo<.  & area_int_placebo>= area_int_rdp);

g area_int_tot = area_int_rdp if area_int_rdp<. & area_int_rdp    >=area_int_placebo;
replace area_int_tot = area_int_placebo if area_int_placebo<.  & area_int_placebo> area_int_rdp;
replace area_int_tot = 0 if area_int_tot==.;

* g project_rdp = (area_int_rdp > $tresh_area & distance_rdp<= $tresh_dist);
* g project_placebo = (area_int_placebo > $tresh_area & distance_placebo<= $tresh_dist);

global CC = 1;


* toilet_flush means;
sum formal if project_rdp ==1 $ww;
matrix SUM[$CC,1] = round(r(mean),.01);
sum formal if project_placebo ==1 $ww;
matrix SUM[$CC,2] = round(r(mean),.01);
sum formal $ww; 
matrix SUM[$CC,3] = round(r(mean),.01);
  global CC = $CC + 1;


* toilet_flush means;
sum toilet_flush if project_rdp ==1 $ww;
matrix SUM[$CC,1] = round(r(mean),.01);
sum toilet_flush if project_placebo ==1 $ww;
matrix SUM[$CC,2] = round(r(mean),.01);
sum toilet_flush $ww; 
matrix SUM[$CC,3] = round(r(mean),.01);
  global CC = $CC + 1;

* water_inside means;
sum water_inside if project_rdp ==1 $ww;
matrix SUM[$CC,1] = round(r(mean),.01);
sum water_inside if project_placebo ==1 $ww;
matrix SUM[$CC,2] = round(r(mean),.01);
sum water_inside $ww;
matrix SUM[$CC,3] = round(r(mean),.01);
  global CC = $CC + 1;

* electric_cooking means;
sum electricity if project_rdp ==1 $ww;
matrix SUM[$CC,1] = round(r(mean),.01);
sum electricity if project_placebo ==1 $ww;
matrix SUM[$CC,2] = round(r(mean),.01);
sum electricity $ww;
matrix SUM[$CC,3] = round(r(mean),.01);
  global CC = $CC + 1;

* tot_rooms means;
sum tot_rooms if project_rdp ==1 $ww;
matrix SUM[$CC,1] = round(r(mean),.01);
sum tot_rooms if project_placebo ==1 $ww;
matrix SUM[$CC,2] = round(r(mean),.01);
sum tot_rooms $ww;
matrix SUM[$CC,3] = round(r(mean),.01);
  global CC = $CC + 1;

* hh_size means;
sum hh_size if project_rdp ==1 $ww;
matrix SUM[$CC,1] = round(r(mean),.01);
sum hh_size if project_placebo ==1 $ww;
matrix SUM[$CC,2] = round(r(mean),.01);
sum hh_size $ww;
matrix SUM[$CC,3] = round(r(mean),.01);
  global CC = $CC + 1;

* area_int means;
* g asum = area_int_rdp + area_int_placebo;

sum area_int_tot if project_rdp ==1 $ww;
matrix SUM[$CC,1] = round(r(mean),.01);
sum area_int_tot if project_placebo ==1 $ww;
matrix SUM[$CC,2] = round(r(mean),.01);
sum area_int_tot $ww;
matrix SUM[$CC,3] = round(r(mean),.01);




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
global CC = 1;
replace names = "Formal House" in $CC ;
  global CC = $CC + 1;
replace names = "Flush Toilet" in $CC ;
  global CC = $CC + 1;
replace names = "Piped Water in Home" in $CC;
  global CC = $CC + 1;
replace names = "Electricity" in $CC;
  global CC = $CC + 1;
replace names = "Number of Rooms" in $CC;
  global CC = $CC + 1;
replace names = "Household Size" in $CC;
  global CC = $CC + 1;
replace names = "\% Area Overlap with Projects" in $CC;
  global CC = $CC + 1;
replace names = "N" in $CC;
replace SUM1 = "$cons" in $CC;
replace SUM2 = "$uncons" in $CC;
replace SUM3 = "$all" in $CC;

replace SUM3 = SUM3 + " \\";

export delimited using "census_at_baseline_AGG${V}.tex", novar delimiter("&") replace;

restore;


svyset [pw=area];
foreach var of varlist formal toilet_flush water_inside electricity tot_rooms hh_size {;
disp "`var'";
svy: mean `var' if project_rdp==1 | project_placebo==1, over(project_rdp);
test [`var']0 = [`var']1 ;
svy: regress `var' project_rdp if project_rdp==1 | project_placebo==1;
};


    ***** DD REGS **** ;





if $type_area == 2 {;
use "temp_censushh_agg_buffer_bblu_${dist_break_reg1}_${dist_break_reg2}${V}.dta", clear;
* g area = buildings;
};
else {;
use "temp_censushh_agg_buffer_${dist_break_reg1}_${dist_break_reg2}${V}.dta", clear;
};


* replace person_pop=. if person_pop>2000;
* replace area = . if area>8050026;
* cap drop pop_density;
replace person_pop = 0 if person_pop==.;
g pop_density  = 1000000*(person_pop/area);

* area area_2 area_3 ;

keep if distance_rdp<$dist_max_reg | distance_placebo<$dist_max_reg ;

replace distance_placebo = . if distance_placebo>distance_rdp   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 ;
replace distance_rdp     = . if distance_rdp>=distance_placebo   & distance_placebo<. & distance_placebo>=0 & distance_rdp<.  & distance_rdp>=0 ;

if $type_area!=2 {;
replace cluster_int_rdp=0 if cluster_int_rdp==. ;
replace cluster_int_placebo=0 if cluster_int_placebo==. ;
};

drop area_int_rdp area_int_placebo ;

g post = year==2011;

if $type_area == 1 {;
rgen_area ;
};
if $type_area == 2 {;
rgen_area_buildings ;
};

cap drop cluster_joined;
g cluster_joined = cluster_rdp if con==1 ; 
replace cluster_joined = cluster_placebo if con==0 ; 



g inc_2001_id = inc if year==2001;
egen inc_2001=mean(inc_2001_id), by(sp_1) ;
* egen proj_sp = mean(proj),     by(sp_1) ;
egen inc_q = cut(inc_2001), group(4);
replace inc_q=inc_q+1;



g proj_cluster = proj>.5 & proj<.;
g spill1_cluster = proj_cluster==0 & spill1>.5 & spill1<.;
g spill2_cluster = proj_cluster==0 & spill1_cluster==0 & spill2>.5 & spill2<.;

if $many_spill == 1 { ;
egen cj1 = group(cluster_joined proj_cluster spill1_cluster spill2_cluster) ;
drop cluster_joined ;
ren cj1 cluster_joined ;
};
if $many_spill == 0 {;
replace spill1_cluster = 1 if spill2_cluster==1;
egen cj1 = group(cluster_joined proj_cluster spill1_cluster) ;
drop cluster_joined ;
ren cj1 cluster_joined ;
};


g t1 = (type_rdp==1 & con==1) | (type_placebo==1 & con==0);
g t2 = (type_rdp==2 & con==1) | (type_placebo==2 & con==0);
g t3 = (type_rdp==. & con==1) | (type_placebo==. & con==0);


if $type_area >= 1 {; 
  rgen_type_area;
};


gen_LL ;


rgen ${no_post} ;

if $type_area == 0 {;
  rgen_type ;
};


g y1996= year==1996;

g y1996_area = y1996*area;
g y1996_area_2 = y1996*area_2;
g y1996_area_3 = y1996*area_3;

g post_area =post*area;
g post_area_2 = post*area_2;
g post_area_3 = post*area_3;

if $many_spill==0 {; 
foreach var of varlist con proj spill1 proj_con spill1_con {;
  g y1996_`var' = `var'*y1996;
    forvalues r=1/3 {;
      g y1996_`var'_t`r' = y1996_`var'*t`r' ;
    };  
  };
    forvalues r=1/3 {;
      g y1996_t`r' = y1996*t`r' ;
    };  
};

* g formal_house = house + house_bkyd ;
* g informal_house = shack_bkyd + shack_non_bkyd ;

* replace pop_density = . if pop_density >40000;

* if $spatial == 0 {;

* keep if area<=2000000 ;

* g total_inf = informal*pop_density;
* g total_for = formal*pop_density;

* total_for total_inf ;
g area_km = area/1000000 ;
* replace area_km= . if area_km>.5 ;

g for_hh = house_dens + flat_dens + duplex_dens + room_on_shared_prop_dens;
g inf_hh = house_bkyd_dens + shack_bkyd_dens + shack_non_bkyd_dens ;
g inf_bkyd_hh = house_bkyd_dens + shack_bkyd_dens ;
g inf_non_bkyd_hh = shack_non_bkyd_dens;
g total_hh = hh_pop;


g for_pers = house_dens_pers + flat_dens_pers + duplex_dens_pers + room_on_shared_prop_dens_pers;
g inf_pers = house_bkyd_dens_pers + shack_bkyd_dens_pers + shack_non_bkyd_dens_pers ;
g inf_bkyd_pers = house_bkyd_dens_pers + shack_bkyd_dens_pers ;
g inf_non_bkyd_pers = shack_non_bkyd_dens_pers;
g total_pers = person_pop;

g total = inf+for;
g inf_non_bkyd = inf-bkyd;
g inf_bkyd = bkyd;

foreach v in total for inf inf_bkyd inf_non_bkyd {;
   replace `v' = 0 if `v'==.;
   replace `v'_pers = 0 if `v'==.;
   g `v'_area = `v'*1000000 / area ;
   replace `v'_area = 0 if `v'_area==.;
   g `v'_pers_area = `v'_pers*1000000 / area ;
   replace `v'_pers_area=0 if `v'_pers_area==.;
   g `v'_per_house = `v'_pers / `v'  ;
   * replace `v'_per_house=0 if `v'_per_house==.;
   * replace `v'_per_house = . if `v'_per_house==0;
   sum `v'_per_house, detail;
   replace `v'_per_house = . if `v'_per_house>=`=r(p99)';
 };


* mean toilet_flush $ww if proj>=.9 & proj<. & con==1 & post==1
* mean toilet_flush $ww if spill1>=.9 & spill1<. & con==1 & post==1
* mean electric_cooking $ww if proj>=.9 & proj<. & con==1 & post==1
* mean electric_cooking $ww if spill1>=.9 & spill1<. & con==1 & post==1
* mean water_inside $ww if proj>=.9 & proj<. & con==1 & post==1
* mean water_inside $ww if spill1>=.9 & spill1<. & con==1 & post==1  ;

**** our backyard classification is right!
* reg house_dens for inf_bkyd inf_non_bkyd if year==2001
* * reg flat_dens for inf_bkyd inf_non_bkyd if year==2001
* * reg duplex_dens for inf_bkyd inf_non_bkyd if year==2001
* * reg room_on_shared_prop_dens for inf_bkyd inf_non_bkyd if year==2001
* reg house_bkyd_dens for inf_bkyd inf_non_bkyd if year==2001
* reg shack_bkyd_dens for inf_bkyd inf_non_bkyd if year==2001
* reg shack_non_bkyd_dens for inf_bkyd inf_non_bkyd if year==2001  ;

* g low_inc = inc_q == 0;
* g high_inc = inc_q == 1;

rgen_q_het_cen ;

* global outcomes " toilet_flush toilet_flush_for_id toilet_flush_bkyd_id toilet_flush_n_bkyd_id "  ; 
* regs_q toilet_flush_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area}_q  ;

* global outcomes "
*   formal 
*   toilet_flush 
*   water_inside 
*   electricity
*   tot_rooms
*   owner
*   ";



global outcomes "
  water_inside 
  toilet_flush 
  electricity
  tot_rooms
  pop_density
  ";

regs ch1_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area} ;

* regs_q_cen ch1_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area}_q ;

global outcomes "
  hh_size
  age
  african
  emp
  ln_inc
  "; 

regs ch2_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area} ;

* regs_q_cen ch2_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area}_q ;


* global outcomes "
*   "; 

* regs ch3_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area} ;

* regs_q ch3_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area}_q ;


* fullreg sex sex  ;
* fullreg age age  ;
* fullreg african african ;
* fullreg emp emp  ;
* fullreg inc inc  ;
* fullreg ln_inc ln_inc  ;


/*


cap prog drop  fullreg;
prog define fullreg ;
global outcomes " `1' `1'_for_id `1'_bkyd_id `1'_n_bkyd_id "  ; 
  regs `2'_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area}  ;

preserve; 
  keep if inc_q==0;
  regs `2'_q0_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area}  ;
restore;
preserve; 
  keep if inc_q==1;
  regs `2'_q1_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area}  ;
restore;

end;

fullreg ten_rented ten_rented  ;
fullreg ten_owned ten_owned  ;
fullreg ten_free ten_free  ;
fullreg ten_debt ten_debt  ;


global outcomes " total_area    for_area     inf_bkyd_area     inf_non_bkyd_area ";
regs cht_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area} ;

global outcomes " total_pers_area    for_pers_area     inf_bkyd_pers_area     inf_non_bkyd_pers_area ";
regs chtp_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area} ;

global outcomes " total_per_house    for_per_house     inf_bkyd_per_house      inf_non_bkyd_per_house ";
regs chtper_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area} ;

preserve;
keep if inc_q==0;
global outcomes " total_area    for_area     inf_bkyd_area     inf_non_bkyd_area ";
regs cht_q0_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area} ;

global outcomes " total_pers_area    for_pers_area     inf_bkyd_pers_area     inf_non_bkyd_pers_area ";
regs chtp_q0_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area} ;

global outcomes " total_per_house    for_per_house     inf_bkyd_per_house      inf_non_bkyd_per_house ";
regs chtper_q0_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area} ;
restore;

preserve;
keep if inc_q==1;
global outcomes " total_area    for_area     inf_bkyd_area     inf_non_bkyd_area ";
regs cht_q1_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area} ;

global outcomes " total_pers_area    for_pers_area     inf_bkyd_pers_area     inf_non_bkyd_pers_area ";
regs chtp_q1_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area} ;

global outcomes " total_per_house    for_per_house     inf_bkyd_per_house      inf_non_bkyd_per_house ";
regs chtper_q1_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area} ;
restore;

fullreg sex sex  ;
fullreg age age  ;
fullreg african african ;
fullreg emp emp  ;
fullreg inc inc  ;
fullreg ln_inc ln_inc  ;


fullreg toilet_flush toih  ;
fullreg water_inside wath  ;
fullreg electric_cooking elec ;
fullreg tot_rooms room  ;
fullreg hh_size hhs  ;




global outcomes " toilet_flush toilet_flush_for_id toilet_flush_bkyd_id toilet_flush_n_bkyd_id "  ; 

regs toih_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area}  ;


global outcomes " water_inside water_inside_for_id water_inside_bkyd_id water_inside_n_bkyd_id"  ; 

regs wath_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area}  ;


global outcomes " water_inside water_inside_for_id water_inside_bkyd_id water_inside_n_bkyd_id"  ; 

regs wath_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area}  ;


global outcomes " water_utility water_utility_for_id  water_utility_bkyd_id water_utility_n_bkyd_id " ;

regs watu_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area}  ;


global outcomes " water_yard water_yard_for_id water_yard_bkyd_id water_yard_n_bkyd_id" ;

regs waty_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area}  ;


global outcomes " electric_cooking electric_cooking_for_id electric_cooking_bkyd_id electric_cooking_n_bkyd_id " ;

regs elec_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area}  ;


global outcomes " tot_rooms tot_rooms_for_id  tot_rooms_bkyd_id tot_rooms_n_bkyd_id " ;

regs room_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area}  ;


global outcomes "hh_size hh_size_for_id hh_size_bkyd_id hh_size_n_bkyd_id" ;

regs hhs_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area}  ;








* foreach var of varlist hh_pop  house_dens traditional_dens flat_dens duplex_dens house_bkyd_dens shack_bkyd_dens shack_non_bkyd_dens room_on_shared_prop_dens {;
*    g `var'_area = `var'/area_km ;
*  };

* ren room_on_shared_prop_dens_area room_dens_area;

* global outcomes "
* hh_pop_area  house_dens_area traditional_dens_area flat_dens_area duplex_dens_area 
*   ";

* * global outcomes "
* *   house_dens house_bkyd_dens shack_bkyd_dens shack_non_bkyd_dens_area hh_pop
* *   ";

* regs cht1_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area} ;

* global outcomes "
* house_bkyd_dens_area shack_bkyd_dens_area shack_non_bkyd_dens_area room_dens_area
* ";

* regs cht2_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area} ;



/*


global outcomes "
total_inf total_for
  ";

regs chd_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area} ;

regs_type chd_t_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area} ;




global outcomes "
  toilet_flush 
  water_inside 
  electricity
  tot_rooms
  hh_size
  pop_density
  ";


regs ch_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area} ;

regs_type ch_t_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area} ;

* global outcomes "
*   house
*   shack_non_bkyd
*   shack_bkyd
*   owner
*   ";
* regs chousef_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}  ;
* regs_type chousef_t_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}  ;


global outcomes "
  formal
  informal
  house_bkyd
  ";

 *   owner; 


regs chouse_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area}  ;

regs_type chouse_t_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area}  ;



global outcomes "
  formal 
  toilet_flush 
  water_inside 
  electricity
  ";


regs ch1_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area} ;

regs_type ch1_t_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area} ;


global outcomes "
  tot_rooms
  owner
  hh_size
  pop_density
  ";


regs ch2_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area} ;

regs_type ch2_t_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area} ;


global outcomes "
  toilet_flush_formal
  water_inside_formal
  electricity_formal
  toilet_flush_informal
  water_inside_informal
  electricity_informal
  ";

regs chouseq_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area}  ;

regs_type chouseq_t_k${k}_o${many_spill}_d${dist_break_reg1}_${dist_break_reg2}_bb${type_area}  ;


/*

**** NOW DO DD *** ;

global outcomes "
  toilet_flush 
  water_inside 
  electricity
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




