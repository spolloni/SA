clear

est clear
set more off
set scheme s1mono

do  reg_gen.do
do  reg_gen_dd.do


#delimit;

if $many_spill == 0 {;
* global extra_controls = 
* " area area_2 area_3  y1996_area post_area y1996_area_2 post_area_2 y1996_area_3 post_area_3 
*   y1996 y1996_con y1996_proj y1996_spill1 y1996_proj_con y1996_spill1_con  [pweight = buildings]  ";
* global extra_controls_2 = 
* "  area area_2 area_3  y1996_area post_area y1996_area_2 post_area_2 y1996_area_3 post_area_3 
*   y1996_t3 y1996_con_t3 y1996_proj_t3 y1996_spill1_t3 y1996_proj_con_t3 y1996_spill1_con_t3  
*   y1996_t2 y1996_con_t2 y1996_proj_t2 y1996_spill1_t2 y1996_proj_con_t2 y1996_spill1_con_t2 
*   y1996_t1 y1996_con_t1 y1996_proj_t1 y1996_spill1_t1 y1996_proj_con_t1 y1996_spill1_con_t1 [pweight = buildings] ";

global extra_controls = 
" area area_2 area_3  y1996_area post_area y1996_area_2 post_area_2 y1996_area_3 post_area_3     ";
global extra_controls_2 = 
" area area_2 area_3  y1996_area post_area y1996_area_2 post_area_2 y1996_area_3 post_area_3    ";

if $type_area == 1 {;
* [pweight = area]  ;
global extra_controls = " $extra_controls  [pweight = area]   " ;
global extra_controls_2 = " $extra_controls_2   [pweight = area]  " ;
* global extra_controls = " $extra_controls   " ;
* global extra_controls_2 = " $extra_controls_2  " ;
* WEIGHTS?? ;
global ww = " [aweight = area] "; /// alternatively [aweight=hh_pop]; 

};

if $type_area == 2 {;
global extra_controls = " $extra_controls [pweight = buildings]    " ;
global extra_controls_2 = " $extra_controls_2 [pweight = buildings]    " ;
};

  

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

****************** ;
*  CENSUS REGS   * ;
****************** ;

* DOFILE SECTIONS ;



if $LOCAL==1 {;
	cd ..;
};

cd ../..;
cd $output;

*****************************************************************;
*****************************************************************;
*****************************************************************;




* go to working dir;

if $type_area == 2 {;
use "temp_censushh_agg_buffer_bblu_${dist_break_reg1}_${dist_break_reg2}${V}.dta", clear;
* g area = buildings;
};
else {;
use "temp_censushh_agg_buffer_${dist_break_reg1}_${dist_break_reg2}${V}.dta", clear;
};






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

g formal_house = house + house_bkyd ;
g informal_house = shack_bkyd + shack_non_bkyd ;

* replace pop_density = . if pop_density >40000;

* if $spatial == 0 {;

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




