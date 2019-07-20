clear

est clear
set more off
set scheme s1mono

do  reg_gen.do
do  reg_gen_dd.do


#delimit;


global extra_controls = 
" area area_2 area_3  y1996_area post_area y1996_area_2 post_area_2 y1996_area_3 post_area_3     ";
global extra_controls_2 = 
" area area_2 area_3  y1996_area post_area y1996_area_2 post_area_2 y1996_area_3 post_area_3    ";


if $type_area == 1 {;
global extra_controls = " $extra_controls  [pweight = area]   " ;
global extra_controls_2 = " $extra_controls_2   [pweight = area]  " ;
global ww = " [aweight = area] "; 
};

if $type_area == 2 {;
global extra_controls = " $extra_controls [pweight = buildings]    " ;
global extra_controls_2 = " $extra_controls_2 [pweight = buildings]    " ;
};



if $LOCAL==1 {;
	cd ..;
};

cd ../..;
cd $output;

* go to working dir;

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
egen inc_2001=mean(inc_2001_id), by(sp_1);

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



mat SUM = J(12, 8,.);
keep if con==1 & year==2011;
replace area_int_rdp=0 if area_int_rdp==.;
replace area_int_placebo=0 if area_int_placebo==.;

g project_rdp     = (area_int_rdp     >= $tresh_area & area_int_rdp<. & area_int_rdp    >area_int_placebo);

g area_int_tot = area_int_rdp if area_int_rdp<. & area_int_rdp    >=area_int_placebo;
replace area_int_tot = area_int_placebo if area_int_placebo<.  & area_int_placebo> area_int_rdp;
replace area_int_tot = 0 if area_int_tot==.;

* g project_rdp = (area_int_rdp > $tresh_area & distance_rdp<= $tresh_dist);
* g project_placebo = (area_int_placebo > $tresh_area & distance_placebo<= $tresh_dist);

global CC = 1;


* toilet_flush means;

foreach var of varlist 
  formal 
  toilet_flush 
  water_inside 
  electricity
  tot_rooms
  owner
  hh_size
  pop_density
  age
  african
  emp
  ln_inc  {;
forvalues r = 1/4 {;
sum `var' if project_rdp ==1 & inc_q==`r' $ww;
matrix SUM[$CC,`r'] = round(r(mean),.01);
sum `var' if project_rdp ==0 & inc_q==`r' $ww;
matrix SUM[$CC,`r'+4] = round(r(mean),.01);
};
  global CC = $CC + 1;
};





cap prog drop insert ;
prog define insert ;
  replace names = "`1'" in $CC ;
  global CC = $CC + 1;
end ; 


preserve;
clear;
svmat SUM; 
tostring * , replace force format(%9.2f);
gen names = "";
order names, first;
global CC = 1;

insert "Formal House" ;
insert "Flush Toilet" ;
insert "Piped Water" ;
insert "Electricity" ; 
insert "Total Rooms" ; 
insert "Own Dwelling" ;
insert "HH Size" ;
insert "People" ;
insert "Age HoH" ;
insert "African HoH" ;
insert "Employed HoH" ;
insert "Log HH Income" ;


* replace names = "Formal House" in $CC ;
*   global CC = $CC + 1;
* replace names = "Flush Toilet" in $CC ;
*   global CC = $CC + 1;
* replace names = "Piped Water in Home" in $CC;
*   global CC = $CC + 1;
* replace names = "Electricity" in $CC;
*   global CC = $CC + 1;
* replace names = "Number of Rooms" in $CC;
*   global CC = $CC + 1;
* replace names = "Household Size" in $CC;
*   global CC = $CC + 1;
* replace names = "\% Area Overlap with Projects" in $CC;
*   global CC = $CC + 1;
* replace names = "N" in $CC;
* replace SUM1 = "$cons" in $CC;
* replace SUM2 = "$uncons" in $CC;
* replace SUM3 = "$all" in $CC;

replace SUM8 = SUM8 + " \\";

export delimited using "census_compare_houses${V}.tex", novar delimiter("&") replace;

restore;



    ***** DD REGS **** ;



